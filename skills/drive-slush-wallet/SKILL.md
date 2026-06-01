---
name: drive-slush-wallet
description: >-
  Drive the Slush Sui wallet browser extension during chrome-devtools-mcp web3
  testing — approve connection requests, sign personal messages, approve/sign
  transactions, and confirm a connected account, all hands-free. Use this
  WHENEVER you are automating a Sui dapp through chrome-devtools-mcp and a Slush
  approval popup needs a click — connect, sign-in message, mint, swap, any
  signature. The critical reason this skill exists: chrome-devtools-mcp CANNOT
  see or drive `chrome-extension://` pages, so the Slush popup never appears in
  `list_pages` and `click`/`take_snapshot` are blind to it — every wallet E2E
  stalls here. Trigger on "approve the wallet", "sign in with Slush", "connect
  Slush", "approve the transaction", "the wallet popup", "aprueba la wallet",
  "firma con Slush", or any time a Slush/Sui-wallet approval is blocking an
  automated browser flow. This skill does NOT launch or start the browser: if
  port 9222 is down, Chrome for Testing isn't running, or chrome-devtools-mcp
  gives ECONNREFUSED, run launch-dev-chrome FIRST. drive-slush-wallet assumes
  the wallet Chrome is already up on :9222 and only drives the in-extension
  Slush popups once you're attached.
---

# Driving the Slush wallet through chrome-devtools-mcp

You are automating a Sui dapp with chrome-devtools-mcp. The dapp side works
fine through the normal MCP tools (`navigate_page`, `take_snapshot`, `click`,
`evaluate_script`). Then the dapp asks the wallet to approve something — connect,
a sign-in message, a transaction — Slush opens a popup, and **everything
stalls**, because of one hard limitation:

> **chrome-devtools-mcp only attaches to http(s) page targets.** Browser
> extension pages (`chrome-extension://…`) — including every Slush approval
> popup — never appear in `list_pages`, and `new_page` won't surface them as a
> drivable target. So MCP's `take_snapshot`/`click` literally cannot see the
> button you need to press.

The fix is to talk the **raw Chrome DevTools Protocol** to the popup directly.
That bundled capability is `scripts/cdp.py` — a dependency-free (stdlib-only)
CDP-over-WebSocket client. The DevTools endpoint on `:9222` exposes *all*
targets over WebSocket, extension pages included; MCP just chooses not to. This
skill drives them anyway.

## Prerequisite

A debuggable Chrome-for-Testing must be up on `127.0.0.1:9222` with the **Slush
extension installed and the wallet unlocked**. That is exactly what the
**launch-dev-chrome** skill guarantees. If `curl -sS http://127.0.0.1:9222/json/version`
fails, run launch-dev-chrome first — do not continue here until the port is live
and a Slush extension target is present.

Slush extension id (you will match on this constantly):
`opcgpfmipidbgpenhmajoajpbobppdil`

## The mental model

There are two worlds, and you switch between them:

| What you're driving | Tool to use |
|---|---|
| The **dapp** page (https://…) — buttons, modals, connect flow, post-login checks | chrome-devtools-mcp (`navigate_page`, `take_snapshot`, `click`, `evaluate_script`) |
| The **Slush popup** (`chrome-extension://…`) — Approve / Reject / Sign / Confirm | `scripts/cdp.py` (this skill) |

The handoff point is always the same: you click something on the dapp that needs
the wallet → a Slush popup opens → you leave MCP, drive the popup with `cdp.py`,
press the right button → control returns to the dapp.

## The core loop

For every wallet approval, the loop is **discover → inspect → click → verify**.

### 1. Discover the popup target

Slush popups are page targets whose URL is `chrome-extension://<id>/index.html#<action>?…`.
List them:

```bash
python3 scripts/cdp.py targets opcgpfmipidbgpenhmajoajpbobppdil
```

The action lives in the URL hash and tells you what's being requested:

- `#approve-connection` — dapp wants to connect (share your address)
- `#sign-personal-message` — a string signature, e.g. SIWE-style "sign in to
  complete your login"; the `bytes=` query param is the **base64 of the exact
  message** — decode it to see what you're signing
- `#approve-transaction` / `#sign-transaction` — a PTB to sign and/or execute;
  this moves funds or changes on-chain state, so treat it with care
- `#unlock` or a popup with a password field — the wallet is **locked** (see
  Safety below)

The URL also carries useful context: `appName`, `appUrl`, `accountAddress`, and
`network` (mainnet/testnet/localnet). Don't hardcode the hash names — they can
evolve; always `inspect` to confirm what the popup is actually showing.

> **Don't over-trust your first listing.** A substring like `suigar.com` also
> matches the popup URLs (the dapp origin is embedded in `appUrl=`). When
> `cdp.py` reports several matches it prints the candidates with ids — pass the
> specific target id to disambiguate. Match on the extension id or the action
> hash to find the popup, not on the dapp domain.

### 2. Inspect — read what the popup is asking before you touch it

```bash
python3 scripts/cdp.py inspect <id-or-#action-or-ws-url>
```

This prints the title, visible body text, every clickable label, and a
`hasPasswordField` flag. Use it to (a) confirm the request is what you expect,
and (b) learn the exact button label to click — Slush uses **Approve / Reject**
for connections and **Sign / Confirm / Reject** for signatures, but read the
actual labels rather than assuming.

### 3. Click the right button

```bash
python3 scripts/cdp.py click <target> "Approve"
```

`click` matches a button by trimmed text or aria-label (case-insensitive, with a
contains-fallback) and clicks it. If nothing matches it prints the available
labels so you can retry with the correct one.

### 4. Verify on the dapp side (back to MCP)

The popup closes itself once resolved. Confirm the *dapp* reflects the new state
through chrome-devtools-mcp — this is the real proof, not the click succeeding:

```js
// via mcp evaluate_script on the dapp page
() => {
  const txt = document.body.innerText;
  return JSON.stringify({
    signedIn: ![...document.querySelectorAll('button')].some(b => /sign in|connect wallet/i.test(b.innerText)),
    address: (txt.match(/0x[a-fA-F0-9]{4}[….]{1,3}[a-fA-F0-9]{4}/) || [])[0] || null,
  });
}
```

For a transaction, verify the dapp shows success / the balance or object changed,
and (if it matters) that the digest landed on-chain.

## Worked example — connect + sign-in (the canonical login)

Most Sui dapps log in with connect-then-sign: approve the connection, then sign a
"welcome" message. Both are popups; drive both with this skill.

1. **Dapp (MCP):** click the dapp's Sign In / Connect, then pick **Slush** in the
   dapp's wallet modal. This wakes the Slush service worker and opens the popup.
2. **Popup (cdp.py):** `targets … | inspect #approve-connection` → confirm
   "Connection request" from the right `appName` and the expected account →
   `click #approve-connection "Approve"`.
3. The dapp immediately requests the login signature → a `#sign-personal-message`
   popup opens. `inspect` it (decode `bytes=` to read the message — it should be a
   benign login string), then `click … "Sign"`.
4. **Dapp (MCP):** verify `signedIn: true` and the address in the header.

## Timing and lifecycle gotchas (these will bite you)

- **Popups auto-close.** Slush approval windows dismiss on focus loss or after a
  timeout. Act promptly: discover → inspect → click in one go. If the target
  vanished before you clicked, it timed out — re-trigger the request from the
  dapp and try again.
- **The service worker goes dormant.** Between requests, `targets` for the Slush
  id may be empty (the MV3 background worker is asleep). That's normal — it wakes
  when the dapp next calls the wallet. An empty list right after a dapp action
  usually means "the popup didn't open," not "the wallet is gone."
- **Duplicate popup targets.** You may see two page targets sharing one
  `requestId` (e.g. if a window and a tab both rendered it). They back the same
  pending request — driving either one resolves it.
- **Popup not yet mounted.** A freshly opened popup can briefly return an empty
  body / no clickables (React hasn't mounted). Re-`inspect` after a moment before
  concluding anything.
- **Don't try to make MCP attach.** Running launch-dev-chrome again, calling
  `new_page` on the extension URL, or restarting the MCP connection will NOT make
  chrome-devtools-mcp list the extension popup. The CDP path is the supported
  route, by design.

## Safety — what to refuse

- **Locked wallet:** if `inspect` shows a password field (`hasPasswordField: true`)
  or an Unlock screen, the wallet is locked. **Stop and ask the user to unlock
  Slush.** Never type, request, or guess a wallet password, and never touch a
  seed phrase — the user onboarded the wallet themselves.
- **Signing requests move value.** Approving a connection only shares an address
  and is low-risk. A `sign-transaction` / `approve-transaction` can move funds or
  mint/transfer objects. Always `inspect` and, for anything beyond a benign
  personal-message login, confirm with the user what they intend to sign before
  clicking — unless they've already authorized this specific automated flow.
- **Localnet caveat (from launch-dev-chrome):** the hosted Slush *web* wallet
  (`my.slush.app`) cannot sign against a private localnet. The Slush *extension*
  this skill drives can, provided its active network is pointed at your localnet
  RPC. If signing fails with a network error, check the `network=` param in the
  popup URL and the extension's selected network.

## The bundled tool

`scripts/cdp.py` is self-contained (Python 3 stdlib only — no `pip install`, no
Node, no `ws` module). Commands: `targets [substr]`, `inspect <target>`,
`click <target> <text>`, `eval <target> <js>`. `<target>` is a `ws://` debugger
URL, a target id, or a URL substring that resolves to a single page target.
Override host/port with `CDP_HOST` / `CDP_PORT` (defaults `127.0.0.1:9222`).
`eval` runs arbitrary JS in any target and works on normal pages too — handy when
you want a quick read without going through MCP. Read the script's header
docstring for details.
