# Peer-`SendMessage` spike — result

**Date:** 2026-05-30
**Verdict:** `PEER_SENDMESSAGE: WORKS`

## What was tested

Two `general-purpose` agents were spawned into one team (`lfg-spike`) in a single
orchestrator turn. The reviewer was told to `SendMessage` the consolidator, and the
consolidator to reply via `SendMessage`. This proves whether a *spawned* teammate can
message a *sibling* (not just the orchestrator).

## Evidence (from team inbox files)

- `lfg-spike-reviewer` → `lfg-spike-consolidator`: `"FINDING count=21"` (delivered to consolidator inbox)
- `lfg-spike-consolidator` → `lfg-spike-reviewer`: `"ACK:42"` (21×2, delivered to reviewer inbox)
- `lfg-spike-reviewer` → `team-lead` final report (verbatim):
  ```
  SENDMESSAGE: SUCCESS
  REPLY: ACK:42
  ROUNDTRIP: WORKS
  ```

## Conclusions for the `/lfg` skill

1. **Peer-to-peer `SendMessage` works.** The pure-team model is the PRIMARY data plane:
   reviewers message the consolidator; the consolidator interrogates reviewers back.
2. **File-drop fallback is needed only for agent types whose `tools:` grant lacks
   `SendMessage`** — today that is `sui-pilot-agent` (until the companion change in Task 9
   ships). Generic (`general-purpose`/`claude`) reviewers chat directly.
   > **Update 2026-06-01:** `sui-pilot-agent` now carries the `SendMessage` grant in
   > the published build, so all current reviewer types use Mode A; Mode B stays as the
   > capability-based fallback for any future grant-less agent type.
3. **CRITICAL operational rule discovered:** a spawned teammate's *return value is NOT
   delivered to the orchestrator* — only `SendMessage` content and idle notifications reach
   the team lead. Therefore:
   - The consolidator MUST `SendMessage` its final summary to the main session (team lead),
     not merely "return" it. (Applied in `consolidator_prompt.md` / Phase 3.)
   - The orchestrator collects results from teammate messages + inbox, not from Agent-call
     return values.
4. Team must be created with `TeamCreate` before spawning members; `team_name` on the
   `Agent` tool does not auto-create the team.
