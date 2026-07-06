# Team-coordination spikes — results

Two spikes inform the /lfg Phase 3 design. The 2026-05-30 spike validated messaging
under the OLD explicit-team model (removed in Claude Code 2.1.178); the 2026-07-06
re-spike re-grounded the skill in the current implicit-team model. Trust the 2026-07-06
sections; the 2026-05-30 results are kept only where the mechanism they proved survives.

## 2026-07-06 re-spike (Claude Code 2.1.201, implicit-team model)

**Setup:** two `general-purpose` teammates (`spike-listener`, `spike-echo`) spawned with
the `Agent` tool's `name` parameter from a headless background session; peer + lead
messaging exercised via `SendMessage`.

### Confirmed empirically

1. **No team-setup step exists.** `TeamCreate`/`TeamDelete` are gone (removed in
   2.1.178); `team_name` on the `Agent` tool is accepted but ignored. Spawning a named
   agent auto-registers it in the session's single implicit team.
2. **Team state layout:** `~/.claude/teams/session-<8-char-session-id>/` gains a
   `config.json` (members, `leadAgentId`) and per-member `inboxes/<name>.json` the moment
   teammates spawn. Same shape as the old per-team dirs, new session-derived naming.
3. **The lead's address is `team-lead`** — fixed by the harness
   (`leadAgentId: team-lead@session-…` in config.json). Use it as `{{LEAD_NAME}}`.
4. **Teammates launch on a tmux/pane backend** (`backendType: "tmux"` in config.json;
   the orchestrating session is `in-process`). **From a headless/background session the
   teammate processes never started**: both members stayed `isActive: false`, produced no
   output, and a wake `SendMessage` (queued successfully) was never consumed. This is why
   SKILL.md requires running /lfg from an interactive main session.
5. **Inbox JSON files are a delivery queue, not an archive** — a successfully queued
   message no longer appears in the file after the harness processes it, so inbox files
   are only a weak debugging signal (hence "best-effort only" in Phase 3.3 recovery).

### Confirmed from official docs (not re-verified empirically under the new model)

- **Peer-to-peer SendMessage between named teammates** — agent-teams docs: any teammate
  can message any other by name. Also proven empirically on 2026-05-30 under the old
  model (`FINDING count=21` / `ACK:42` roundtrip). The skill's Mode A relies on this.
- **SendMessage auto-resumes stopped agents** (2.1.77) and **wakes stuck teammates**
  (2.1.198); a send to a name that now resolves to a different agent than earlier in the
  conversation is **refused** (2.1.199) — so per-run unique names (PR-number suffix).

### Unresolved — and deliberately not load-bearing

- **Whether a teammate's plain return value reaches the lead** under the implicit-team
  model. The 2026-05-30 spike observed it does NOT (only SendMessage + idle notifications
  arrived); current sub-agent docs say a subagent's final message IS returned to its
  spawner; teammate backends may differ. The headless re-spike could not settle it.
  Phase 3 is therefore written to work either way: the consolidator MUST SendMessage its
  summary, the lead accepts a completion notification carrying the same content, and
  `gh pr view` is the authoritative recovery check.

## 2026-05-30 spike (historical — explicit-team model, pre-2.1.178)

Two `general-purpose` agents spawned into an explicit team (`lfg-spike`) created with
`TeamCreate`. Results that still matter:

- Peer roundtrip worked: reviewer → consolidator `"FINDING count=21"`, consolidator →
  reviewer `"ACK:42"`; reviewer reported `ROUNDTRIP: WORKS` to the lead.
- A teammate's return value was NOT delivered to the orchestrator — only SendMessage
  content and idle notifications reached the lead (see "Unresolved" above for current
  status).

Results that are now dead: the `TeamCreate`-before-spawn requirement and everything
`team_name`-related (the tool was removed and the parameter is ignored as of 2.1.178);
the per-agent-type SendMessage-grant inventory (point-in-time; SKILL.md 3.1 now derives
the mode from the agent type's tools grant at dispatch time instead of from this file).
