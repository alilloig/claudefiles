#!/usr/bin/env bash
# context-bundle-write — compose primitives 1–5 + write context.md
# Usage:
#   write.sh --target <pr:N|pr:URL|branch|worktree> --out <dir> [--anti-bias] [--force]

set -eu
set -o pipefail

TARGET=""
OUT=""
ANTI_BIAS=0
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --anti-bias) ANTI_BIAS=1; shift ;;
    --force) FORCE=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$TARGET" ] || { echo "ERROR: --target required" >&2; exit 2; }
[ -n "$OUT" ] || { echo "ERROR: --out required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }

mkdir -p "$OUT/design-docs" "$OUT/reviewers/prompts"

REPO_ROOT="$(git rev-parse --show-toplevel)"
SHARED_DIR="${HOME}/.claude/skills/_review-shared"
FORCE_FLAG=""
[ "$FORCE" -eq 1 ] && FORCE_FLAG="--force"

echo "==> 1/5 pr-diff-acquire"
~/.claude/skills/pr-diff-acquire/scripts/acquire.sh --target "$TARGET" --out "$OUT" $FORCE_FLAG

echo "==> 2/5 pr-meta-fetch"
~/.claude/skills/pr-meta-fetch/scripts/fetch.sh --target "$TARGET" --out "$OUT" $FORCE_FLAG

echo "==> 3/5 claude-md-walk"
~/.claude/skills/claude-md-walk/scripts/walk.sh --files "$OUT/scope_files.txt" --repo-root "$REPO_ROOT" --out "$OUT"

echo "==> 4/5 dep-pins-capture"
~/.claude/skills/dep-pins-capture/scripts/capture.sh --repo-root "$REPO_ROOT" --out "$OUT"

echo "==> 5/5 design-doc-fetch (ref extraction only; MCP fetches require Claude)"
~/.claude/skills/design-doc-fetch/scripts/extract-refs.sh --meta "$OUT/pr.meta.json" --out "$OUT/design-docs/_refs.json" || true

if [ ! -f "$OUT/design-docs/index.md" ]; then
  REF_COUNT=$(jq 'length' "$OUT/design-docs/_refs.json" 2>/dev/null || echo 0)
  if [ "$REF_COUNT" -eq 0 ]; then
    {
      echo "# Design docs"
      echo ""
      echo "(no Linear / Notion / design docs referenced in PR body)"
    } > "$OUT/design-docs/index.md"
  else
    {
      echo "# Design docs — refs detected, not yet fetched"
      echo ""
      echo "The ref extractor found $REF_COUNT linked doc reference(s) in the PR body / branch name. To enrich the bundle with their distilled content, invoke the \`design-doc-fetch\` skill (requires Linear / Notion MCP tools)."
      echo ""
      echo "## Detected refs"
      echo ""
      jq -r '.[] | "- \(.kind): \(.id // .url)"' "$OUT/design-docs/_refs.json"
    } > "$OUT/design-docs/index.md"
  fi
fi

echo "==> 6/6 context.md"

# Pull values from pr.meta.json
NUMBER=$(jq -r '.number // empty' "$OUT/pr.meta.json")
TITLE=$(jq -r '.title // ""' "$OUT/pr.meta.json")
BASE=$(jq -r '.baseRefName // ""' "$OUT/pr.meta.json")
HEAD=$(jq -r '.headRefName // ""' "$OUT/pr.meta.json")
HEAD_OID=$(jq -r '.headRefOid // ""' "$OUT/pr.meta.json")
ADDS=$(jq -r '.additions // 0' "$OUT/pr.meta.json")
DELS=$(jq -r '.deletions // 0' "$OUT/pr.meta.json")
N_FILES=$(jq -r '.files | length' "$OUT/pr.meta.json")
N_COMMITS=$(jq -r '.commits | length' "$OUT/pr.meta.json")

# Best repo name from `gh` if available, else origin URL
REPO_NAME=""
if command -v gh >/dev/null 2>&1; then
  REPO_NAME=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)
fi
if [ -z "$REPO_NAME" ]; then
  REPO_NAME=$(git config --get remote.origin.url 2>/dev/null | sed -E 's#.*[:/]([^/]+/[^/]+)(\.git)?$#\1#' || true)
fi
[ -n "$REPO_NAME" ] || REPO_NAME="(unknown)"

# Target block
TARGET_BLOCK=$(mktemp)
case "$TARGET" in
  pr:*)
    {
      echo "- **Repo:** \`$REPO_NAME\`"
      echo "- **PR:** #${NUMBER} — ${TITLE}"
      echo "- **Base:** \`$BASE\`  **Head:** \`$HEAD\`"
      echo "- **HEAD commit:** \`$HEAD_OID\`"
      echo "- **Diff size:** +${ADDS} / −${DELS} across ${N_FILES} files"
      echo "- **Commits:** ${N_COMMITS}"
    } > "$TARGET_BLOCK"
    ;;
  branch)
    {
      echo "- **Repo:** \`$REPO_NAME\`"
      echo "- **Branch:** \`$HEAD\` (vs \`$BASE\`)"
      echo "- **HEAD commit:** \`$HEAD_OID\`"
      echo "- **Diff size:** +${ADDS} / −${DELS} across ${N_FILES} files"
      echo "- **Commits ahead of base:** ${N_COMMITS}"
    } > "$TARGET_BLOCK"
    ;;
  worktree)
    {
      echo "- **Repo:** \`$REPO_NAME\`"
      echo "- **Mode:** working tree vs HEAD"
      echo "- **HEAD commit:** \`$HEAD_OID\`"
      echo "- **Diff size:** +${ADDS} / −${DELS} across ${N_FILES} files"
    } > "$TARGET_BLOCK"
    ;;
esac

# Scope IN block
SCOPE_BLOCK=$(mktemp)
if [ -s "$OUT/scope_files.txt" ]; then
  sed 's|^|- `|; s|$|`|' "$OUT/scope_files.txt" > "$SCOPE_BLOCK"
else
  echo "(empty diff — no files to audit)" > "$SCOPE_BLOCK"
fi

# Dep pins block
DEP_BLOCK=$(mktemp)
DEP_COUNT=$(jq '.deps | length' "$OUT/dep-pins.json" 2>/dev/null || echo 0)
if [ "$DEP_COUNT" -eq 0 ]; then
  echo "(no git deps)" > "$DEP_BLOCK"
else
  jq -r '
    .deps[] |
    "- `\(.name)` (in `\(.manifest)`) pinned to `\(.rev)`" +
      (if .is_branch then " — ⚠️ **branch pin**" else "" end) +
      (if .local_clone_path then
        "\n  - Local clone: `\(.local_clone_path)` HEAD `\(.local_head)`" +
          (if .local_head_subject then " — _\"\(.local_head_subject)\"_" else "" end)
       else "\n  - (no local clone found)"
       end)
  ' "$OUT/dep-pins.json" > "$DEP_BLOCK"
fi

# CLAUDE.md preview block
CMD_BLOCK=$(mktemp)
if [ -s "$OUT/claude-md-paths.txt" ]; then
  head -10 "$OUT/claude-md-paths.txt" | sed "s|^|- \`|; s|$|\`|" > "$CMD_BLOCK"
else
  echo "(none found)" > "$CMD_BLOCK"
fi

# Design docs block
DD_BLOCK=$(mktemp)
if [ -s "$OUT/design-docs/index.md" ]; then
  echo "See \`$OUT/design-docs/index.md\`." > "$DD_BLOCK"
else
  echo "(no design docs)" > "$DD_BLOCK"
fi

# Compose context.md
{
  echo "# ${TITLE:-$HEAD} — Shared Context Bundle"
  echo ""
  echo "> Read this **completely** before reviewing. Single source of truth shared with all other reviewers."
  echo ""
  echo "## 1. Target"
  echo ""
  cat "$TARGET_BLOCK"
  echo ""
  echo "## 2. Review scope — IN"
  echo ""
  echo "Every file listed must be audited at least once."
  echo ""
  cat "$SCOPE_BLOCK"
  echo ""
  echo "## 3. Review scope — OUT (read for context only)"
  echo ""
  echo "(none — every changed file is in scope)"
  echo ""
  echo "## 4. Dep pins"
  echo ""
  cat "$DEP_BLOCK"
  echo ""
  echo "## 5. Repo conventions"
  echo ""
  echo "Reviewers MUST honor every CLAUDE.md listed at:"
  echo ""
  echo "\`$OUT/claude-md-paths.txt\`"
  echo ""
  echo "At-a-glance (first 10):"
  echo ""
  cat "$CMD_BLOCK"
  echo ""
  echo "## 6. Design intent"
  echo ""
  cat "$DD_BLOCK"
  echo ""
  echo "## 7. Finding schema and severity rubric (STRICT)"
  echo ""
  echo "All findings must conform to:"
  echo ""
  echo "\`$SHARED_DIR/references/schemas.md\`"
  echo ""
  echo "Quick reference:"
  echo "- \`severity\` ∈ \`critical | high | medium | low | info\`"
  echo "- \`category\` — one of 23 (see schema doc)"
  echo "- \`evidence\` is a literal quote, ≥ 1 full line, no ellipsis"
  echo "- \`spec_reference\` REQUIRED for critical / high findings"
  echo ""
  echo "## 8. Working directory and prohibitions"
  echo ""
  echo "- **cwd:** \`$REPO_ROOT\`"
  echo "- **NO** edits to source / manifests / anything outside your reviewer artifact file"
  echo "- **NO** \`sui move build\`, \`forge\`, \`pnpm install\`, \`git commit\`, \`git push\`, mutating \`gh\` commands"
  echo "- **NO** test runs unless your reviewer prompt explicitly authorizes them"
  echo ""
  echo "## 9. Budget"
  echo ""
  echo "- Target ~30–45 minutes per reviewer."
  echo "- Target 10–30 findings. Quality > quantity."
  echo "- Emit what you have if you run out of budget."
  if [ "$ANTI_BIAS" -ne 1 ]; then
    echo ""
    echo "## 10. Leads — confirm, refute, or ignore (DO NOT TRUST)"
    echo ""
    echo "(Orchestrator pre-read observations — confirm with independent evidence, refute, or ignore. Populate this section by hand if leads exist; the bundle composer leaves it as a template.)"
    echo ""
    echo "_(no leads — the composer left this as a placeholder for orchestrator notes)_"
  fi
} > "$OUT/context.md"

rm -f "$TARGET_BLOCK" "$SCOPE_BLOCK" "$DEP_BLOCK" "$CMD_BLOCK" "$DD_BLOCK"

echo ""
echo "Bundle written to: $OUT"
echo "  pr.diff               $(wc -l < "$OUT/pr.diff" | tr -d ' ') lines"
echo "  scope_files.txt       $(wc -l < "$OUT/scope_files.txt" | tr -d ' ') files"
echo "  claude-md-paths.txt   $(wc -l < "$OUT/claude-md-paths.txt" | tr -d ' ') CLAUDE.md"
echo "  dep-pins.json         $(jq '.deps | length' "$OUT/dep-pins.json") deps"
echo "  design-docs/          $([ -s "$OUT/design-docs/_refs.json" ] && jq 'length' "$OUT/design-docs/_refs.json" || echo 0) refs"
echo "  context.md            $(wc -l < "$OUT/context.md" | tr -d ' ') lines"
if [ "$ANTI_BIAS" -eq 1 ]; then
  echo "  (--anti-bias: leads/shortlist section omitted)"
fi
