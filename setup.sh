#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== dotclaude setup ==="
echo "Repo: $REPO_DIR"
echo ""

# --- Prerequisites ---
if ! command -v claude &>/dev/null; then
    echo "✘ 'claude' CLI not found. Install Claude Code first:"
    echo "  npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# --- 1. Symlink ~/.claude -> repo ---
if [ -L "$HOME/.claude" ]; then
    current=$(readlink "$HOME/.claude")
    if [ "$current" = "$REPO_DIR" ]; then
        echo "✓ ~/.claude -> $REPO_DIR"
    else
        echo "! ~/.claude -> $current (expected $REPO_DIR)"
        echo "  Remove the symlink and re-run to update."
        exit 1
    fi
elif [ -e "$HOME/.claude" ]; then
    echo "! ~/.claude exists but is not a symlink."
    echo "  Back it up and remove it, then re-run:"
    echo "    mv ~/.claude ~/.claude.bak && bash $0"
    exit 1
else
    ln -s "$REPO_DIR" "$HOME/.claude"
    echo "✓ Created ~/.claude -> $REPO_DIR"
fi

# --- 2. Plugin hook permissions ---
# Some plugins ship hook scripts without +x, which makes SessionStart (or other
# hook events) fail with "permission denied". Recurs after plugin updates since
# new versions are fresh checkouts — safe to re-run any time.
echo ""
echo "--- Plugin hook permissions ---"
if [ -d "$REPO_DIR/plugins/cache" ]; then
    count=0
    while IFS= read -r -d '' f; do
        chmod +x "$f"
        count=$((count + 1))
    done < <(find "$REPO_DIR/plugins/cache" -name '*.sh' ! -perm -u+x -print0)
    echo "✓ Made $count plugin hook script(s) executable"
else
    echo "· no plugin cache yet (first run)"
fi

# --- 3. Marketplaces ---
echo ""
echo "--- Marketplaces ---"

# Local marketplace (re-registers with correct absolute path for this machine)
if claude plugin marketplace add "$REPO_DIR/plugins/local" 2>/dev/null; then
    echo "✓ local marketplace registered"
else
    echo "· local marketplace (already registered)"
fi

# Fetch/refresh all marketplace catalogs (official, impeccable, local)
# Official and impeccable are declared in settings.json extraKnownMarketplaces
echo "  Updating catalogs..."
claude plugin marketplace update 2>/dev/null || true

# --- 4. Install plugins ---
echo ""
echo "--- Plugins ---"

installed=0
skipped=0

install_plugin() {
    if claude plugin install "$1" 2>/dev/null; then
        echo "  ✓ $1"
        ((installed++)) || true
    else
        ((skipped++)) || true
    fi
}

# Official marketplace
official_plugins=(
    chrome-devtools-mcp claude-code-setup claude-md-management
    code-review code-simplifier commit-commands feature-dev
    frontend-design hookify
    learning-output-style linear mcp-server-dev
    notion playground plugin-dev pr-review-toolkit
    pyright-lsp ralph-loop receipts rust-analyzer-lsp
    security-guidance skill-creator slack
    telegram typescript-lsp
)
for p in "${official_plugins[@]}"; do
    install_plugin "${p}@claude-plugins-official"
done

# Impeccable marketplace
install_plugin "impeccable@impeccable"

# Local plugins
for p in forge-bench sui-wallet; do
    install_plugin "${p}@local"
done

# Contract-hero plugins (code-forge + codex-bridge migrated here from local;
# see plugins/marketplaces/contract-hero/.claude-plugin/marketplace.json)
for p in code-forge codex-bridge sui-pilot; do
    install_plugin "${p}@contract-hero"
done

# Trail of Bits security plugins (marketplace: trailofbits/skills, declared in
# settings.json extraKnownMarketplaces). Full set — AI-assisted security
# analysis, fuzzing, static analysis, audit workflows, etc.
#
# Gated behind INSTALL_EVM_STACK (same flag as the heavy toolchain below) so a
# default bootstrap stays lean. These 39 plugins register always-on hooks
# (gh-cli Bash PreToolUse; fp-check/skill-improver Stop) and pull in extra MCP
# servers, so they're opt-in. settings.json ships them disabled; the runtime
# switch is scripts/sol-sec-stack.sh {on,off}.
tob_plugins=(
    ask-questions-if-underspecified audit-context-building
    building-secure-contracts burpsuite-project-parser
    claude-in-chrome-troubleshooting constant-time-analysis culture-index
    debug-buttercup devcontainer-setup differential-review
    firebase-apk-scanner gh-cli dwarf-expert entry-point-analyzer
    mutation-testing property-based-testing semgrep-rule-creator
    semgrep-rule-variant-creator sharp-edges static-analysis
    spec-to-code-compliance testing-handbook-skills trailmark
    variant-analysis c-review modern-python insecure-defaults
    second-opinion yara-authoring git-cleanup workflow-skill-design
    seatbelt-sandboxer supply-chain-risk-auditor zeroize-audit
    let-fate-decide agentic-actions-auditor skill-improver fp-check
    dimensional-analysis
)
if [ "${INSTALL_EVM_STACK:-0}" = "1" ]; then
    for p in "${tob_plugins[@]}"; do
        install_plugin "${p}@trailofbits"
    done
else
    echo "  · Trail of Bits plugins skipped (set INSTALL_EVM_STACK=1 to install)"
    echo "    runtime toggle: ~/.claude/scripts/sol-sec-stack.sh on"
fi

echo ""
echo "  Installed: $installed  Already present: $skipped"

# --- 5. Disable selected plugins ---
echo ""
echo "--- Disable optional plugins ---"
disabled_plugins=(
    slack@claude-plugins-official
    notion@claude-plugins-official
)
for p in "${disabled_plugins[@]}"; do
    claude plugin disable "$p" 2>/dev/null || true
done
echo "  ✓ Disabled: slack, notion"

# --- 6. EVM / Solidity-security stack (opt-in) ---
# Heavy toolchain (Foundry, Slither, Aderyn, Halmos, Mythril, Medusa, Echidna)
# plus analysis-only MCP servers and auditor skill repos. Off by default so
# normal bootstraps stay fast; enable with:
#     INSTALL_EVM_STACK=1 bash setup.sh
# The installer is idempotent and safe to re-run.
echo ""
echo "--- EVM / Solidity-security stack ---"
if [ "${INSTALL_EVM_STACK:-0}" = "1" ]; then
    echo "  INSTALL_EVM_STACK=1 -> running scripts/setup-sol-sec-stack.sh --yes"
    bash "$REPO_DIR/scripts/setup-sol-sec-stack.sh" --yes || \
        echo "  ! EVM stack install reported issues (see output above)"
else
    echo "  · skipped (set INSTALL_EVM_STACK=1 to install)"
    echo "    or run manually: bash ~/.claude/scripts/setup-sol-sec-stack.sh"
fi

# --- Done ---
echo ""
echo "=== Setup complete ==="
echo ""
echo "Restart Claude Code to load all plugins."
echo "Verify with: claude plugin list"
