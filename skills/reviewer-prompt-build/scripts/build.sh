#!/usr/bin/env bash
# reviewer-prompt-build — fill placeholders in a reviewer prompt template
# Usage:
#   build.sh --bundle <dir> --reviewer-id N --template <name>
#            --reviewer-count M [--focus "..."] [--pr-number N]

set -eu
set -o pipefail

BUNDLE=""
REVIEWER_ID=""
TEMPLATE=""
REVIEWER_COUNT=""
FOCUS=""
PR_NUMBER=""

while [ $# -gt 0 ]; do
  case "$1" in
    --bundle) BUNDLE="$2"; shift 2 ;;
    --reviewer-id) REVIEWER_ID="$2"; shift 2 ;;
    --template) TEMPLATE="$2"; shift 2 ;;
    --reviewer-count) REVIEWER_COUNT="$2"; shift 2 ;;
    --focus) FOCUS="$2"; shift 2 ;;
    --pr-number) PR_NUMBER="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BUNDLE" ] || { echo "ERROR: --bundle required" >&2; exit 2; }
[ -n "$REVIEWER_ID" ] || { echo "ERROR: --reviewer-id required" >&2; exit 2; }
[ -n "$TEMPLATE" ] || { echo "ERROR: --template required" >&2; exit 2; }
[ -n "$REVIEWER_COUNT" ] || { echo "ERROR: --reviewer-count required" >&2; exit 2; }

SHARED_DIR="${HOME}/.claude/skills/_review-shared"
TPL_FILE="$SHARED_DIR/references/reviewer_prompts/${TEMPLATE}.md"
[ -f "$TPL_FILE" ] || { echo "ERROR: template not found: $TPL_FILE" >&2; exit 2; }

if [ "$TEMPLATE" = "dimensional-focus" ] && [ -z "$FOCUS" ]; then
  echo "ERROR: --focus required for dimensional-focus template" >&2
  exit 2
fi

# Resolve PR_NUMBER from meta if not passed
if [ -z "$PR_NUMBER" ] && [ -f "$BUNDLE/pr.meta.json" ]; then
  PR_NUMBER=$(jq -r '.number // ""' "$BUNDLE/pr.meta.json" 2>/dev/null || true)
  if [ -z "$PR_NUMBER" ] || [ "$PR_NUMBER" = "null" ]; then
    PR_NUMBER="(branch/worktree)"
  fi
fi
[ -n "$PR_NUMBER" ] || PR_NUMBER="(unknown)"

ABS_BUNDLE=$(cd "$BUNDLE" && pwd -P)
ABS_SCHEMA="$SHARED_DIR/references/schemas.md"

mkdir -p "$ABS_BUNDLE/reviewers/prompts"
OUT="$ABS_BUNDLE/reviewers/prompts/subagent-${REVIEWER_ID}.md"

# Strip the template's leading frontmatter-style header (everything above the first --- line break)
# The shared templates start with `# Reviewer prompt template: <name>` and a `---` separator
# before the actual body. We want only the body.
BODY_START=$(awk '/^---$/ { print NR+1; exit }' "$TPL_FILE")
if [ -n "$BODY_START" ]; then
  TPL_BODY=$(tail -n +"$BODY_START" "$TPL_FILE")
else
  TPL_BODY=$(cat "$TPL_FILE")
fi

# Substitute placeholders. Using awk so values can contain slashes / brackets safely.
echo "$TPL_BODY" | awk \
  -v reviewer_id="$REVIEWER_ID" \
  -v reviewer_count="$REVIEWER_COUNT" \
  -v bundle_path="$ABS_BUNDLE" \
  -v pr_number="$PR_NUMBER" \
  -v focus_area="$FOCUS" \
  -v schema_path="$ABS_SCHEMA" '
  {
    gsub(/\{REVIEWER_ID\}/, reviewer_id)
    gsub(/\{REVIEWER_COUNT\}/, reviewer_count)
    gsub(/\{BUNDLE_PATH\}/, bundle_path)
    gsub(/\{PR_NUMBER\}/, pr_number)
    gsub(/\{FOCUS_AREA\}/, focus_area)
    gsub(/\{SCHEMA_PATH\}/, schema_path)
    print
  }' > "$OUT"

echo "wrote $OUT ($(wc -l < "$OUT" | tr -d ' ') lines, template=$TEMPLATE)"
