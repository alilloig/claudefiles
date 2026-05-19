#!/usr/bin/env bash
# dep-pins-capture — snapshot Move.toml git dep pins to dep-pins.json
# Usage:
#   capture.sh --repo-root <dir> --out <dir> [--local-clones-root <dir>]
#
# Excludes vendored/submodule trees by default (.git, build, .claude,
# plugins/cache, node_modules). Override via --include-vendored.

set -eu
set -o pipefail

REPO_ROOT=""
OUT=""
CLONES_ROOT="${HOME}/workspace"
INCLUDE_VENDORED=0

while [ $# -gt 0 ]; do
  case "$1" in
    --repo-root) REPO_ROOT="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --local-clones-root) CLONES_ROOT="$2"; shift 2 ;;
    --include-vendored) INCLUDE_VENDORED=1; shift ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$REPO_ROOT" ] || REPO_ROOT="$(git rev-parse --show-toplevel)"
[ -n "$OUT" ] || { echo "ERROR: --out required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }

mkdir -p "$OUT"
DEST="$OUT/dep-pins.json"
TS=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

# Find Move.toml files. By default, exclude common vendored/submodule paths.
if [ "$INCLUDE_VENDORED" -eq 1 ]; then
  MOVE_TOMLS=$(find "$REPO_ROOT" -name 'Move.toml' -not -path '*/.git/*' -not -path '*/build/*' 2>/dev/null || true)
else
  MOVE_TOMLS=$(find "$REPO_ROOT" -name 'Move.toml' \
    -not -path '*/.git/*' \
    -not -path '*/build/*' \
    -not -path '*/.claude/*' \
    -not -path '*/plugins/cache/*' \
    -not -path '*/node_modules/*' \
    2>/dev/null || true)
fi

# Accumulate per-dep JSON lines (one object per line); slurp at the end.
LINES_FILE=$(mktemp)
trap 'rm -f "$LINES_FILE"' EXIT

emit_dep() {
  # Args: manifest_rel, name, pin, is_branch_bool, git_url, local_path, local_head, local_subject
  local manifest="$1" name="$2" pin="$3" is_branch_bool="$4" git_url="$5"
  local local_path="$6" local_head="$7" local_subject="$8"
  jq -nc \
    --arg manifest "$manifest" \
    --arg name "$name" \
    --arg rev "$pin" \
    --argjson is_branch "$is_branch_bool" \
    --arg git_url "$git_url" \
    --arg local_path "$local_path" \
    --arg local_head "$local_head" \
    --arg local_subject "$local_subject" \
    '{
      manifest: $manifest,
      name: $name,
      rev: $rev,
      is_branch: $is_branch,
      git_url: $git_url,
      local_clone_path: (if $local_path == "" then null else $local_path end),
      local_head: (if $local_head == "" then null else $local_head end),
      local_head_subject: (if $local_subject == "" then null else $local_subject end)
    }' >> "$LINES_FILE"
}

parse_toml() {
  # Pull single-line dep entries: NAME = { git = "URL", rev = "REV"|branch = "B", ... }
  local toml="$1"
  local rel="${toml#$REPO_ROOT/}"

  awk '
    /^\[dependencies\]/ { in_deps=1; next }
    /^\[dev-dependencies\]/ { in_deps=1; next }
    /^\[/ { in_deps=0; next }
    in_deps && /git[[:space:]]*=/ { print }
  ' "$toml" | while IFS= read -r line; do
    local name git_url rev branch pin is_branch local_path local_head local_subject
    name=$(echo "$line" | sed -nE 's/^[[:space:]]*([A-Za-z0-9_-]+)[[:space:]]*=.*/\1/p')
    [ -z "$name" ] && continue
    git_url=$(echo "$line" | sed -nE 's/.*git[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p')
    rev=$(echo "$line" | sed -nE 's/.*rev[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p')
    branch=$(echo "$line" | sed -nE 's/.*branch[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p')
    pin="${rev:-$branch}"
    [ -z "$git_url" ] && continue

    is_branch=false
    if [ -n "$branch" ]; then
      is_branch=true
    elif [ -n "$pin" ] && ! echo "$pin" | grep -qE '^[0-9a-f]{7,40}$'; then
      is_branch=true
    fi

    local_path=""
    local_head=""
    local_subject=""
    local name_lower
    name_lower=$(echo "$name" | tr 'A-Z' 'a-z')
    for cand in "$CLONES_ROOT/$name" "$CLONES_ROOT/$name_lower"; do
      if [ -d "$cand/.git" ]; then
        local_path="$cand"
        local_head=$(git -C "$cand" rev-parse HEAD 2>/dev/null || true)
        local_subject=$(git -C "$cand" log -1 --pretty=%s 2>/dev/null || true)
        break
      fi
    done

    emit_dep "$rel" "$name" "$pin" "$is_branch" "$git_url" "$local_path" "$local_head" "$local_subject"
  done
}

if [ -n "$MOVE_TOMLS" ]; then
  while IFS= read -r toml; do
    [ -z "$toml" ] && continue
    parse_toml "$toml"
  done <<< "$MOVE_TOMLS"
fi

# Slurp the newline-delimited JSON objects into an array, then wrap.
if [ -s "$LINES_FILE" ]; then
  jq -s --arg ts "$TS" '{captured_at: $ts, deps: .}' "$LINES_FILE" > "$DEST"
else
  jq -n --arg ts "$TS" '{captured_at: $ts, deps: []}' > "$DEST"
fi

N=$(jq '.deps | length' "$DEST")
echo "wrote $DEST ($N deps captured)"
