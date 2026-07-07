# Incident 2026-07-07 — daemon respawn swapped the lead into a reviewer

Evidence-verified post-mortem of a headless /lfg run that silently lost its orchestrator.

## What happened

A headless background job ("sui-pilot-prover", Claude Code 2.1.202, daemon backend) ran
/lfg against a repo PR #38. Phase 1 shipped the PR normally. Phase 2's /simplify fanned
out four dimension subagents (`simp-reuse-38`, `simp-simplify-38`, `simp-efficiency-38`,
`simp-altitude-38`); a second /lfg pass respawned them under `-r2` names. Background
subagents took hours to start (the documented ~25min+ lag from `spike-results.md`,
observed worse). During the long waits the job daemon respawned/resumed the MAIN
conversation several times; on the final respawn the main transcript began with a
reviewer dispatch — `<teammate-message teammate_id=team-lead>You are an ALTITUDE
reviewer...` — instead of any orchestrator context. The lead adopted the reviewer
identity, performed the review itself, sent SendMessage to "team-lead" (which resolved
to its own fresh single-member team: a self-addressed black hole), and declared the job
done. Phase 3 (`rev-*` reviewers + consolidator) and Phase 4 (adjudication/approve)
never ran. Both RUN_DIRs stayed empty. The PR ended with zero reviews.

## Root cause

Orchestrator identity and progress lived ONLY in conversation prose. A daemon respawn
that re-seeded the context with a teammate-addressed message silently swapped the lead's
role — nothing durable contradicted it.

## Reliable discriminator

A spawned subagent/teammate is explicitly told so in its system prompt; the job's main
session instead gets the background-job system prompt, and its RUN_DIRs live under its
own `CLAUDE_JOB_DIR`. System prompt + on-disk state decide who you are — never prose.

## Fixes in this change

1. `scripts/run_state.sh` — durable per-run `state.json` (phase, PR refs, roster,
   consolidator, run token, repo root, skill dir), checkpointed at every phase boundary
   in SKILL.md; aborted runs are marked terminal, and `init` refuses to clobber an
   in-flight run without `--force`.
2. SKILL.md wake guard — on any resume, scan `${CLAUDE_JOB_DIR:-$TMPDIR}/lfg-*/state.json`;
   an incomplete run whose `repo_root` matches yours (and whose PR is still open) means
   YOU are its lead and any reviewer/consolidator dispatch in context is mis-delivered.
   A respawned lead's team is fresh — its old SendMessage addresses are dead letters.
3. Sanity-check headers atop `reviewer_prompt.md` + `consolidator_prompt.md` — a
   self-sufficient antidote for when SKILL.md is not in context — plus a resume tripwire
   in the skill's frontmatter description, visible even when only the skill list is.
4. Phase 2 headless-slimming rule — no multi-agent /simplify fan-out in background runs
   (headless = `CLAUDE_JOB_DIR` set; the constraint is passed into the /simplify call).
