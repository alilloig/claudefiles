#!/usr/bin/env bash
# reviewer-fan-out/finalize.sh — post-dispatch validation
# Usage:
#   finalize.sh --bundle <dir>

set -eu
set -o pipefail

BUNDLE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --bundle) BUNDLE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BUNDLE" ] || { echo "ERROR: --bundle required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }
DISPATCH="$BUNDLE/reviewers/_dispatch.json"
[ -f "$DISPATCH" ] || { echo "ERROR: $DISPATCH missing — run prepare.sh first" >&2; exit 2; }

# Update output_written + completed_at per reviewer
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
UPDATED=$(mktemp)
trap 'rm -f "$UPDATED"' EXIT

jq --arg bundle "$BUNDLE" --arg ts "$TS" '
  map(
    . as $r |
    ($bundle + "/reviewers/subagent-" + (.reviewer_id|tostring) + ".json") as $json |
    .output_written = ($json | test(".*")) |
    .completed_at = $ts
  )
' "$DISPATCH" > "$UPDATED"
mv "$UPDATED" "$DISPATCH"

# Determine the actual highest reviewer ID for the schema check
MAX_ID=$(jq '[.[].reviewer_id] | max' "$DISPATCH")
MISSING=""
for id in $(jq -r '.[].reviewer_id' "$DISPATCH"); do
  if [ ! -f "$BUNDLE/reviewers/subagent-${id}.json" ]; then
    MISSING="$MISSING $id"
  fi
done

if [ -n "$MISSING" ]; then
  echo "WARN: missing reviewer outputs for ids:$MISSING" >&2
  # Mark them in dispatch
  for id in $MISSING; do
    UPDATED2=$(mktemp)
    jq --argjson id "$id" \
      'map(if .reviewer_id == $id then .output_written = false else . end)' \
      "$DISPATCH" > "$UPDATED2"
    mv "$UPDATED2" "$DISPATCH"
  done
fi

# Run schema validator on what's present
REVIEWERS="$MAX_ID" bash "${HOME}/.claude/skills/_review-shared/scripts/validate_schema.sh" "$BUNDLE/reviewers"

OK_COUNT=$(jq '[.[] | select(.output_written == true)] | length' "$DISPATCH")
TOTAL=$(jq 'length' "$DISPATCH")
echo "fan-out finalize: $OK_COUNT/$TOTAL reviewers produced output"
