# Team-coordination spikes — results

Two spikes inform the /lfg Phase 3 design. The 2026-05-30 spike validated messaging
under the OLD explicit-team model (removed in Claude Code 2.1.178); the 2026-07-06
re-spike re-verified everything under the current implicit-team model.

## 2026-07-06 re-spike (Claude Code 2.1.201, implicit-team model) — COMPLETE

**Setup:** two `general-purpose` teammates (`spike-listener`, `spike-echo`) spawned with
the `Agent` tool's `name` parameter from a headless background session. Echo messaged the
listener (peer) and the lead; the listener relayed what it received; both also emitted
plain final messages. All channels were eventually observed end-to-end.

### Confirmed empirically

1. **No team-setup step exists.** `TeamCreate`/`TeamDelete` are gone (removed in
   2.1.178); `team_name` on the `Agent` tool is accepted but ignored. Spawning a named
   agent auto-registers it in the session's single implicit team.
2. **Team state layout:** `~/.claude/teams/session-<8-char-session-id>/` gains a
   `config.json` (members, `leadAgentId`) and per-member `inboxes/<name>.json` the moment
   teammates spawn. Same shape as the old per-team dirs, new session-derived naming.
3. **The lead's address is `team-lead`** — fixed by the harness
   (`leadAgentId: team-lead@session-…`); a teammate's `SendMessage` to it was delivered
   (`LEAD-MSG-9` roundtrip). Use it as `{{LEAD_NAME}}`.
4. **Peer-to-peer SendMessage between named teammates WORKS** under the implicit model:
   `spike-echo → spike-listener` (`PEER-MSG-7`) was delivered and relayed back on first
   try. Re-confirms the 2026-05-30 result on the current harness.
5. **A teammate's plain final message IS delivered to the lead** as a teammate message,
   alongside idle notifications (`RETVAL-ALPHA-42` report arrived without any
   teammate-initiated SendMessage to the lead). This reverses the 2026-05-30 finding —
   but keep reporting SendMessage-primary anyway (see "Design consequence" below).
6. **Teammates carry the `Agent` tool** (and Bash natively; SendMessage/TaskCreate via
   ToolSearch). "Having the Agent tool" is therefore NOT a valid main-session check;
   nested teammate spawning is restricted at the harness level instead (2.1.69).
7. **Headless/background sessions start teammates with LONG delays** — on a tmux/pane
   backend (`backendType: "tmux"`), both teammates sat `isActive: false` with silent
   inboxes for ~25+ minutes before running and delivering everything. Not a failure, but
   plan for it: run /lfg interactively, budget generous waits, and don't declare a
   teammate dead early.
8. **Inbox JSON files are a delivery queue, not an archive** — a successfully queued
   message no longer appears in the file after processing, so inbox files are only a weak
   debugging signal (hence "best-effort only" in Phase 3.3 recovery).

### Also relevant (from docs/changelog, consistent with observations)

- `SendMessage` auto-resumes stopped agents (2.1.77) and wakes stuck teammates (2.1.198);
  a send to a name that now resolves to a different agent than earlier in the
  conversation is **refused** (2.1.199) — so per-run unique names (PR-number suffix).

### Design consequence for Phase 3

Both reporting channels work, but final-message delivery timing isn't under the skill's
control on slow-starting teammates — so Phase 3.3 keeps reporting dual-channel
(SendMessage-primary, whichever arrives first) with `gh pr view` as the authoritative
recovery check.

## 2026-05-30 spike (historical — explicit-team model, pre-2.1.178)

Two `general-purpose` agents spawned into an explicit team (`lfg-spike`) created with
`TeamCreate`. Peer roundtrip worked (`FINDING count=21` / `ACK:42`; `ROUNDTRIP: WORKS`).
Its other conclusions are superseded: the return-value-never-delivered rule no longer
holds (see item 5 above), the `TeamCreate`-before-spawn requirement and everything
`team_name`-related are dead (2.1.178), and the per-agent-type SendMessage-grant
inventory was point-in-time — check the agent type's tools grant at dispatch time
instead.
