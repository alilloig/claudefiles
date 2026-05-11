#!/usr/bin/env bash
# batch-validate.sh — run validate_artifacts.sh across all 18 runs in iteration-1.
#
# Usage:
#   ./batch-validate.sh <iteration-dir>
#
# Args:
#   <iteration-dir>  e.g. ~/.claude/skills/ship-reviewed-pr-workspace/iteration-1
#
# For each run dir found under <iteration-dir>/eval-*/<config>/run-*/, this:
#   1. Reads eval_metadata.json to learn the per-run branch + test repo path.
#   2. Calls validate_artifacts.sh against that run's dir + branch.
# Skips runs that already have metrics.json (idempotent — safe to re-run).

set -uo pipefail

ITER_DIR="${1:?usage: batch-validate.sh <iteration-dir>}"
VALIDATOR="$(dirname "$0")/validate_artifacts.sh"

if [[ ! -d "$ITER_DIR" ]]; then
  echo "ERROR: iteration dir not found: $ITER_DIR" >&2
  exit 1
fi

if [[ ! -x "$VALIDATOR" ]]; then
  echo "ERROR: validator not executable: $VALIDATOR" >&2
  exit 1
fi

PROCESSED=0
SKIPPED=0
FAILED=0

for run_dir in "$ITER_DIR"/eval-*/with_skill/run-*/ "$ITER_DIR"/eval-*/without_skill/run-*/; do
  [[ -d "$run_dir" ]] || continue

  meta="$run_dir/eval_metadata.json"
  if [[ ! -f "$meta" ]]; then
    echo "SKIP (no metadata): $run_dir"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  if [[ -f "$run_dir/metrics.json" ]]; then
    echo "SKIP (metrics exists): $run_dir"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  branch=$(jq -r '.branch' "$meta" 2>/dev/null || echo "")
  test_repo=$(jq -r '.test_repo' "$meta" 2>/dev/null || echo "")

  if [[ -z "$branch" || -z "$test_repo" ]]; then
    echo "FAIL (bad metadata): $run_dir"
    FAILED=$((FAILED + 1))
    continue
  fi

  echo "VALIDATE: $run_dir"
  if "$VALIDATOR" "$run_dir" "$test_repo" "$branch" >/dev/null 2>&1; then
    PROCESSED=$((PROCESSED + 1))
  else
    echo "  ⚠ validator returned non-zero — metrics.json may be incomplete"
    FAILED=$((FAILED + 1))
  fi
done

echo
echo "Done. processed=$PROCESSED, skipped=$SKIPPED, failed=$FAILED"
