#!/usr/bin/env bash
#
# patch-chrome-devtools-mcp.sh — SessionStart hook
#
# Forces the chrome-devtools-mcp plugin to ATTACH to the user's dev Chrome on
# 127.0.0.1:9222 instead of spawning its own (regular, extension-less) Chrome.
#
# Why this exists: the marketplace plugin registers its MCP server as a bare
# `npx chrome-devtools-mcp@<ver>` with NO --browser-url flag, so it always
# launches a fresh wallet-less browser and ignores the Chrome-for-Testing that
# the launch-dev-chrome skill brings up (where MetaMask + Slush are unlocked).
# Adding --browser-url=http://127.0.0.1:9222 makes every MCP call land in the
# wallet instance — the whole point of the launch-dev-chrome workflow.
#
# The plugin cache uses hash/version dirs that rotate on every marketplace
# auto-update, which silently reverts any manual edit. This hook re-applies the
# flag each SessionStart so it survives updates. The hook script is committed in
# dotclaude; its patch target (the plugin cache) is machine-local and ephemeral.
#
# Discovery is name-agnostic: it patches ANY installed plugin whose plugin.json
# declares an mcpServers entry that runs chrome-devtools-mcp, so a plugin rename
# won't break it. Idempotent — only rewrites when the flag is actually missing.
set -euo pipefail

CLAUDE_DIR="${HOME}/.claude"
REG="${CLAUDE_DIR}/plugins/installed_plugins.json"
BROWSER_URL="http://127.0.0.1:9222"

# No registry yet (fresh machine, plugins not installed): nothing to do.
[ -f "$REG" ] || exit 0

python3 - "$REG" "$BROWSER_URL" <<'PY'
import json, sys, os, re

reg_path, browser_url = sys.argv[1], sys.argv[2]
flag = f"--browser-url={browser_url}"

try:
    reg = json.load(open(reg_path))
except Exception as e:
    print(f"[chrome-devtools-mcp-patch] WARN: cannot read registry: {e}", file=sys.stderr)
    sys.exit(0)

# Collect every installPath. Registry shape: {"version": N, "plugins": {key: [records]}}.
# Fall back to scanning the whole doc so a future schema tweak still finds paths.
install_paths = []
plugins = reg.get("plugins", reg)
for records in plugins.values():
    if isinstance(records, list):
        for rec in records:
            if isinstance(rec, dict) and rec.get("installPath"):
                install_paths.append(rec["installPath"])

def server_runs_cdt(cfg):
    """True if this mcpServers entry launches chrome-devtools-mcp."""
    args = cfg.get("args", []) if isinstance(cfg, dict) else []
    cmd = cfg.get("command", "") if isinstance(cfg, dict) else ""
    blob = " ".join([cmd] + [str(a) for a in args])
    return "chrome-devtools-mcp" in blob

patched_any = False
for p in install_paths:
    pj = os.path.join(p, ".claude-plugin", "plugin.json")
    if not os.path.isfile(pj):
        continue
    try:
        data = json.load(open(pj))
    except Exception:
        continue
    servers = data.get("mcpServers")
    if not isinstance(servers, dict):
        continue

    changed = False
    for name, cfg in servers.items():
        if not server_runs_cdt(cfg):
            continue
        args = cfg.setdefault("args", [])
        # Already has a browser-url / browserUrl / -u flag? Normalise to ours only
        # if it points somewhere else; otherwise leave a user's deliberate choice.
        has_attach = any(
            re.match(r'^(--browser-url|--browserUrl|-u)(=|$)', str(a)) for a in args
        )
        if has_attach:
            continue
        args.append(flag)
        changed = True

    if changed:
        json.dump(data, open(pj, "w"), indent=2)
        open(pj, "a").write("\n")
        print(f"[chrome-devtools-mcp-patch] added {flag} -> {pj.replace(os.path.expanduser('~'), '~')}", file=sys.stderr)
        patched_any = True

if not patched_any:
    # Either already patched (idempotent no-op) or plugin not installed — both fine, stay quiet.
    pass
PY
