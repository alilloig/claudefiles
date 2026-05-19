#!/usr/bin/env bash
# routing-resolve — emit reviewers.json for a review bundle
# Usage:
#   resolve.sh --bundle <dir> [--profile redundancy|dimensional|hybrid]
#              [--reviewer-count N] [--focuses 'a;b;c'] [--out <file>]

set -eu
set -o pipefail

BUNDLE=""
PROFILE="hybrid"
COUNT=""
FOCUSES=""
OUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --bundle) BUNDLE="$2"; shift 2 ;;
    --profile) PROFILE="$2"; shift 2 ;;
    --reviewer-count) COUNT="$2"; shift 2 ;;
    --focuses) FOCUSES="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BUNDLE" ] || { echo "ERROR: --bundle required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }
SCOPE="$BUNDLE/scope_files.txt"
DIFF="$BUNDLE/pr.diff"
[ -f "$SCOPE" ] || { echo "ERROR: $SCOPE missing (run pr-meta-fetch first)" >&2; exit 2; }
[ -f "$DIFF" ] || { echo "ERROR: $DIFF missing (run pr-diff-acquire first)" >&2; exit 2; }
[ -n "$OUT" ] || OUT="$BUNDLE/reviewers/reviewers.json"
mkdir -p "$(dirname "$OUT")"

# Classify files into clusters
MOVE_FILES=$(grep -E '\.move$|/Move\.toml$' "$SCOPE" 2>/dev/null || true)
TS_FILES=$(grep -E '\.(ts|tsx|js|jsx|mjs|cjs)$' "$SCOPE" 2>/dev/null || true)
DOCS_FILES=$(grep -E '\.md$' "$SCOPE" 2>/dev/null || true)
INFRA_FILES=$(grep -E '\.github/|^(Dockerfile|docker-compose\.yml)|\.ya?ml$' "$SCOPE" 2>/dev/null || true)
# "other" = anything not in the above (some overlap with infra by yaml; we just use simple priority)
ALL_NONMOVE_NONTS_NONDOCS=$(grep -vE '\.(move|ts|tsx|js|jsx|mjs|cjs|md)$|/Move\.toml$' "$SCOPE" 2>/dev/null || true)

MOVE_COUNT=$([ -n "$MOVE_FILES" ] && echo "$MOVE_FILES" | wc -l | tr -d ' ' || echo 0)
TS_COUNT=$([ -n "$TS_FILES" ] && echo "$TS_FILES" | wc -l | tr -d ' ' || echo 0)
DOCS_COUNT=$([ -n "$DOCS_FILES" ] && echo "$DOCS_FILES" | wc -l | tr -d ' ' || echo 0)
INFRA_COUNT=$([ -n "$INFRA_FILES" ] && echo "$INFRA_FILES" | wc -l | tr -d ' ' || echo 0)

# TS lines changed (rough — +-line count in TS files of the diff)
TS_LINES=0
if [ "$TS_COUNT" -gt 0 ]; then
  TS_LINES=$(awk -v re='\\.(ts|tsx|js|jsx|mjs|cjs)$' '
    /^diff --git/ { current=$0; in_ts=0; if ($NF ~ re) in_ts=1; next }
    in_ts && /^[+-][^+-]/ { c++ }
    END { print c+0 }
  ' "$DIFF")
fi

# Dimension signals (sampled from added lines).
# Note: `grep -c` exits 1 when there are 0 matches but still prints "0",
# so we capture-with-fallback to handle both signal and exit-code.
SIG_ERR=$(grep -cE '^\+[^+].*(catch|try \{|throw |panic!|\.unwrap\(\))' "$DIFF" 2>/dev/null) || SIG_ERR=0
SIG_TYPES=$(grep -cE '^\+[^+].*\b(type |interface |struct |enum )\s*[A-Z]' "$DIFF" 2>/dev/null) || SIG_TYPES=0
SIG_TESTS=$(grep -cE '\.test\.|__tests__|_test\.move' "$SCOPE" 2>/dev/null) || SIG_TESTS=0
# Comment-only signal: count + and # comment lines vs total + lines
PLUS_TOTAL=$(grep -cE '^\+[^+]' "$DIFF" 2>/dev/null) || PLUS_TOTAL=0
COMMENT_LINES=$(grep -cE '^\+[^+][[:space:]]*(//|#)' "$DIFF" 2>/dev/null) || COMMENT_LINES=0
if [ "$PLUS_TOTAL" -gt 0 ]; then
  COMMENT_PCT=$(( COMMENT_LINES * 100 / PLUS_TOTAL ))
else
  COMMENT_PCT=0
fi
SIG_COMMENT=0
[ "$COMMENT_PCT" -ge 80 ] && SIG_COMMENT=1

# Pick the dominant cluster for redundancy/dimensional fallback
LARGEST_CLUSTER="other"
LARGEST_AGENT="general-purpose"
LARGEST_TEMPLATE="generic-redundancy"
if [ "$MOVE_COUNT" -gt 0 ]; then
  LARGEST_CLUSTER="move"; LARGEST_AGENT="sui-pilot:sui-pilot-agent"; LARGEST_TEMPLATE="move-deep"
elif [ "$TS_COUNT" -gt 0 ]; then
  LARGEST_CLUSTER="ts-js"
  if [ "$TS_LINES" -ge 50 ]; then LARGEST_AGENT="pr-review-toolkit:code-reviewer"; else LARGEST_AGENT="feature-dev:code-reviewer"; fi
  LARGEST_TEMPLATE="ts-js-focused"
elif [ "$DOCS_COUNT" -gt 0 ]; then
  LARGEST_CLUSTER="docs"; LARGEST_AGENT="pr-review-toolkit:comment-analyzer"; LARGEST_TEMPLATE="dimensional-focus"
fi

LINES_FILE=$(mktemp)
trap 'rm -f "$LINES_FILE"' EXIT

emit() {
  # id, subagent_type, focus_area, prompt_template, role
  jq -nc \
    --argjson id "$1" \
    --arg subagent_type "$2" \
    --arg focus_area "$3" \
    --arg prompt_template "$4" \
    --arg role "$5" \
    '{id: $id, subagent_type: $subagent_type, focus_area: $focus_area, prompt_template: $prompt_template, role: $role}' >> "$LINES_FILE"
}

case "$PROFILE" in
  redundancy)
    N="${COUNT:-3}"
    for i in $(seq 1 "$N"); do
      emit "$i" "$LARGEST_AGENT" "general — find issues across all dimensions" "$LARGEST_TEMPLATE" "redundancy"
    done
    ;;
  dimensional)
    [ -n "$FOCUSES" ] || { echo "ERROR: --focuses required for dimensional profile" >&2; exit 2; }
    i=1
    IFS=';' read -ra FOCUS_ARR <<< "$FOCUSES"
    for focus in "${FOCUS_ARR[@]}"; do
      focus_trimmed=$(echo "$focus" | sed -E 's/^[[:space:]]+|[[:space:]]+$//g')
      [ -z "$focus_trimmed" ] && continue
      emit "$i" "$LARGEST_AGENT" "$focus_trimmed" "dimensional-focus" "dimensional"
      i=$((i + 1))
    done
    ;;
  hybrid)
    i=1
    # Per-cluster primaries
    if [ "$MOVE_COUNT" -gt 0 ]; then
      emit "$i" "sui-pilot:sui-pilot-agent" "general Move review across all dimensions" "move-deep" "cluster-primary"
      i=$((i + 1))
    fi
    if [ "$TS_COUNT" -gt 0 ]; then
      ts_agent="pr-review-toolkit:code-reviewer"
      [ "$TS_LINES" -lt 50 ] && ts_agent="feature-dev:code-reviewer"
      emit "$i" "$ts_agent" "general TS/JS review across all dimensions" "ts-js-focused" "cluster-primary"
      i=$((i + 1))
    fi
    if [ "$INFRA_COUNT" -gt 0 ] && [ "$MOVE_COUNT" -eq 0 ] && [ "$TS_COUNT" -eq 0 ]; then
      emit "$i" "general-purpose" "infra/config review (no domain specialist available)" "generic-redundancy" "cluster-primary"
      i=$((i + 1))
    fi
    if [ "$MOVE_COUNT" -eq 0 ] && [ "$TS_COUNT" -eq 0 ] && [ "$INFRA_COUNT" -eq 0 ] && [ "$DOCS_COUNT" -eq 0 ]; then
      emit "$i" "general-purpose" "general code review (no domain match)" "generic-redundancy" "cluster-primary"
      i=$((i + 1))
    fi
    # Dimension lanes
    if [ "$SIG_ERR" -gt 0 ]; then
      emit "$i" "pr-review-toolkit:silent-failure-hunter" "error handling — silent failures, swallowed exceptions, unsafe fallbacks" "dimensional-focus" "dimension-lane"
      i=$((i + 1))
    fi
    if [ "$SIG_TYPES" -gt 0 ]; then
      emit "$i" "pr-review-toolkit:type-design-analyzer" "type design — invariants, encapsulation, expressiveness" "dimensional-focus" "dimension-lane"
      i=$((i + 1))
    fi
    if [ "$SIG_TESTS" -gt 0 ]; then
      emit "$i" "pr-review-toolkit:pr-test-analyzer" "test coverage — behavioral coverage, edge cases" "dimensional-focus" "dimension-lane"
      i=$((i + 1))
    fi
    if [ "$SIG_COMMENT" -eq 1 ] && [ "$DOCS_COUNT" -eq 0 ]; then
      # Avoid double-add if docs cluster already routed to comment-analyzer
      emit "$i" "pr-review-toolkit:comment-analyzer" "comments — accuracy, completeness, rot" "dimensional-focus" "dimension-lane"
      i=$((i + 1))
    fi
    # Hard cap at 10 reviewers
    if [ "$(wc -l < "$LINES_FILE" | tr -d ' ')" -gt 10 ]; then
      head -10 "$LINES_FILE" > "$LINES_FILE.tmp" && mv "$LINES_FILE.tmp" "$LINES_FILE"
    fi
    ;;
  *)
    echo "ERROR: unrecognized --profile: $PROFILE (use redundancy|dimensional|hybrid)" >&2
    exit 2
    ;;
esac

if [ -s "$LINES_FILE" ]; then
  jq -s '.' "$LINES_FILE" > "$OUT"
else
  echo '[]' > "$OUT"
fi

N=$(jq 'length' "$OUT")
echo "wrote $OUT ($N reviewers, profile=$PROFILE)"
echo "  cluster sizes: move=$MOVE_COUNT ts=$TS_COUNT docs=$DOCS_COUNT infra=$INFRA_COUNT"
echo "  dimension signals: err=$SIG_ERR types=$SIG_TYPES tests=$SIG_TESTS comments=$SIG_COMMENT (${COMMENT_PCT}%)"
