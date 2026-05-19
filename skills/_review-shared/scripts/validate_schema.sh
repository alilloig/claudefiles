#!/usr/bin/env bash
# Strict JSON schema validation for reviewer findings.
# Usage: validate_schema.sh <raw-dir>
#   <raw-dir> defaults to reviews/.raw
#
# For each subagent-N.json (N in 0..REVIEWERS):
#   - asserts the top level is a JSON array
#   - asserts every element has the required fields with correct types
#   - asserts id matches "R<N>-NNN" pattern
#   - exits non-zero with detailed error if any reviewer fails
#
# Originally vendored from sui-pilot/move-pr-review (see UPSTREAM.md).
# Local modifications:
#   - expanded category vocabulary (union of move-pr-review, stepped-pr,
#     ship-reviewed-pr categories)
#   - optional fields: `domain`, `spec_reference`
#   - REVIEWERS defaults to 10 but can be lower via env (set per fan-out size)
#
# Requires: jq.

set -u
set -o pipefail

RAW_DIR="${1:-reviews/.raw}"
REVIEWERS="${REVIEWERS:-10}"

if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq not found in PATH" >&2
  exit 2
fi

if [ ! -d "$RAW_DIR" ]; then
  echo "ERROR: directory not found: $RAW_DIR" >&2
  exit 2
fi

VALID_SEVERITIES='["critical","high","medium","low","info"]'
VALID_CONFIDENCE='["high","medium","low"]'
VALID_CATEGORIES='["access-control","correctness","arithmetic","object-model","versioning","integration-boundary","events","move-quality","testing","scripts","docs","design","error-handling","simplicity","security","performance","build","api-contract","concurrency","data-integrity","observability","type-design","comments"]'
VALID_DOMAINS='["move","ts-js","generic"]'

OVERALL=0

for n in $(seq 0 "$REVIEWERS"); do
  f="$RAW_DIR/subagent-$n.json"
  [ -f "$f" ] || continue

  echo "=== validating subagent-$n.json ==="

  # Top-level must be an array
  if ! jq -e 'type == "array"' "$f" >/dev/null 2>&1; then
    echo "  FAIL: not a JSON array" >&2
    OVERALL=1
    continue
  fi

  # Per-element strict schema
  bad=$(jq --argjson sevs "$VALID_SEVERITIES" \
           --argjson confs "$VALID_CONFIDENCE" \
           --argjson cats "$VALID_CATEGORIES" \
           --argjson doms "$VALID_DOMAINS" \
           --arg ridprefix "R$n-" '
    [ .[] | select(
        (has("id") | not) or (.id | tostring | startswith($ridprefix) | not) or
        (has("title") | not) or (.title | type != "string") or (.title == "") or
        (has("severity") | not) or (.severity as $s | $sevs | index($s) == null) or
        (has("category") | not) or (.category as $c | $cats | index($c) == null) or
        (has("file") | not) or (.file | type != "string") or (.file == "") or
        (has("line_range") | not) or (.line_range | type != "string") or (.line_range == "") or
        (has("description") | not) or (.description | type != "string") or (.description == "") or
        (has("impact") | not) or (.impact | type != "string") or (.impact == "") or
        (has("recommendation") | not) or (.recommendation | type != "string") or (.recommendation == "") or
        (has("evidence") | not) or (.evidence | type != "string") or (.evidence == "") or
        (has("confidence") | not) or (.confidence as $c | $confs | index($c) == null) or
        # Optional: if `domain` is present it must be one of the valid values.
        (has("domain") and (.domain as $d | $doms | index($d) == null)) or
        # Required iff severity is critical|high: `spec_reference` must be a non-empty string.
        ((.severity == "critical" or .severity == "high") and
          ((has("spec_reference") | not) or (.spec_reference | type != "string") or (.spec_reference == "")))
      ) | .id // "<missing-id>"
    ]' "$f")

  bad_count=$(echo "$bad" | jq 'length')
  total=$(jq 'length' "$f")
  if [ "$bad_count" != "0" ]; then
    echo "  FAIL: $bad_count of $total entries failed schema check"
    echo "  Failing IDs: $bad"
    OVERALL=1
  else
    echo "  OK ($total findings)"
  fi
done

exit "$OVERALL"
