#!/usr/bin/env bash
#
# refresh-sui-pilot-symlink.sh — SessionStart hook
#
# Keeps ~/.claude/sui-pilot pointed at whichever INSTALLED plugin currently ships
# agents/sui-pilot-agent.md, so the always-on `@~/.claude/sui-pilot/agents/sui-pilot-agent.md`
# import in CLAUDE.md (plus the bundled .*-docs/ corpora) stays valid across marketplace
# auto-updates — the plugin cache uses hash-versioned dirs that rotate on every update.
#
# Discovery is name-agnostic: it prefers a sui-pilot install but falls back to ANY installed
# plugin that ships the agent doc, so a future skills-split or plugin rename won't break it.
# The symlink itself is machine-local and gitignored; this hook (and setup.sh) recreate it.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
REG="${CLAUDE_DIR}/plugins/installed_plugins.json"
LINK="${CLAUDE_DIR}/sui-pilot"
DOC_REL="agents/sui-pilot-agent.md"

# No registry yet (fresh machine, plugins not installed): nothing to do.
[ -f "$REG" ] || exit 0

target=""; fallback=""
while IFS= read -r p; do
  [ -n "$p" ] || continue
  [ -f "${p}/${DOC_REL}" ] || continue
  case "$p" in
    */sui-pilot/*) target="$p"; break ;;   # prefer an actual sui-pilot install
  esac
  [ -z "$fallback" ] && fallback="$p"        # else: first plugin that ships the doc
done < <(grep -o '"installPath"[: ]*"[^"]*"' "$REG" | sed 's/.*"installPath"[: ]*"//; s/"$//')
target="${target:-$fallback}"

if [ -z "$target" ]; then
  echo "[sui-pilot-symlink] WARN: no installed plugin provides ${DOC_REL}; the always-on @-import will be empty until sui-pilot (or its successor) is installed." >&2
  exit 0
fi

# Recreate only when it would change, so we don't churn the inode every session.
if [ "$(readlink "$LINK" 2>/dev/null || true)" != "$target" ]; then
  rm -rf "$LINK"
  ln -s "$target" "$LINK"
  echo "[sui-pilot-symlink] ~/.claude/sui-pilot -> ${target#$CLAUDE_DIR/}" >&2
fi
