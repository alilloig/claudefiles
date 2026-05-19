#!/usr/bin/env bash
# reviewer-fan-out/prepare.sh — pre-flight a fan-out dispatch
# Usage:
#   prepare.sh --bundle <dir> [--reviewers <path>]

set -eu
set -o pipefail

BUNDLE=""
REVIEWERS_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --bundle) BUNDLE="$2"; shift 2 ;;
    --reviewers) REVIEWERS_FILE="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$BUNDLE" ] || { echo "ERROR: --bundle required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }
[ -n "$REVIEWERS_FILE" ] || REVIEWERS_FILE="$BUNDLE/reviewers/reviewers.json"
[ -f "$REVIEWERS_FILE" ] || { echo "ERROR: reviewers file missing: $REVIEWERS_FILE" >&2; exit 2; }

N=$(jq 'length' "$REVIEWERS_FILE")
[ "$N" -gt 0 ] || { echo "ERROR: reviewers.json is empty array" >&2; exit 2; }

# Schema check
INVALID=$(jq '[.[] | select((has("id") | not) or (has("subagent_type") | not) or (has("focus_area") | not) or (has("prompt_template") | not) or (has("role") | not)) | .id // "<no-id>"]' "$REVIEWERS_FILE")
INVALID_COUNT=$(echo "$INVALID" | jq 'length')
if [ "$INVALID_COUNT" != "0" ]; then
  echo "ERROR: $INVALID_COUNT reviewer entries are missing required fields: $INVALID" >&2
  exit 2
fi

# Per-reviewer prompt existence check
MISSING=""
for id in $(jq -r '.[].id' "$REVIEWERS_FILE"); do
  if [ ! -f "$BUNDLE/reviewers/prompts/subagent-${id}.md" ]; then
    MISSING="$MISSING $id"
  fi
done
if [ -n "$MISSING" ]; then
  echo "ERROR: missing prompt files for reviewer ids:$MISSING" >&2
  echo "  Hint: run reviewer-prompt-build for each id first." >&2
  exit 2
fi

# Skeleton _dispatch.json
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
jq --arg ts "$TS" \
  '[.[] | {reviewer_id: .id, subagent_type, focus_area, prompt_template, role, fallback_reason: null, dispatched_at: $ts, completed_at: null, output_written: null}]' \
  "$REVIEWERS_FILE" > "$BUNDLE/reviewers/_dispatch.json"

echo "OK: $N reviewers pre-flighted; _dispatch.json skeleton written"
echo "Reviewer ids: $(jq -r '[.[].id] | join(", ")' "$REVIEWERS_FILE")"
