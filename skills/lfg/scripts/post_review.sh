#!/usr/bin/env bash
# Post a PR review with inline suggestions via the GitHub reviews API.
# Usage:
#   post_review.sh <owner> <repo> <pr_number> <payload.json>   # posts the review
#   post_review.sh --check <payload.json>                      # validates payload only, no network
set -euo pipefail

if [[ "${1:-}" == "--check" ]]; then
  payload="${2:?usage: post_review.sh --check <payload.json>}"
  # Payload must be valid JSON with event + comments[] each having path/line/side/body.
  jq -e '
    (.event | type == "string") and
    (.body  | type == "string") and
    (.comments | type == "array") and
    (all(.comments[]; (.path|type=="string") and (.line|type=="number") and (.side|type=="string") and (.body|type=="string")))
  ' "$payload" > /dev/null
  echo "CHECK OK: $payload"
  exit 0
fi

owner="${1:?owner}"; repo="${2:?repo}"; pr="${3:?pr_number}"; payload="${4:?payload.json}"
bash "$0" --check "$payload"   # validate before sending
gh api -X POST "repos/${owner}/${repo}/pulls/${pr}/reviews" --input "$payload"
echo "POSTED review to ${owner}/${repo}#${pr}"
