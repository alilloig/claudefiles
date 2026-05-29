#!/usr/bin/env bash
#
# setup-sol-sec-stack.sh
# ----------------------------------------------------------------------------
# Idempotent checker/installer for the recommended Claude Code Solidity-security
# stack (Foundry, Slither, Aderyn, Echidna/Medusa, Halmos, Slither-MCP,
# Etherscan MCP, OpenZeppelin Contracts MCP, Pashov + Trail of Bits skills).
#
# Design principles:
#   * IDEMPOTENT  - every action is guarded by a check; re-running is safe.
#   * SAFE        - never installs wallet/Foundry-signing MCPs flagged dangerous;
#                   never touches private keys; MCP servers added read-only.
#   * GRACEFUL    - missing prerequisites are reported and skipped, not fatal.
#   * INSPECTABLE - run with --dry-run to see what *would* happen.
#
# Usage:
#   ./setup-sol-sec-stack.sh [--dry-run] [--check-only] [--yes]
#                            [--skip-mcp] [--skip-skills] [--mcp-scope user|project]
#
# Flags:
#   --dry-run        Print actions without executing them.
#   --check-only     Only report status; install nothing (implies no mutations).
#   --yes            Don't prompt before installing missing items.
#   --skip-mcp       Skip Claude Code MCP server registration.
#   --skip-skills    Skip cloning of skill repos.
#   --mcp-scope      MCP registration scope (default: user).
#   -h | --help      Show help.
#
# Exit code: 0 if everything required is present (or successfully installed),
#            1 if one or more REQUIRED components are still missing afterwards.
# ----------------------------------------------------------------------------

set -uo pipefail

# ----------------------------- configuration --------------------------------

DRY_RUN=0
CHECK_ONLY=0
ASSUME_YES=0
SKIP_MCP=0
SKIP_SKILLS=0
MCP_SCOPE="user"

SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills-src}"   # where we clone skill repos
MISSING_REQUIRED=0

# Skill repos to clone (name -> git url). These are the auditor-built repos
# from the recommendations. Cloning != enabling; you still point Claude at them.
# Parallel indexed arrays (portable to bash 3.2; assoc arrays need bash 4+).
SKILL_REPO_NAMES=( "pashov-skills" "trailofbits-skills" )
SKILL_REPO_URLS=(
  "https://github.com/pashov/skills.git"
  "https://github.com/trailofbits/skills.git"
)

# ------------------------------- ui helpers ---------------------------------

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'; C_OK=$'\033[32m'; C_WARN=$'\033[33m'
  C_ERR=$'\033[31m'; C_INFO=$'\033[36m'; C_BOLD=$'\033[1m'
else
  C_RESET=""; C_OK=""; C_WARN=""; C_ERR=""; C_INFO=""; C_BOLD=""
fi

say()   { printf '%s\n' "$*"; }
ok()    { printf '%s[ ok ]%s %s\n'   "$C_OK"   "$C_RESET" "$*"; }
warn()  { printf '%s[warn]%s %s\n'   "$C_WARN" "$C_RESET" "$*"; }
err()   { printf '%s[fail]%s %s\n'   "$C_ERR"  "$C_RESET" "$*"; }
info()  { printf '%s[info]%s %s\n'   "$C_INFO" "$C_RESET" "$*"; }
head()  { printf '\n%s== %s ==%s\n'  "$C_BOLD" "$*" "$C_RESET"; }

# Run a command, honoring --dry-run.
run() {
  if [[ "$DRY_RUN" -eq 1 || "$CHECK_ONLY" -eq 1 ]]; then
    info "would run: $*"
    return 0
  fi
  "$@"
}

# Run a shell string (for pipelines), honoring --dry-run.
run_sh() {
  if [[ "$DRY_RUN" -eq 1 || "$CHECK_ONLY" -eq 1 ]]; then
    info "would run: $1"
    return 0
  fi
  bash -c "$1"
}

confirm() {
  # $1 = prompt. Returns 0 if user says yes.
  [[ "$ASSUME_YES" -eq 1 ]] && return 0
  [[ "$CHECK_ONLY" -eq 1 || "$DRY_RUN" -eq 1 ]] && return 1
  local reply
  read -r -p "    -> $1 [y/N] " reply
  [[ "$reply" =~ ^[Yy]$ ]]
}

have() { command -v "$1" >/dev/null 2>&1; }

# --------------------------- argument parsing -------------------------------

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)     DRY_RUN=1 ;;
    --check-only)  CHECK_ONLY=1 ;;
    --yes|-y)      ASSUME_YES=1 ;;
    --skip-mcp)    SKIP_MCP=1 ;;
    --skip-skills) SKIP_SKILLS=1 ;;
    --mcp-scope)   shift; MCP_SCOPE="${1:-user}" ;;
    -h|--help)
      sed -n '2,40p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *) err "unknown flag: $1"; exit 2 ;;
  esac
  shift
done

# ----------------------------- prerequisites --------------------------------

head "Prerequisites"

PREQ_NODE=0; PREQ_RUST=0; PREQ_UV=0; PREQ_PYTHON=0; PREQ_DOCKER=0; PREQ_CLAUDE=0; PREQ_GIT=0; PREQ_GO=0

if have node && have npm; then ok "Node.js / npm  ($(node -v))"; PREQ_NODE=1
else warn "Node.js / npm not found  (needed for: claude CLI, some MCPs)"; fi

if have cargo; then ok "Rust / cargo  ($(cargo --version | awk '{print $2}'))"; PREQ_RUST=1
else warn "Rust / cargo not found  (needed for: aderyn via cargo, foundry build-from-source)"; fi

if have uv || have uvx; then ok "uv / uvx present"; PREQ_UV=1
else warn "uv not found  (recommended for: slither-mcp, halmos)"; fi

if have python3 && have pipx; then ok "python3 + pipx present"; PREQ_PYTHON=1
elif have python3; then warn "python3 present but pipx not found  (recommended for slither/mythril installs)"; PREQ_PYTHON=1
else warn "python3 not found  (needed for: slither, mythril, halmos)"; fi

if have docker; then ok "Docker present  ($(docker --version | awk '{print $3}' | tr -d ,))"; PREQ_DOCKER=1
else warn "Docker not found  (optional: echidna/medusa containers, ToB sandbox)"; fi

if have git; then ok "git present"; PREQ_GIT=1
else err "git not found  (REQUIRED to clone skill repos)"; fi

if have go; then ok "Go present  ($(go version | awk '{print $3}'))"; PREQ_GO=1
else warn "Go not found  (needed only to build medusa from source)"; fi

if have claude; then ok "Claude Code CLI present  ($(claude --version 2>/dev/null | head -1))"; PREQ_CLAUDE=1
else warn "Claude Code CLI ('claude') not found  (needed for MCP/skills registration)"; fi

# ------------------------- helper install routines --------------------------

# Generic "ensure a CLI tool exists" with a pluggable installer.
# $1 = friendly name, $2 = command to test, $3 = required(1)/optional(0),
# $4 = install function name (or "" to just report)
ensure_tool() {
  local name="$1" cmd="$2" required="$3" installer="$4"
  if have "$cmd"; then
    local ver=""
    ver="$("$cmd" --version 2>/dev/null | head -1)"
    ok "$name present${ver:+  ($ver)}"
    return 0
  fi

  if [[ "$required" -eq 1 ]]; then
    err "$name MISSING (required)"
  else
    warn "$name missing (optional)"
  fi

  if [[ -z "$installer" ]]; then
    info "$name has no automatic installer here; see notes below."
    [[ "$required" -eq 1 ]] && MISSING_REQUIRED=1
    return 1
  fi

  if [[ "$CHECK_ONLY" -eq 1 ]]; then
    info "check-only: skipping install of $name"
    [[ "$required" -eq 1 ]] && MISSING_REQUIRED=1
    return 1
  fi

  if confirm "Install $name now?"; then
    "$installer"
    if have "$cmd"; then
      ok "$name installed"
    else
      err "$name install attempted but '$cmd' still not on PATH (open a new shell?)"
      [[ "$required" -eq 1 ]] && MISSING_REQUIRED=1
      return 1
    fi
  else
    info "skipped $name"
    [[ "$required" -eq 1 ]] && MISSING_REQUIRED=1
  fi
}

# --- installers (each guarded; called only when tool is absent) ---

install_foundry() {
  # foundryup manages forge/cast/anvil/chisel
  if ! have foundryup; then
    run_sh "curl -L https://foundry.paradigm.xyz | bash"
    # foundryup lands in ~/.foundry/bin
    export PATH="$HOME/.foundry/bin:$PATH"
  fi
  run_sh "$HOME/.foundry/bin/foundryup || foundryup"
}

install_aderyn() {
  # Prefer cyfrinup; fall back to cargo.
  if have cyfrinup; then
    run cyfrinup
  elif [[ "$PREQ_RUST" -eq 1 ]]; then
    run cargo install aderyn
  else
    run_sh "curl -L https://raw.githubusercontent.com/Cyfrin/up/main/install | bash" \
      && info "Restart your shell, then run 'cyfrinup' to get aderyn."
  fi
}

install_slither() {
  if have uvx; then
    info "slither can be run on-demand via: uvx --from slither-analyzer slither ."
    run_sh "uv tool install slither-analyzer"
  elif have pipx; then
    run pipx install slither-analyzer
  elif have python3; then
    run_sh "python3 -m pip install --user slither-analyzer"
  fi
}

install_mythril() {
  # Two known footguns on fresh machines:
  #  1) mythril's 'coincurve' dep has no wheels for bleeding-edge CPython
  #     (e.g. 3.14) and its source build fails -> prefer an older interpreter.
  #  2) mythril's 'eth'/py-evm dep does 'import pkg_resources', which was
  #     removed from setuptools>=81 -> pin setuptools<81 into the venv.
  local py="" c
  for c in python3.13 python3.12 python3.11; do have "$c" && { py="$c"; break; }; done
  if have pipx; then
    if [[ -n "$py" ]]; then run pipx install mythril --python "$py"
    else run pipx install mythril; fi
    run pipx inject mythril "setuptools<81" --force
  elif have python3; then
    run_sh "python3 -m pip install --user mythril 'setuptools<81'"
  fi
  export PATH="$HOME/.local/bin:$PATH"
}

install_halmos() {
  if have uv; then run_sh "uv tool install halmos"
  elif have pipx; then run pipx install halmos
  elif have python3; then run_sh "python3 -m pip install --user halmos"; fi
}

install_echidna() {
  if [[ "$PREQ_DOCKER" -eq 1 ]]; then
    info "Pulling Echidna via Docker (no global binary install)."
    run docker pull ghcr.io/crytic/echidna/echidna:latest
  else
    info "Echidna: no Docker. Grab a static binary from github.com/crytic/echidna/releases"
  fi
}

install_medusa() {
  if [[ "$PREQ_GO" -eq 1 ]]; then
    run_sh "go install github.com/crytic/medusa@latest"
    # go installs to GOPATH/bin (default ~/go/bin), often not yet on PATH;
    # expose it so the post-install recheck finds the binary this run.
    export PATH="$(go env GOPATH 2>/dev/null)/bin:$HOME/go/bin:$PATH"
  elif [[ "$PREQ_DOCKER" -eq 1 ]]; then
    info "Medusa: build/run via Docker per crytic/medusa README."
  else
    info "Medusa: install Go or Docker, or download a release binary."
  fi
}

install_claude() {
  if [[ "$PREQ_NODE" -eq 1 ]]; then
    run npm install -g @anthropic-ai/claude-code
  else
    info "Install Node.js first, then: npm install -g @anthropic-ai/claude-code"
  fi
}

# ------------------------------ core tooling --------------------------------

head "Core deterministic tooling (the layer AI wraps)"

# forge is the real test; foundryup is the installer
if have forge; then ok "Foundry present  ($(forge --version 2>/dev/null | head -1))"
else
  warn "Foundry (forge) missing (required)"
  if [[ "$CHECK_ONLY" -eq 0 ]] && confirm "Install Foundry?"; then
    install_foundry
    have forge && ok "Foundry installed" || { err "forge still not on PATH (add ~/.foundry/bin)"; MISSING_REQUIRED=1; }
  else
    [[ "$CHECK_ONLY" -eq 1 ]] && info "check-only: skipping Foundry"
    MISSING_REQUIRED=1
  fi
fi

ensure_tool "Slither"  "slither"  1 install_slither
ensure_tool "Aderyn"   "aderyn"   1 install_aderyn
ensure_tool "Halmos"   "halmos"   0 install_halmos
ensure_tool "Mythril"  "myth"     0 install_mythril
ensure_tool "Medusa"   "medusa"   0 install_medusa

# Echidna is special (often Docker-only) - handle directly.
if have echidna; then ok "Echidna present"
elif docker image inspect ghcr.io/crytic/echidna/echidna:latest >/dev/null 2>&1; then
  ok "Echidna available via Docker image"
else
  warn "Echidna missing (optional)"
  [[ "$CHECK_ONLY" -eq 0 ]] && confirm "Set up Echidna?" && install_echidna
fi

# --------------------------- Claude Code CLI --------------------------------

head "Claude Code CLI"
if have claude; then
  ok "claude present"
else
  warn "claude CLI missing (required for MCP + skills automation)"
  if [[ "$CHECK_ONLY" -eq 0 ]] && confirm "Install Claude Code CLI?"; then
    install_claude
    have claude && PREQ_CLAUDE=1 || MISSING_REQUIRED=1
  else
    MISSING_REQUIRED=1
  fi
fi

# ------------------------------- MCP servers --------------------------------
# Only safe, read-only / analysis MCPs. We DELIBERATELY do not add any wallet
# MCP or any Foundry MCP that can sign/broadcast transactions.

head "MCP servers (safe, analysis-only)"

mcp_has() {
  # returns 0 if an MCP server with given name is already registered
  [[ "$PREQ_CLAUDE" -eq 1 ]] || return 1
  claude mcp list 2>/dev/null | grep -qiE "(^|[[:space:]])$1([[:space:]]|:|$)"
}

add_mcp() {
  # $1 = name, $2... = full 'claude mcp add' arg list
  local name="$1"; shift
  if [[ "$PREQ_CLAUDE" -ne 1 ]]; then
    warn "skip MCP '$name' (claude CLI absent)"; return 1
  fi
  if mcp_has "$name"; then
    ok "MCP '$name' already registered"; return 0
  fi
  warn "MCP '$name' not registered"
  if [[ "$CHECK_ONLY" -eq 1 ]]; then info "check-only: skipping"; return 1; fi
  if confirm "Register MCP '$name'?"; then
    run claude mcp add "$@"
  else
    info "skipped MCP '$name'"
  fi
}

if [[ "$SKIP_MCP" -eq 1 ]]; then
  info "MCP registration skipped (--skip-mcp)"
elif [[ "$PREQ_CLAUDE" -ne 1 ]]; then
  warn "Cannot manage MCP servers without the claude CLI."
else
  # Slither-MCP (Trail of Bits) - deterministic static-analysis ground truth.
  if [[ "$PREQ_UV" -eq 1 ]]; then
    add_mcp "slither" --transport stdio --scope "$MCP_SCOPE" slither \
      -- uvx --from git+https://github.com/trailofbits/slither-mcp slither-mcp
  else
    warn "slither-mcp wants uv/uvx; install uv to enable. Skipping."
  fi

  # Etherscan MCP (official, remote HTTP). Needs an API key in env.
  if [[ -n "${ETHERSCAN_API_KEY:-}" ]]; then
    add_mcp "etherscan" --transport http --scope "$MCP_SCOPE" etherscan \
      "https://mcp.etherscan.io/mcp?apikey=${ETHERSCAN_API_KEY}"
  else
    info "Set ETHERSCAN_API_KEY to auto-register the Etherscan MCP. Skipping for now."
  fi

  # OpenZeppelin Contracts MCP (official, remote HTTP) - secure generation side.
  add_mcp "openzeppelin" --transport http --scope "$MCP_SCOPE" openzeppelin \
    "https://mcp.openzeppelin.com/contracts/solidity/mcp"
fi

info "By design this script installs NO wallet MCP and NO tx-signing Foundry MCP."

# --------------------------------- skills -----------------------------------

head "Auditor skill repos"

if [[ "$SKIP_SKILLS" -eq 1 ]]; then
  info "Skill cloning skipped (--skip-skills)"
elif [[ "$PREQ_GIT" -ne 1 ]]; then
  err "git missing; cannot clone skill repos."
  MISSING_REQUIRED=1
else
  [[ "$CHECK_ONLY" -eq 1 || "$DRY_RUN" -eq 1 ]] || mkdir -p "$SKILLS_DIR"
  for i in "${!SKILL_REPO_NAMES[@]}"; do
    name="${SKILL_REPO_NAMES[$i]}"
    url="${SKILL_REPO_URLS[$i]}"
    dest="$SKILLS_DIR/$name"
    if [[ -d "$dest/.git" ]]; then
      ok "skill repo '$name' present -> $dest"
      if [[ "$CHECK_ONLY" -eq 0 ]] && confirm "git pull '$name' to update?"; then
        run_sh "git -C '$dest' pull --ff-only"
      fi
    else
      warn "skill repo '$name' not cloned"
      if [[ "$CHECK_ONLY" -eq 0 ]] && confirm "Clone '$name'?"; then
        run git clone --depth 1 "$url" "$dest"
      fi
    fi
  done
  info "Enable individual skills by symlinking the ones you want into ~/.claude/skills/,"
  info "e.g.  ln -s '$SKILLS_DIR/pashov-skills/solidity-auditor' ~/.claude/skills/"
  info "Review each SKILL.md and its scripts before enabling (skills run like software)."
fi

# -------------------------------- summary -----------------------------------

head "Summary"
if [[ "$DRY_RUN" -eq 1 ]]; then
  info "Dry run complete - nothing was changed."
fi
if [[ "$MISSING_REQUIRED" -eq 0 ]]; then
  ok "All REQUIRED components are present (or were installed)."
  exit 0
else
  warn "One or more REQUIRED components are still missing. Re-run after resolving prerequisites."
  exit 1
fi
