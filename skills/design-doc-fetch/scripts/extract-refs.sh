#!/usr/bin/env bash
# extract-refs.sh — extract Linear ticket IDs + Linear/Notion URLs from PR meta
# Usage:
#   extract-refs.sh --meta <pr.meta.json> --out <refs.json>

set -eu
set -o pipefail

META=""
OUT=""

while [ $# -gt 0 ]; do
  case "$1" in
    --meta) META="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    *) echo "unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$META" ] || { echo "ERROR: --meta required" >&2; exit 2; }
[ -n "$OUT" ] || { echo "ERROR: --out required" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || { echo "ERROR: jq required" >&2; exit 2; }

mkdir -p "$(dirname "$OUT")"

# Concatenate title + body + headRefName for searching
TEXT=$(jq -r '[.title // "", .body // "", .headRefName // ""] | join("\n")' "$META")

# Linear ticket IDs: 2-6 uppercase letters, dash, 1-5 digits (e.g. COMG-123, SOLENG-4521)
LINEAR_IDS=$(echo "$TEXT" | grep -oE '\b[A-Z]{2,6}-[0-9]{1,5}\b' | sort -u || true)

# Linear URLs: https://linear.app/<workspace>/issue/<ID>/<slug>
LINEAR_URLS=$(echo "$TEXT" | grep -oE 'https://linear\.app/[a-z0-9-]+/issue/[A-Z]{2,6}-[0-9]+[a-z0-9-]*' | sort -u || true)

# Notion URLs: https://www.notion.so/... or https://<workspace>.notion.site/...
NOTION_URLS=$(echo "$TEXT" | grep -oE 'https://[a-z0-9-]*\.?notion\.(so|site)/[^ )]*' | sort -u || true)

# Emit JSON array
{
  echo "["
  first=1
  emit() {
    if [ "$first" -eq 1 ]; then first=0; else echo ","; fi
    printf '  %s' "$1"
  }
  if [ -n "$LINEAR_IDS" ]; then
    while IFS= read -r id; do
      [ -z "$id" ] && continue
      emit "$(jq -nc --arg id "$id" '{kind:"linear", id:$id}')"
    done <<< "$LINEAR_IDS"
  fi
  if [ -n "$LINEAR_URLS" ]; then
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      emit "$(jq -nc --arg url "$url" '{kind:"linear_url", url:$url}')"
    done <<< "$LINEAR_URLS"
  fi
  if [ -n "$NOTION_URLS" ]; then
    while IFS= read -r url; do
      [ -z "$url" ] && continue
      emit "$(jq -nc --arg url "$url" '{kind:"notion", url:$url}')"
    done <<< "$NOTION_URLS"
  fi
  echo ""
  echo "]"
} > "$OUT"

N=$(jq 'length' "$OUT")
echo "wrote $OUT ($N refs)"
