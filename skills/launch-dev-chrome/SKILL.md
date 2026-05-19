---
name: launch-dev-chrome
description: |
  Launches "Google Chrome for Testing" with --remote-debugging-port=9222 and
  the user's persistent dev profile (~/dev-chrome, where MetaMask + Slush are
  already installed and unlocked) so chrome-devtools-mcp can attach to it for
  web3 dapp end-to-end testing. Idempotent — skips launch if port 9222 already
  responds.

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

  Skip if:
  - The user explicitly wants to drive their default Chrome profile instead
    of the isolated dev profile.
  - chrome-devtools-mcp is already proven attached in this session (a
    `list_pages` call has succeeded since the last shell restart).
allowed-tools: Bash
---

# Launch dev Chrome for Testing for chrome-devtools-mcp

The user's chrome-devtools-mcp server is configured to **attach** to a Chrome
running on `http://127.0.0.1:9222`, not to spawn its own Chromium. This skill
brings up that Chrome with the persistent wallet profile so MCP calls land in
the right place instead of erroring with `ECONNREFUSED` or popping a fresh
window.

## Pre-flight: is it already up?

```bash
curl -sS -m 1 http://127.0.0.1:9222/json/version > /dev/null 2>&1 && echo up || echo down
```

- `up` → do nothing. Attach is already possible; just call the MCP tool.
- `down` → proceed to launch.

## Launch command

```bash
"/Applications/Google Chrome for Testing.app/Contents/MacOS/Google Chrome for Testing" \
  --remote-debugging-port=9222 \
  --user-data-dir="$HOME/dev-chrome" \
  > /dev/null 2>&1 &
```

What each piece is doing:

- **Binary** — Chrome for Testing (not regular Chrome). It's the build
  chrome-devtools-mcp's puppeteer dependency targets, so versions stay aligned.
- **`--remote-debugging-port=9222`** — opens the DevTools Protocol endpoint
  at `http://127.0.0.1:9222` that chrome-devtools-mcp attaches to.
- **`--user-data-dir=$HOME/dev-chrome`** — reuses the persistent profile
  where MetaMask + Slush are already installed and unlocked. A fresh dir
  would force re-onboarding with seed phrases.
- **`> /dev/null 2>&1 &`** — background and detach. The Bash tool's
  `run_in_background` flag works too if you prefer.

## Verify the attach is live

Give Chrome ~1s to bind the port, then:

```bash
sleep 1 && curl -sS -m 2 http://127.0.0.1:9222/json/version | head -3
```

Expect JSON with `"Browser": "Chrome/<version>"`. Once that responds, the
chrome-devtools-mcp `list_pages` call will work without popping a new window.

## Common failures

- **"ProfileInUse" / Chrome refuses to start** — A previous Chrome for
  Testing window is still open with `~/dev-chrome`. Either close those
  windows first, or treat the running instance as the target (its debug
  port should already be up — re-run the pre-flight check).
- **Port 9222 reachable but `list_pages` returns empty** — Chrome started
  but hasn't surfaced any real tab. Call `new_page` against `about:blank`
  in the background to wake it.
- **MetaMask / Slush extensions missing** — `~/dev-chrome` was wiped or the
  flag pointed elsewhere. Do NOT silently reinstall — ask the user, since
  they onboarded those wallets manually with seed phrases.

## Why this skill exists

chrome-devtools-mcp is launched with `--browserUrl http://127.0.0.1:9222` so
it attaches to an existing Chrome instead of spawning its own. That fixes a
regression where every MCP tool call popped a stray Chromium window. The
trade-off: someone has to make sure that Chrome is actually running before
any MCP call. This skill is that someone — invoke it any time port 9222 is
not known to be live.
