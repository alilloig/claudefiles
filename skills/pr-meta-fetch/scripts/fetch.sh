#!/usr/bin/env bash
# pr-meta-fetch — write pr.meta.json + scope_files.txt for a target
# Usage:
#   fetch.sh --target <pr:N|pr:URL|branch|worktree> --out <dir> [--force]

set -eu
set -o pipefail

TARGET=""
OUT=""
FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --target) TARGET="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --force) FORCE=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$TARGET" ] || { echo "ERROR: --target required" >&2; exit 2; }
[ -n "$OUT" ] || { echo "ERROR: --out required" >&2; exit 2; }

mkdir -p "$OUT"
META="$OUT/pr.meta.json"
SCOPE="$OUT/scope_files.txt"

if [ -f "$META" ] && [ -f "$SCOPE" ] && [ "$FORCE" -ne 1 ]; then
  echo "pr.meta.json and scope_files.txt already exist (pass --force to overwrite)" >&2
  exit 0
fi

resolve_default_branch() {
  local b
  b=$(git rev-parse --abbrev-ref origin/HEAD 2>/dev/null | sed 's|origin/||') || true
  if [ -z "$b" ]; then
    if git show-ref --verify --quiet refs/heads/main; then b=main
    elif git show-ref --verify --quiet refs/heads/master; then b=master
    else b=main
    fi
  fi
  echo "$b"
}

case "$TARGET" in
  pr:*)
    command -v gh >/dev/null 2>&1 || { echo "ERROR: gh required" >&2; exit 2; }
    command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }
    REF="${TARGET#pr:}"
    gh pr view "$REF" \
      --json number,title,body,headRefName,baseRefName,headRefOid,files,additions,deletions,commits \
      > "$META"
    jq -r '.files[].path' "$META" | sort -u > "$SCOPE"
    ;;
  branch|worktree)
    command -v git >/dev/null 2>&1 || { echo "ERROR: git required" >&2; exit 2; }
    command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }
    HEAD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
    HEAD_OID=$(git rev-parse HEAD)
    if [ "$TARGET" = "branch" ]; then
      BASE_BRANCH=$(resolve_default_branch)
      MB=$(git merge-base HEAD "$BASE_BRANCH")
      DIFF_RANGE="$MB..HEAD"
      TITLE=$(git log -1 --pretty=%s)
      BODY=$(git log "$MB..HEAD" --pretty=%B | head -200)
    else
      BASE_BRANCH="$HEAD_BRANCH"
      DIFF_RANGE="HEAD"
      TITLE="(working tree)"
      BODY=""
    fi
    # Files + per-file additions/deletions
    FILES_JSON=$(git diff --numstat "$DIFF_RANGE" 2>/dev/null \
      | awk 'BEGIN{print "["} NR>1{print ","} {printf "{\"path\":\"%s\",\"additions\":%s,\"deletions\":%s}", $3, ($1=="-"?0:$1), ($2=="-"?0:$2)} END{print "]"}')
    if [ -z "$FILES_JSON" ]; then FILES_JSON='[]'; fi
    TOTAL_ADD=$(git diff --shortstat "$DIFF_RANGE" 2>/dev/null | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+' || echo 0)
    TOTAL_DEL=$(git diff --shortstat "$DIFF_RANGE" 2>/dev/null | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+' || echo 0)
    COMMITS_JSON=$(git log --pretty=format:'{"oid":"%H","messageHeadline":"%s"}' "$DIFF_RANGE" 2>/dev/null \
      | jq -s '.' 2>/dev/null || echo '[]')

    jq -n \
      --argjson files "$FILES_JSON" \
      --arg headRefName "$HEAD_BRANCH" \
      --arg baseRefName "$BASE_BRANCH" \
      --arg headRefOid "$HEAD_OID" \
      --arg title "$TITLE" \
      --arg body "$BODY" \
      --argjson additions "${TOTAL_ADD:-0}" \
      --argjson deletions "${TOTAL_DEL:-0}" \
      --argjson commits "$COMMITS_JSON" \
      '{number: null, title: $title, body: $body, headRefName: $headRefName, baseRefName: $baseRefName, headRefOid: $headRefOid, files: $files, additions: $additions, deletions: $deletions, commits: $commits}' \
      > "$META"

    jq -r '.files[].path' "$META" | sort -u > "$SCOPE"
    ;;
  *)
    echo "ERROR: unrecognized --target: $TARGET" >&2
    exit 2
    ;;
esac

NUM_FILES=$(wc -l < "$SCOPE" | tr -d ' ')
echo "wrote $META and $SCOPE ($NUM_FILES files)"
