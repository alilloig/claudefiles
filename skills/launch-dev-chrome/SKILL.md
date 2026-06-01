---
name: launch-dev-chrome
description: |
  Launches "Google Chrome for Testing" with --remote-debugging-port=9222 and
  the user's persistent dev profile (~/dev-chrome, where MetaMask + Slush are
  already installed and unlocked) so chrome-devtools-mcp can attach to it for
  web3 dapp end-to-end testing. Guarantees the DEBUGGABLE instance is the one
  holding the wallet profile (not an extension-less fallback).

  Use this skill whenever:
  - About to drive a web3 / dapp end-to-end test through chrome-devtools-mcp
    (MetaMask popups, Slush approvals, wallet signatures, on-chain mints).
  - The user says "launch dev chrome", "start dev chrome", "bring up dev
    chrome", "open my testing chrome", "abre el chrome de pruebas", or any
    variant.
  - chrome-devtools-mcp returns "Could not connect to Chrome" or
    `ECONNREFUSED` on port 9222.
  - About to call any chrome-devtools-mcp tool and port 9222 has not been
    verified live in this session.
  - The dapp's wallet-connect modal shows no wallets (a sign you're attached to
    an extension-less instance — see the profile-lock trap below).

  Skip if:
  - The user explicitly wants to drive their default Chrome profile instead
    of the isolated dev profile.
  - chrome-devtools-mcp is already proven attached to the WALLET profile in
    this session (a `list_pages` succeeded AND the extension check below passed).
allowed-tools: Bash
---

# Launch dev Chrome for Testing for chrome-devtools-mcp

The user's chrome-devtools-mcp server is configured to **attach** to a Chrome
running on `http://127.0.0.1:9222`, not to spawn its own Chromium. This skill
brings up that Chrome **with the wallet profile** so MCP calls land in an
instance where MetaMask + Slush are actually loaded.

That attach is **not** the plugin default — the marketplace plugin ships a bare
`npx chrome-devtools-mcp` with no `--browser-url`, which makes it spawn its own
wallet-less Chrome and ignore the one this skill launches (the *attach trap*
below). A SessionStart hook (`~/.claude/hooks/patch-chrome-devtools-mcp.sh`)
re-adds `--browser-url=http://127.0.0.1:9222` to the installed plugin every
session so the attach survives marketplace auto-updates. This skill assumes that
hook is in place; if MCP ever opens a second, extension-less window, the hook
didn't run or the MCP connection wasn't restarted after it did.

## The profile-lock trap (read this first)

A `--user-data-dir` can only be owned by ONE Chrome process. If a
Chrome-for-Testing is already running on `~/dev-chrome` **without** the debug
port, and you then launch a second instance with `--user-data-dir=~/dev-chrome
--remote-debugging-port=9222`, Chrome cannot lock the busy profile and silently
falls back to a **fresh, extension-less** profile. The debug port comes up, your
MCP calls attach — but there is **no wallet**, so the dapp's connect modal is
empty and you can't sign anything. Checking only "is 9222 up?" does NOT catch
this. You must also confirm the wallet profile is the one being debugged.

Wallet extension ids (used to verify the right profile loaded):
- MetaMask: `nkbihfbeogaeaoehlefnkodbefgpgknn`
- Slush:    `opcgpfmipidbgpenhmajoajpbobppdil`

## The attach trap (the OTHER way you end up wallet-less)

Distinct from the profile-lock trap: even with a perfect wallet Chrome on 9222,
if chrome-devtools-mcp wasn't given `--browser-url`, it **spawns its own regular
Chrome** (profile `~/.cache/chrome-devtools-mcp/chrome-profile`, no extensions)
and every MCP call lands there. Symptom: **two Chrome windows** — your
Chrome-for-Testing (wallets, unused) and a generic Chrome (no wallets, the one
MCP drives). `list_pages` succeeds against the wrong browser, so it looks
attached but the connect modal is empty.

Confirm MCP attached to the RIGHT browser (not a spawned one):

```bash
# A regular Google Chrome on the MCP cache profile = MCP spawned its own (bad).
ps aux | grep -i "Google Chrome.app" | grep -v "Chrome for Testing" | grep -v grep \
  | grep -oE -- '--user-data-dir=[^ ]*chrome-devtools-mcp[^ ]*' | sort -u
```

- Output present → MCP is NOT attaching. The `--browser-url` flag is missing
  from the plugin config. Run `~/.claude/hooks/patch-chrome-devtools-mcp.sh`,
  then **restart the MCP connection** (config changes don't hot-reload), and
  kill the stray `pkill -f "chrome-devtools-mcp/chrome-profile"`.
- No output → MCP is attaching to your 9222 Chrome. Good.

## Step 1 — Assess what's actually running

```bash
# Is the debug port up?
curl -sS -m 1 http://127.0.0.1:9222/json/version >/dev/null 2>&1 && echo "port:up" || echo "port:down"
# Which Chrome-for-Testing mains are running, and with what flags?
ps aux | grep -i "Chrome for Testing" | grep -v grep | grep -vE 'Helper|--type=' \
  | grep -oE -- '--(user-data-dir|remote-debugging-port)=[^ ]+' | sort -u
```

Interpret:
- **port:down, nothing on `~/dev-chrome`** → clean launch (Step 2).
- **port:down, but a Chrome-for-Testing already holds `~/dev-chrome`** (no
  `--remote-debugging-port`) → this is the trap. A naive launch will be
  extension-less. Do a **clean restart** (Step 2, which kills first).
- **port:up** → still verify it's the wallet profile (Step 3) before trusting it.

## Step 2 — Launch (clean restart) the single debuggable wallet instance

To guarantee no profile-lock fallback, ensure exactly ONE Chrome-for-Testing
owns the profile and it is the debuggable one. Kill any existing
Chrome-for-Testing first (the profile persists on disk — wallets are NOT lost;
ask the user before doing this if they may have unsaved work open):

```bash
pkill -f "Google Chrome for Testing" 2>/dev/null; sleep 1
"/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/dev-chrome" \
  > /dev/null 2>&1 &
sleep 2
```

- **`--remote-debugging-port=9222`** — the DevTools endpoint chrome-devtools-mcp attaches to.
- **`--user-data-dir=$HOME/dev-chrome`** — the persistent profile with MetaMask + Slush unlocked.
- Killing first avoids the profile-lock trap; a single owner gets both the extensions AND the port.

## Step 3 — Verify the WALLET profile is the debuggable one (not a fallback)

Port-up is necessary but NOT sufficient. Confirm a wallet extension actually
loaded in the attached instance:

```bash
curl -sS -m 2 http://127.0.0.1:9222/json/version | head -2
# At least one wallet extension target must be present:
curl -s http://127.0.0.1:9222/json \
  | grep -oE 'chrome-extension://(nkbihfbeogaeaoehlefnkodbefgpgknn|opcgpfmipidbgpenhmajoajpbobppdil)' \
  | sort -u
```

- A `chrome-extension://<id>` line for MetaMask and/or Slush → the real profile is loaded. Proceed.
- **No extension lines** → you're on an extension-less fallback (the trap fired,
  or `~/dev-chrome` is wrong/wiped). Re-run Step 2's clean restart. If still
  empty, confirm `ls ~/dev-chrome/Default/Extensions` lists the ids above; if it
  doesn't, the profile was wiped — STOP and ask the user (do not reinstall;
  they onboarded the wallets with seed phrases).

Note: Slush is an MV3 service worker that can be **dormant** and may not appear
as a target until the dapp first requests a wallet. MetaMask's service worker is
usually present immediately and is the more reliable presence signal. The
definitive functional check is opening the dapp's connect modal and seeing the
wallet listed — do that as the first step of any wallet E2E.

## Step 4 — Before driving a LOCALNET dapp: the wallet must support localnet

Getting the right debuggable+wallet instance is necessary but still not enough
for a **localnet** dapp. The **Slush web / zkLogin wallet** (`my.slush.app`,
which the in-modal "Slush" entry routes to) is a **hosted** wallet that submits
through its own mainnet/testnet backend — it **cannot sign or execute against a
private localnet** (`127.0.0.1:9000`). Symptoms: after connecting, the account
shows `$0` / "Acquire SUI to begin transacting" on mainnet, and any localnet
mint/sign fails. This is independent of the profile-lock trap.

For hands-free **localnet** E2E, prefer a signer that can actually sign localnet:
- A **local dev keypair** in the dapp (faucet-funded Ed25519 signing PTBs
  directly via the JSON-RPC client) — no wallet, no popups, fully automatable.
  Note localnet's JSON-RPC rejects the auto `simulateTransaction` gas
  estimation, so set an explicit `tx.setGasBudget(...)`.
- Or a wallet that supports an **imported local key + a custom localnet RPC**
  (some extension wallets do; the hosted Slush web wallet does not).

Use the hosted-wallet path for **public-network** (testnet/mainnet) E2E, where
Slush web works (real network + faucet) and approvals come back as
`my.slush.app/dapp-request` pages you can drive via chrome-devtools.

## Common failures

- **Two Chrome windows, one wallet-less / connect modal empty** — the attach
  trap. MCP spawned its own Chrome because `--browser-url` is missing. Run the
  patch hook, restart the MCP connection, kill the stray cache-profile Chrome.
- **Connect modal is empty / wallet missing (one window)** — the profile-lock
  trap. Clean-restart (Step 2) so the debuggable instance owns `~/dev-chrome`.
- **Connected, but localnet mint/sign fails / account is $0 mainnet** — the
  hosted web wallet can't do localnet (Step 4). Switch to a local-key signer.
- **"ProfileInUse" / Chrome refuses to start** — another instance holds the
  profile. `pkill -f "Google Chrome for Testing"` then relaunch (Step 2).
- **Port 9222 reachable but `list_pages` empty** — call `new_page` against the
  app URL (or `about:blank`) to surface a tab.
- **Extensions dir empty in `~/dev-chrome`** — profile wiped. Do NOT silently
  reinstall — ask the user.

## Why this skill exists

chrome-devtools-mcp attaches (`--browser-url http://127.0.0.1:9222`, injected by
the `patch-chrome-devtools-mcp.sh` SessionStart hook) instead of spawning, so
something must guarantee a Chrome is up on 9222 — AND that it is the wallet
profile, not an extension-less fallback. This skill is that guarantee. The hook
guarantees MCP actually attaches to it instead of opening its own window.
