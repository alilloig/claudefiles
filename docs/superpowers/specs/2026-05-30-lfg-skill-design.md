# `/lfg` skill — design

**Date:** 2026-05-30
**Status:** Approved (brainstorming complete; ready for implementation plan)
**Author:** Álvaro + Claude

## Summary

`/lfg` ("let's f***ing go") is a one-command "ship + harden + review + adjudicate"
pipeline for a pull request. It chains four phases, all orchestrated from the **main
Claude Code session**:

1. **Ship** — invoke `/commit-push-pr` (branch off `main` if needed, commit, push, open PR).
2. **Simplify** — invoke `/simplify` (edits the working tree for reuse/efficiency/clarity),
   then land those edits as a *second* commit and push.
3. **Team review** — spawn a team of dimension-specialised reviewer subagents plus one
   consolidator subagent; reviewers report findings, the consolidator double-checks them
   against the source and posts **one GitHub PR review** with inline `suggestion` blocks
   plus a walkthrough comment.
4. **Self-adjudicate** — the main session accepts or rejects each suggestion on its merits,
   applies the accepted ones as a third commit, resolves the threads, and **approves** the
   PR, leaving it merge-ready for a human.

The deliverable is a GitHub-native PR (commits + a posted review + an approval), not an
HTML artifact — the medium *is* the PR.

## Goals

- Collapse the routine "commit → open PR → clean up → review → address review" loop into a
  single `/lfg` invocation.
- Produce a **high-confidence** review (independent reviewers + a verifying consolidator),
  not a single-pass skim.
- Be **domain-aware**: route Move diffs through `sui-pilot-agent` reviewers (which run
  `/move-code-review` + `/move-code-quality` internally) and everything else through generic
  reviewers.
- Work **today** even before the companion `sui-pilot` change ships (graceful degradation).

## Non-goals

- Not a replacement for `move-pr-review` (deep Move-only audit) or `/code-review` (single
  comment pass). `/lfg` composes the ship+review loop; it may *delegate* to those engines.
- No HTML report. The PR review is the artifact.
- Does not merge the PR. It approves and leaves merge to a human (per user choice, the bot
  auto-approves; a human still clicks merge).

## Vehicle & location

A **skill** (orchestration logic + agent dispatch, too rich for a thin command):

- `~/.claude/skills/lfg/SKILL.md` (this repo; `~/.claude` → `/Users/alilloig/workspace/dotfiles/.claude`).
- Supporting files as needed under `skills/lfg/` (e.g. `references/reviewer_prompt.md`,
  `references/consolidator_prompt.md`, `scripts/` for any helper).
- Sits alongside the existing `move-pr-review` and `stepped-pr` skills.

## Architecture

### Orchestration model: agent team + `SendMessage`, with a file-drop fallback

The **main session is the orchestrator throughout** — it is the only context reliably
granting the `Agent` tool, so all spawning happens there. The team feature
(`TeamCreate` + named agents + `SendMessage`) is used so the consolidator can *coordinate*
(not spawn) the reviewers: pull findings and interrogate uncertain ones back-and-forth.

**Hard constraint (why the design is shaped this way):** a *spawned* subagent typically
cannot spawn further subagents (it lacks the `Agent`/`Task` tool — see
`skills/move-pr-review/SKILL.md` line 34). Therefore the consolidator cannot spawn the
reviewers; the main session spawns *everyone* into one team in a single turn, and the
consolidator only communicates with the already-running reviewers.

**Transitional fallback (graceful degradation):** `SendMessage` is only in an agent's
toolbox if its `tools:` grant includes it. Today, `sui-pilot-agent`'s grant does **not**
include it, so Move reviewers cannot chat. Until the companion change ships (see below),
any reviewer lacking `SendMessage` **writes its findings to a run-dir JSON file**; the
consolidator reads those files and skips live interrogation for them. Once every reviewer
type is `SendMessage`-capable, the file fallback is unused and the model is pure-team.

### Phase-by-phase

```
Phase 0 — Preflight (main session)
   ├─ resolve target repo + branch; ensure clean enough working tree to commit
   ├─ confirm `gh auth status` OK and the repo has a GitHub remote
   └─ create a gitignored run dir for findings files (session tmp, NOT inside the repo)

Phase 1 — Ship
   └─ invoke /commit-push-pr  → branch off main if on main, single commit, push, gh pr create
      capture: PR number, base ref, head ref, head sha, repo owner/name, changed-file list

Phase 2 — Simplify
   ├─ invoke /simplify        → edits working tree (quality only; no bug hunting)
   └─ if /simplify changed files: commit ("simplify") + push  (second commit on the branch)
      (no-op commit skipped if /simplify made no changes)

Phase 3 — Team review
   main session:
     ├─ classify the diff: Move files (.move) → sui-pilot-agent reviewers;
     │  all other files → generic (claude/general-purpose) reviewers; mixed repos get both
     ├─ choose reviewer dimensions, scaled to diff size (see Reviewers below)
     ├─ TeamCreate, then in ONE turn spawn N reviewers + 1 consolidator into the team,
     │  passing each reviewer its dimension + scope + run-dir path + consolidator name,
     │  and the consolidator the roster + PR coordinates
     ├─ each reviewer: review its dimension against the diff/source, then
     │     • if SendMessage-capable: SendMessage findings to the consolidator
     │     • else: write findings JSON to the run dir
     └─ consolidator:
          ├─ collect all findings (messages + run-dir files)
          ├─ interrogate uncertain / high-severity findings (SendMessage where possible;
          │  re-read source + file otherwise) — re-derive the threat/bug path against code
          ├─ drop false positives; cluster + dedupe; order by severity & reviewer agreement
          ├─ post ONE GitHub PR review via `gh api POST /repos/{owner}/{repo}/pulls/{n}/reviews`
          │     • event: COMMENT
          │     • comments[]: { path, line, side, body } with body containing a
          │       ```suggestion fenced block for each concrete code change
          │     • body: a walkthrough comment explaining every proposed change + rationale
          └─ return a structured summary (findings kept/dropped, suggestion list) to main

Phase 4 — Self-adjudicate (main session)
   ├─ read the consolidator's posted review + its summary
   ├─ for each suggestion, decide ACCEPT or REJECT on the merits:
   │     ACCEPT → apply locally (Edit the file to match the suggestion)
   │     REJECT → note rationale
   ├─ if any accepted: commit ("apply review suggestions") + push  (third commit)
   ├─ reply to each review thread: applied / rejected (+ one-line reason) and resolve it
   └─ `gh pr review <n> --approve` with a summary body  → PR left OPEN, APPROVED, merge-ready
```

Total: one `/lfg` call → a branch with up to three commits (feature, simplify, review-fixes),
a posted+adjudicated PR review, and an approval.

### Reviewers (Phase 3 detail)

"As many subagents as needed" → scale the count to diff size; default dimension set:

- correctness / logic bugs
- security
- performance
- tests & coverage
- docs / comments accuracy
- `CLAUDE.md` & project-convention adherence
- API / type design

Routing:

- **Move files** (`.move`, `Move.toml`) → `sui-pilot:sui-pilot-agent` reviewers (doc-first;
  each runs `/move-code-review` + `/move-code-quality`). Fallback chain for the agent name as
  in `move-pr-review` (`sui-pilot:sui-pilot-agent` → `sui-pilot-agent` → `general-purpose`).
- **Everything else** → generic `claude` / `general-purpose` reviewers.
- **Mixed repos** → both sets, each scoped to its file subset.

The consolidator should be a generic agent type (needs `Bash` for `gh` + `SendMessage` for
interrogation); reviewers are typed per routing above.

## Mechanism decisions (locked)

- **Inline suggestions** must go through `gh api POST /repos/{owner}/{repo}/pulls/{n}/reviews`
  with a `comments[]` array — `gh pr review` alone cannot attach inline suggestions. The
  consolidator (has `Bash`) posts the review.
- **Applying accepted suggestions**: edit files locally → commit → push (third commit),
  rather than GitHub's per-suggestion "commit suggestion" button. Simpler, single-branch,
  CLI-friendly.
- **Commit strategy**: three separate commits (feature via `/commit-push-pr`, `simplify`,
  `apply review suggestions`) so the PR history reads as ship → clean up → address review.
- **Final PR state**: auto-approved (`gh pr review --approve`) but left open — a human still
  performs the merge. (User choice; documented trade-off: the bot reviews its own work, so
  the human merge is the only external gate.)
- **Run dir**: a session-tmp directory (e.g. under `$CLAUDE_JOB_DIR/tmp` when present),
  gitignored, never inside the target repo.

## Companion change (separate deliverable, prerequisite for full Move team-chat)

Add `SendMessage` to the `tools:` list in **`~/workspace/sui-pilot/agents/sui-pilot-agent.md`**
(the workspace source — *not* the marketplace cache under
`~/.claude/plugins/cache/contract-hero/sui-pilot/<hash>/`, which is clobbered on auto-update),
then republish to the contract-hero marketplace. Until this ships, Move reviewers use the
file-drop fallback and `/lfg` still works.

## Top implementation risk

**Peer-to-peer `SendMessage` between *spawned* teammates is unverified.** The tool docs
describe messaging from the orchestrator's perspective; the pure-team model assumes a
reviewer can message a *sibling* consolidator (and vice-versa). Implementation **Phase 0
must be a 2-agent spike** proving peer messaging works end-to-end. If it does not, the
file-drop fallback (already in the design) becomes the primary path and the consolidator
loses only the live-interrogation upgrade — the pipeline still functions.

## Out-of-scope / future

- Per-suggestion "commit suggestion" via GitHub API (we apply locally instead).
- HTML review artifact (the PR review is the artifact).
- Configurable auto-approve vs. leave-unapproved (hardcoded to auto-approve for v1).
- Parameterising reviewer count/dimensions via flags (sensible defaults for v1).

## Success criteria

- `/lfg` on a dirty working tree produces: a branch, an opened PR, a simplify commit (when
  `/simplify` changed anything), a posted PR review with at least the walkthrough comment
  (and inline suggestions when concrete fixes exist), a review-fixes commit (when any
  suggestion is accepted), resolved threads, and an approval — with no manual steps.
- Move-heavy diffs are reviewed by `sui-pilot-agent`; non-Move by generic reviewers.
- Runs to completion today (Move reviewers via file fallback) and uses live team-chat once
  `sui-pilot-agent` gains `SendMessage`.
- False positives are filtered by the consolidator's verification pass before the review is
  posted.
