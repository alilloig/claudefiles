#!/usr/bin/env bash
# pr-diff-acquire — emit pr.diff for a PR/branch/worktree target
# Usage:
#   acquire.sh --target <pr:N|pr:URL|branch|worktree> --out <dir> [--force]

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
DEST="$OUT/pr.diff"

if [ -f "$DEST" ] && [ "$FORCE" -ne 1 ]; then
  echo "pr.diff already exists: $DEST (pass --force to overwrite)" >&2
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
    command -v gh >/dev/null 2>&1 || { echo "ERROR: gh required for pr: target" >&2; exit 2; }
    REF="${TARGET#pr:}"
    gh pr diff "$REF" > "$DEST"
    ;;
  branch)
    command -v git >/dev/null 2>&1 || { echo "ERROR: git required" >&2; exit 2; }
    BASE=$(resolve_default_branch)
    MB=$(git merge-base HEAD "$BASE")
    git diff "$MB..HEAD" > "$DEST"
    ;;
  worktree)
    command -v git >/dev/null 2>&1 || { echo "ERROR: git required" >&2; exit 2; }
    git diff HEAD > "$DEST"
    ;;
  *)
    echo "ERROR: unrecognized --target: $TARGET" >&2
    exit 2
    ;;
esac

# Summarize
if [ -s "$DEST" ]; then
  ADD=$(grep -c '^+[^+]' "$DEST" || true)
  DEL=$(grep -c '^-[^-]' "$DEST" || true)
  FILES=$(grep -c '^diff --git ' "$DEST" || true)
  echo "wrote $DEST: +$ADD / -$DEL across $FILES files"
else
  echo "wrote $DEST: (empty diff)"
fi
