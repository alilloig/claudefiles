#!/usr/bin/env bash
# validate_artifacts.sh — capture artifacts and produce metrics.json for one eval run.
#
# Usage:
#   validate_artifacts.sh <run-dir> <test-repo-dir> <branch-name>
#
# Args:
#   <run-dir>        — eval workspace run directory, e.g.
#                       ~/.claude/skills/ship-reviewed-pr-workspace/iteration-1/eval-clean-pr/with_skill/run-1/
#                      The script writes outputs/ artifacts into this dir's outputs/ subdir,
#                      and metrics.json directly into this dir (sibling to outputs/).
#   <test-repo-dir>  — where the ship-reviewed-pr skill ran, e.g. ~/workspace/ship-reviewed-pr-test
#   <branch-name>    — per-run feature branch the skill operated on, e.g. fixture/clean-pr-handwalk
#
# Behavior:
#   - Captures observable artifacts from the test repo (PR state, comments, .claude-pr-review/<ts>/)
#     into <run-dir>/outputs/ for the eval-viewer to render.
#   - Inspects git/gh state and writes <run-dir>/metrics.json — the artifact the
#     grader subagent reads alongside the LLM-evaluated expectations.
#   - All checks are objective: file existence, JSON schema, regex match on
#     comment body, commit-message match, typecheck exit code. Substantive
#     judgments (was the review correct?) are left for the grader / human reviewer.

set -uo pipefail

RUN_DIR="${1:?usage: validate_artifacts.sh <run-dir> <test-repo-dir> <branch-name>}"
TEST_REPO="${2:?missing test-repo-dir}"
BRANCH="${3:?missing branch-name}"
OUTPUTS_DIR="$RUN_DIR/outputs"
METRICS="$RUN_DIR/metrics.json"

mkdir -p "$OUTPUTS_DIR"

# ---------- 1. Locate the skill's workspace dir in the test repo ----------
PR_REVIEW_BASE="$TEST_REPO/.claude-pr-review"
LATEST_WS=""
if [[ -d "$PR_REVIEW_BASE" ]]; then
  LATEST_WS=$(ls -1dt "$PR_REVIEW_BASE"/* 2>/dev/null | head -1 || true)
fi

# ---------- 2. Capture review.md and subagent JSONs into outputs/ ----------
REVIEW_MD_PATH=""
REVIEW_MD_EXISTS=false
REVIEWER_JSON_COUNT=0
REVIEWER_SCHEMA_VALID_COUNT=0
REVIEWER_SCHEMA_FAILURES=()

if [[ -n "$LATEST_WS" && -d "$LATEST_WS" ]]; then
  if [[ -f "$LATEST_WS/review.md" ]]; then
    cp "$LATEST_WS/review.md" "$OUTPUTS_DIR/review-md-copy.md"
    REVIEW_MD_PATH="$LATEST_WS/review.md"
    REVIEW_MD_EXISTS=true
  fi
  if [[ -d "$LATEST_WS/reviewers" ]]; then
    for f in "$LATEST_WS"/reviewers/subagent-*.json; do
      [[ -f "$f" ]] || continue
      REVIEWER_JSON_COUNT=$((REVIEWER_JSON_COUNT + 1))
      cp "$f" "$OUTPUTS_DIR/$(basename "$f")"

      # Schema check via jq.
      # Note the `as $obj` pattern: inside `all(.[]; ...)`, the current element
      # is the implicit `.` — but after a pipe like `$sevs | ...`, jq's `.`
      # rebinds to $sevs. Capturing the element via `as $obj` lets us reach
      # back to it on the right-hand side of those pipes.
      if jq -e \
        --argjson required '["id","title","severity","category","file","line_range","description","impact","recommendation","evidence","confidence"]' \
        --argjson sevs '["critical","high","medium","low","info"]' \
        --argjson confs '["high","medium","low"]' \
        --argjson cats '["correctness","design","error-handling","simplicity","tests-vs-impl","security","performance","documentation","build"]' \
        'type=="array" and (length == 0 or all(.[]; . as $obj |
            (($required - ($obj | keys_unsorted)) == []) and
            ($sevs | index($obj.severity) != null) and
            ($confs | index($obj.confidence) != null) and
            ($cats | index($obj.category) != null)
          ))' \
        "$f" >/dev/null 2>&1; then
        REVIEWER_SCHEMA_VALID_COUNT=$((REVIEWER_SCHEMA_VALID_COUNT + 1))
      else
        REVIEWER_SCHEMA_FAILURES+=("$(basename "$f")")
      fi
    done
  fi
fi

# ---------- 3. Inspect review.md structure ----------
REVIEW_HAS_HEADING=false
REVIEW_HAS_SEVERITY_TABLE=false
REVIEW_HAS_METHODOLOGY=false
if [[ "$REVIEW_MD_EXISTS" == true ]]; then
  grep -qE '^### Code review$' "$REVIEW_MD_PATH" 2>/dev/null && REVIEW_HAS_HEADING=true
  grep -qE '\| *Severity *\| *Count *\|' "$REVIEW_MD_PATH" 2>/dev/null && REVIEW_HAS_SEVERITY_TABLE=true
  grep -qiE '^#+.*Methodology' "$REVIEW_MD_PATH" 2>/dev/null && REVIEW_HAS_METHODOLOGY=true
fi

# ---------- 4. PR state from gh ----------
PR_NUMBER=""
PR_COUNT=0
PR_URL=""
PR_HEAD_SHA=""
if command -v gh >/dev/null 2>&1; then
  PR_NUMBER=$(gh pr list --repo alilloig/ship-reviewed-pr-test --head "$BRANCH" --state open --json number -q '.[0].number' 2>/dev/null || echo "")
  if [[ -n "$PR_NUMBER" ]]; then
    PR_COUNT=$(gh pr list --repo alilloig/ship-reviewed-pr-test --head "$BRANCH" --state open --json number -q '. | length' 2>/dev/null || echo 0)
    PR_URL=$(gh pr view "$PR_NUMBER" --repo alilloig/ship-reviewed-pr-test --json url -q '.url' 2>/dev/null || echo "")
    PR_HEAD_SHA=$(gh pr view "$PR_NUMBER" --repo alilloig/ship-reviewed-pr-test --json headRefOid -q '.headRefOid' 2>/dev/null || echo "")
  fi
fi

# ---------- 5. PR comment(s): count and body capture ----------
PR_COMMENT_COUNT=0
COMMENT_HAS_HEADING=false
COMMENT_HAS_SEVERITY_TABLE=false
COMMENT_HAS_METHODOLOGY=false
if [[ -n "$PR_NUMBER" ]]; then
  PR_COMMENT_COUNT=$(gh pr view "$PR_NUMBER" --repo alilloig/ship-reviewed-pr-test --json comments -q '.comments | length' 2>/dev/null || echo 0)
  if [[ "$PR_COMMENT_COUNT" -ge 1 ]]; then
    gh pr view "$PR_NUMBER" --repo alilloig/ship-reviewed-pr-test --json comments -q '.comments[0].body' > "$OUTPUTS_DIR/pr-comment.md" 2>/dev/null || true
    grep -qE '^### Code review$' "$OUTPUTS_DIR/pr-comment.md" 2>/dev/null && COMMENT_HAS_HEADING=true
    grep -qE '\| *Severity *\| *Count *\|' "$OUTPUTS_DIR/pr-comment.md" 2>/dev/null && COMMENT_HAS_SEVERITY_TABLE=true
    grep -qiE '^#+.*Methodology' "$OUTPUTS_DIR/pr-comment.md" 2>/dev/null && COMMENT_HAS_METHODOLOGY=true
  fi
fi

# ---------- 6. Auto-fix commit detection ----------
AUTO_FIX_COMMIT_PRESENT=false
AUTO_FIX_COMMIT_SHA=""
AUTO_FIX_COMMIT_FILES=()
if [[ -d "$TEST_REPO/.git" ]]; then
  AUTO_FIX_COMMIT_SHA=$(git -C "$TEST_REPO" log "origin/$BRANCH" --grep '^fix: address critical/high review findings' --format='%H' -1 2>/dev/null || echo "")
  if [[ -n "$AUTO_FIX_COMMIT_SHA" ]]; then
    AUTO_FIX_COMMIT_PRESENT=true
    while IFS= read -r f; do
      [[ -n "$f" ]] && AUTO_FIX_COMMIT_FILES+=("$f")
    done < <(git -C "$TEST_REPO" diff-tree --no-commit-id --name-only -r "$AUTO_FIX_COMMIT_SHA" 2>/dev/null || true)
  fi
fi

# ---------- 7. Typecheck (current state of test repo on the per-run branch) ----------
TYPECHECK_EXIT=-1
TYPECHECK_PASS=false
if [[ -d "$TEST_REPO" && -f "$TEST_REPO/package.json" ]]; then
  if (cd "$TEST_REPO" && pnpm typecheck >/dev/null 2>&1); then
    TYPECHECK_EXIT=0
    TYPECHECK_PASS=true
  else
    TYPECHECK_EXIT=$?
  fi
fi

# ---------- 8. Build PR info JSON for the viewer ----------
cat > "$OUTPUTS_DIR/pr-info.json" <<EOF
{
  "branch": "$BRANCH",
  "pr_number": $([ -n "$PR_NUMBER" ] && echo "$PR_NUMBER" || echo "null"),
  "pr_url": "$PR_URL",
  "pr_head_sha": "$PR_HEAD_SHA",
  "auto_fix_commit_sha": "$AUTO_FIX_COMMIT_SHA"
}
EOF

# ---------- 9. Write metrics.json ----------
# Build the reviewer_schema_failures JSON array safely.
if [[ ${#REVIEWER_SCHEMA_FAILURES[@]} -gt 0 ]]; then
  FAIL_JSON=$(printf '"%s",' "${REVIEWER_SCHEMA_FAILURES[@]}")
  FAIL_JSON="[${FAIL_JSON%,}]"
else
  FAIL_JSON="[]"
fi

if [[ ${#AUTO_FIX_COMMIT_FILES[@]} -gt 0 ]]; then
  AF_FILES_JSON=$(printf '"%s",' "${AUTO_FIX_COMMIT_FILES[@]}")
  AF_FILES_JSON="[${AF_FILES_JSON%,}]"
else
  AF_FILES_JSON="[]"
fi

cat > "$METRICS" <<EOF
{
  "captured_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "branch": "$BRANCH",
  "test_repo": "$TEST_REPO",
  "skill_workspace_path": "$LATEST_WS",
  "pr": {
    "count": $PR_COUNT,
    "number": $([ -n "$PR_NUMBER" ] && echo "$PR_NUMBER" || echo "null"),
    "url": "$PR_URL",
    "head_sha": "$PR_HEAD_SHA",
    "comment_count": $PR_COMMENT_COUNT,
    "comment_has_code_review_heading": $COMMENT_HAS_HEADING,
    "comment_has_severity_table": $COMMENT_HAS_SEVERITY_TABLE,
    "comment_has_methodology_section": $COMMENT_HAS_METHODOLOGY
  },
  "reviewers": {
    "json_file_count": $REVIEWER_JSON_COUNT,
    "schema_valid_count": $REVIEWER_SCHEMA_VALID_COUNT,
    "schema_failures": $FAIL_JSON
  },
  "review_md": {
    "exists": $REVIEW_MD_EXISTS,
    "path": "$REVIEW_MD_PATH",
    "has_code_review_heading": $REVIEW_HAS_HEADING,
    "has_severity_table": $REVIEW_HAS_SEVERITY_TABLE,
    "has_methodology_section": $REVIEW_HAS_METHODOLOGY
  },
  "auto_fix": {
    "commit_present": $AUTO_FIX_COMMIT_PRESENT,
    "commit_sha": "$AUTO_FIX_COMMIT_SHA",
    "files_touched": $AF_FILES_JSON
  },
  "typecheck": {
    "exit_code": $TYPECHECK_EXIT,
    "pass": $TYPECHECK_PASS
  }
}
EOF

echo "Wrote metrics: $METRICS"
echo "Captured artifacts: $OUTPUTS_DIR"
