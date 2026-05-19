---
description: Co-review a PR file-by-file with the user. User drives questioning per file; supplement findings only after each file. Optionally scaffold an unbiased multi-agent swarm review at the end.
argument-hint: [linear-ticket.md] [review.md path | PR# | URL] (both optional)
---

Co-review a PR/branch with the user. The user drives the review pace and questions; you are the meaningful assistant who supplements after each file. Do **not** edit code, run tests, or push during this skill — review-only.

## Input parsing

Parse `$ARGUMENTS`. Any combination of these may appear; auto-detect by shape:

- **Linear ticket markdown** — a local `.md` path. Identify by content, not name: it should look like a pasted Linear ticket (Description, Acceptance Criteria, Metadata with `Identifier: COMG-…`, Linear URL, …). If a `.md` is passed but content doesn't match this, treat it as a review/findings setup doc instead.
- **PR scope** — one of: a PR id (e.g. `120`), a PR URL, a local `.md` setup doc, or nothing (= current branch vs `main`). Resolve to a list of changed files via `gh pr view` + `gh pr diff --name-only` for a PR, or `git diff main --name-only` for a branch.

If no Linear ticket is supplied AND you cannot identify the ticket cleanly from the branch name / PR description / setup doc, **stop and ask the user to paste the Linear content into a markdown file and pass the path** before continuing. Do not guess.

## Phase A — File-by-file co-review (user drives)

1. Read the Linear ticket markdown (if any) and any setup doc end-to-end before doing anything else.
2. Compute the changed file list and present it **ordered for maximum understanding** of the PR — highest-level files first (entry points, public APIs, top-level types, schema/migrations) down to internals (helpers, tests). Briefly justify the ordering in one line.
3. While doing the above, silently form your own findings. **Do not reveal them yet** — that would bias the user.
4. The user reads each file in order and questions you on it. Answer accurately, concisely, and only what was asked. They may follow a reference into a different file — that's fine, answer it, but the current file does not change until they say so.
5. When the user signals they're done with the current file, do a more careful pass yourself and surface:
   - Things they missed (correctness, security, edge cases, contract violations).
   - Places where their recommendation is suboptimal — say why.
   - Cross-file implications worth flagging now rather than later.
6. Continue to the next file. Repeat 4–5 until every file in the list has been reviewed.

## Phase B — Optional multi-agent swarm pass

After Phase A is complete, ask the user whether to follow up with a multi-agent swarm review. If yes, offer three modes:

- **(a) Plan first** — enter plan mode so the user can refine focus areas and orchestrator count before execution.
- **(b) Execute now** — you take the Leader Consolidator role and run the swarm in this session.
- **(c) Scaffold only** — write the task artifacts and stop; the user will run the swarm later.

In all three modes, set up a task directory at `.claude/tasks/co_review_<slug>/` (slug from the Linear ticket id or PR number) containing:

- `spec.md` — Linear ticket content (verbatim from the passed markdown) + branch/PR identifier + reference doc pointers (`docs/*`, design doc URLs, etc.).
- `prompt.md` — the orchestration prompt below, tailored to this PR's surface area.
- `pr.diff` and `pr.meta.json` — produced via `gh pr diff … > pr.diff` and `gh pr view … --json … > pr.meta.json` (or `git diff main` equivalents).
- `context.md` — a self-contained, **descriptive** briefing every orchestrator can work from with no prior repo memory. See anti-bias rules below.
- `reviews/` — empty dir for orchestrator outputs.

### Anti-bias rules (CRITICAL — independence is what makes consolidation worth doing)

The whole point of the swarm is that N orchestrators reach conclusions independently and Phase 3 surfaces convergence. If the Leader's framing channels them toward the same answer, you've built an expensive echo chamber. Therefore:

1. **`context.md` is descriptive, not evaluative.** Copy primary sources verbatim — Linear ticket, design-doc paragraphs, CLAUDE.md rules. List changed files with a **neutral one-line purpose** (what the file _is_, not how well it does its job). Identify entrypoints by `file:line` only — never label them as "the cap-check function" or "the suspicious path"; that pre-judges. If you need to point at code, quote it, do not characterize it.
2. **Phase A co-review findings stay out of `context.md`, out of `prompt.md`, and out of every orchestrator brief.** No exceptions. Those findings live in conversation/memory and are compared against the swarm's output _after_ Phase 3. The orchestrators must rediscover independently — that's what gives Phase 3's convergence/divergence signal any meaning.
3. **No "what to look for" hints, no "critical context" warnings, no "make sure to check X".** Past task prompts that did this (e.g. `review_comg_171/prompt.md`) were single-agent reviews of tiny PRs — a different mode. For the swarm, channeling attention destroys the independence.
4. **Focus areas are questions to investigate, not answers to verify.** Phrase each as a scope ("Walk every AC and locate implementing code + test; flag any AC missing, partial, or UI-only"), not a hypothesis ("AC#3 looks UI-only — confirm").
5. **Identical baseline.** Every orchestrator receives the same `context.md`, `pr.diff`, `spec.md`. No orchestrator-specific hints or "you should pay attention to…" lines. The only thing that differs per orchestrator is its focus area definition.
6. **No severity or verdict priors.** Don't tell orchestrators "this is a risky PR" or "should be straightforward". Let them decide.
7. **If a piece of context is load-bearing (e.g. a clarification from a PR comment thread that changed an AC), include it as a verbatim quote attributed to the source — not as a Leader summary.** Summaries smuggle in framing; quotes don't.

### Swarm orchestration template (Leader Consolidator → parallel orchestrators → consolidation)

The `prompt.md` you generate should run in three phases:

**Phase 1 — Exploration (Leader, sequential).** Produce `pr.diff`, `pr.meta.json`, and `context.md` under the anti-bias rules above. Do not begin Phase 2 until `context.md` is complete enough that an orchestrator with no repo memory could work from it.

**Phase 2 — Parallel independent review.** Spawn N orchestrators (typically 4–8, disjoint focus areas tailored to this PR) in a **single message** with `subagent_type: "general-purpose"`. Each orchestrator:

- Reads `pr.diff`, `context.md`, `spec.md` first.
- Spawns 2–4 subagents in parallel (`subagent_type: "Explore"` for read-only mapping; `general-purpose` for deeper analysis).
- Stays strictly inside its focus area — cross-cutting issues are the Leader's job to merge.
- Writes one report to `reviews/<focus-slug>.md` using this schema:

  ```markdown
  # Review: <Focus Area>

  ## Summary

  ## Findings

  ### [SEVERITY] <Short title>

  - **File**: `path/to/file.ts:LINE`
  - **Category**: <correctness | security | concurrency | data-integrity | api-contract | testing | observability | code-quality>
  - **Evidence**: <quoted code or observed behavior>
  - **Spec/doc reference**: <AC#, design doc section, repo file:line — REQUIRED for severity ≥ Major>
  - **Suggested fix**:

  ## Spec compliance checklist (if in scope)

  ## Subagent log

  ## Confidence
  ```

  Severity: **Critical** (blocks merge) · **Major** (must fix) · **Minor** (should fix) · **NiceToHave (can defer)** .

**Phase 3 — Consolidation (Leader).** Read all reports and write `FINAL_REVIEW.md`. Rules, in order:

1. Dedup by `(file:line, category)` — keep highest severity, merge evidence. **Note the dedup count** (how many orchestrators independently raised it) — that's signal.
2. Conflict resolution: put disagreements in a "Disputed" subsection with your tie-break and the primary source that decides it.
3. Promote cross-cutting patterns: if ≥3 orchestrators independently flag the same root cause, promote to "Systemic Issues".
4. Demote unsupported claims: Major/Critical without a primary-source citation → Minor or dropped; list demotions in "Excluded findings".
5. One consolidated AC checklist drawn from the strongest evidence per item.

Final structure: Verdict · Spec compliance · Critical · Major · Minor · Systemic issues · Disputed/tie-broken · Strengths · Excluded findings · Per-reviewer source map.

**After Phase 3 — comparison with Phase A .** Diff the swarm's `FINAL_REVIEW.md` against the findings the user and you produced in Phase A. Where they converge: high confidence. Where the swarm caught something Phase A missed: real value-add. Where Phase A caught something the swarm missed: likely needed deeper familiarity than the orchestrators built up. Present this diff to the user — do **not** retroactively edit `FINAL_REVIEW.md` to match Phase A.

### Determinism contract (non-negotiable)

- Each orchestrator stays inside its focus.
- Severity ≥ Major requires a primary-source citation; otherwise demote.
- All file references are `path:line`. "Somewhere in the upload code" is rejected.
- No invented conventions — cite the repo file or doc that establishes the rule.
- Orchestrators are spawned in **one message, in parallel**.
- Each orchestrator spawns ≥2 subagents (or documents in `Subagent log` why a single sweep sufficed).
- No code edits, no `git push`, no test runs, no lint runs at any level.

### Tailoring focus areas

Pick 4–8 disjoint focus areas based on what the PR actually touches. Don't reuse a fixed list. Typical menu to draw from: Spec/AC compliance · domain-specific idioms (Effect-TS, Move 2024, etc.) · security & authorization · concurrency & races · data integrity & migrations · API contract & error UX · testing · observability/ops/rollout · performance · upgrade & backwards compat. Examples of well-scoped past runs live under `.claude/tasks/review_comg_*/prompt.md` — read one for structural reference, but do **not** copy its framing verbatim (it was tailored to a different PR and may carry biases that don't apply).

$ARGUMENTS