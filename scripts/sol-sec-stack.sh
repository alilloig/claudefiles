#!/usr/bin/env bash
#
# sol-sec-stack.sh — one-switch toggle for the EVM/Solidity-security stack.
#
# The stack (added across commits 1a305f5 / 92bdcb6 / fe2389e) is heavy and
# always-on: 39 @trailofbits plugins register hooks that fire on every Bash
# call (gh-cli PreToolUse) and every turn end (fp-check / skill-improver Stop),
# and the openzeppelin + slither MCP servers inject tools into every session.
# This script turns the whole batch off (or back on) in one command.
#
#   ./scripts/sol-sec-stack.sh off      # disable — quiet, cheap sessions
#   ./scripts/sol-sec-stack.sh on       # re-enable the full stack
#   ./scripts/sol-sec-stack.sh status   # show current state
#
# What it touches:
#   - ~/.claude/settings.json  → flips every "*@trailofbits" enabledPlugins
#     entry true/false (entries are kept, never deleted: re-enable needs no
#     marketplace re-clone). Disabling a plugin also disables the MCP servers
#     it bundles (second-opinion, zeroize-audit/serena).
#   - ~/.claude.json           → adds/removes the openzeppelin + slither MCP
#     servers (definitions are baked in below — ~/.claude.json is machine-local
#     and not tracked in this repo).
#
# NOT touched: the pashov solidity-auditor / x-ray skills in skills/ (they only
# load when explicitly invoked, so they cost nothing at rest), and the unrelated
# codex / elevenlabs MCP servers.
#
# Portable bash 3.2 (macOS default). Requires jq.
set -euo pipefail

SETTINGS="${HOME}/.claude/settings.json"
CLAUDE_JSON="${HOME}/.claude.json"

# MCP server definitions to restore on `on` (see commit 1a305f5).
OZ_DEF='{"type":"http","url":"https://mcp.openzeppelin.com/contracts/solidity/mcp"}'
SLITHER_DEF='{"type":"stdio","command":"uvx","args":["--from","git+https://github.com/trailofbits/slither-mcp","slither-mcp"],"env":{}}'

die() { echo "error: $*" >&2; exit 1; }
usage() { echo "usage: $(basename "$0") {on|off|status}" >&2; exit 1; }

command -v jq >/dev/null 2>&1 || die "jq not found on PATH"
[ -f "$SETTINGS" ] || die "settings.json not found at $SETTINGS"

# Atomically rewrite a JSON file through a jq filter (args after filter are jq args).
edit_json() {
  local file="$1" filter="$2"; shift 2
  local tmp; tmp="$(mktemp)"
  jq "$@" "$filter" "$file" > "$tmp" && mv "$tmp" "$file"
}

flip_plugins() { # $1 = true|false
  edit_json "$SETTINGS" \
    '.enabledPlugins |= with_entries(if (.key|endswith("@trailofbits")) then .value = $v else . end)' \
    --argjson v "$1"
}

add_mcp() {
  [ -f "$CLAUDE_JSON" ] || die "~/.claude.json not found at $CLAUDE_JSON"
  edit_json "$CLAUDE_JSON" \
    '.mcpServers.openzeppelin = $oz | .mcpServers.slither = $sl' \
    --argjson oz "$OZ_DEF" --argjson sl "$SLITHER_DEF"
}

remove_mcp() {
  [ -f "$CLAUDE_JSON" ] || return 0
  edit_json "$CLAUDE_JSON" 'del(.mcpServers.openzeppelin, .mcpServers.slither)'
}

status() {
  local total on off
  total="$(jq -r '[.enabledPlugins|to_entries[]|select(.key|endswith("@trailofbits"))]|length' "$SETTINGS")"
  on="$(jq -r '[.enabledPlugins|to_entries[]|select((.key|endswith("@trailofbits")) and .value==true)]|length' "$SETTINGS")"
  off=$(( total - on ))
  echo "Trail of Bits plugins: ${on} on / ${off} off  (of ${total})"
  if [ -f "$CLAUDE_JSON" ]; then
    local oz sl
    oz="$(jq -r 'if .mcpServers.openzeppelin then "present" else "absent" end' "$CLAUDE_JSON")"
    sl="$(jq -r 'if .mcpServers.slither then "present" else "absent" end' "$CLAUDE_JSON")"
    echo "MCP servers: openzeppelin=${oz}  slither=${sl}"
  else
    echo "MCP servers: ~/.claude.json not found"
  fi
}

case "${1:-}" in
  on)
    flip_plugins true
    add_mcp
    echo "EVM/Solidity-security stack ENABLED."
    status
    echo "Restart Claude Code (or start a new session) for plugin/MCP changes to take effect."
    ;;
  off)
    flip_plugins false
    remove_mcp
    echo "EVM/Solidity-security stack DISABLED."
    status
    echo "Restart Claude Code (or start a new session) for plugin/MCP changes to take effect."
    ;;
  status) status ;;
  *) usage ;;
esac
