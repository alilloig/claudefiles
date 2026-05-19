#!/usr/bin/env bash
# claude-md-walk — write claude-md-paths.txt for a list of changed files
# Usage:
#   walk.sh --files <scope_files.txt> --repo-root <dir> --out <dir>

set -eu
set -o pipefail

FILES=""
REPO_ROOT=""
OUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --files) FILES="$2"; shift 2 ;;
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$FILES" ] || { echo "ERROR: --files required" >&2; exit 2; }
[ -n "$REPO_ROOT" ] || REPO_ROOT="$(git rev-parse --show-toplevel)"
[ -n "$OUT" ] || { echo "ERROR: --out required" >&2; exit 2; }

mkdir -p "$OUT"
DEST="$OUT/claude-md-paths.txt"

if [ ! -f "$FILES" ] || [ ! -s "$FILES" ]; then
  : > "$DEST"
  echo "wrote $DEST: (empty — no scope files)"
  exit 0
fi

# Canonicalize repo root (resolve symlinks like ~/.claude → dotfiles/.claude)
REPO_ROOT=$(cd "$REPO_ROOT" && pwd -P)

# Collect every directory we need to walk up from
TMP_DIRS=$(mktemp)
trap 'rm -f "$TMP_DIRS"' EXIT

while IFS= read -r f; do
  [ -z "$f" ] && continue
  # File may not exist (e.g., deleted in diff); still walk its dir.
  # Normalize: dirname may yield "." for repo-root files; collapse to repo root.
  rel_dir=$(dirname "$f")
  if [ "$rel_dir" = "." ] || [ -z "$rel_dir" ]; then
    echo "$REPO_ROOT"
  else
    echo "$REPO_ROOT/$rel_dir"
  fi
done < "$FILES" | sort -u > "$TMP_DIRS"

# Walk up each starting dir, collecting CLAUDE.md
TMP_PATHS=$(mktemp)
trap 'rm -f "$TMP_DIRS" "$TMP_PATHS"' EXIT

while IFS= read -r d; do
  cur="$d"
  while :; do
    if [ -f "$cur/CLAUDE.md" ]; then
      echo "$cur/CLAUDE.md"
    fi
    if [ "$cur" = "$REPO_ROOT" ] || [ "$cur" = "/" ]; then
      break
    fi
    parent=$(dirname "$cur")
    [ "$parent" = "$cur" ] && break
    cur="$parent"
  done
done < "$TMP_DIRS" | sort -u | awk '{ print length, $0 }' | sort -n | awk '{ $1=""; sub(/^ /,""); print }' > "$TMP_PATHS"

mv "$TMP_PATHS" "$DEST"

N=$(wc -l < "$DEST" | tr -d ' ')
echo "wrote $DEST ($N CLAUDE.md ancestors)"
