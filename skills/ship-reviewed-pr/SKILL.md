---
name: ship-reviewed-pr
description: |
  Full PR pipeline — commit current changes, push the branch, open the PR,
  run the code-simplifier, fan out 6 parallel general-purpose reviewers,
  consolidate their findings with source-verified double-checking, post a
  single review comment on the PR, and auto-fix every critical or high
  finding before pushing the cleanup commit.

  Use this skill whenever the user says "ship this", "ship it", "ship a PR",
  "ship a PR for this", "ship the PR", "let's ship a PR", "ship it as a PR",
  "ship it with review", "ship and review", "run the full PR pipeline",
  "deep review and push fixes", "commit + review + ship", or any variant
  that asks for the full commit→review→fix arc handled in one shot. Any
  English sentence combining "ship" with PR/branch/this/it on a feature
  branch is the golden path — including phrases like "ship a PR for this
  before manual testing" or "okay, let's ship a PR". Trigger even if they
  only say "ship" while sitting on a feature branch with unstaged work.

  Do NOT downgrade "ship a PR" to a plain `git commit` + `git push` +
  `gh pr create` sequence. When the user says "ship", they want the full
  multi-reviewer arc — not the bare git operations.

  Skip if: the user is on `main`/`master`, the repo has no remote, or they
  explicitly only want a review without commits (use `/code-review` instead).
allowed-tools: Read, Edit, Write, Bash, Glob, Grep, Agent
---

# Ship a PR with multi-agent review

This skill collapses commit-push-pr → simplify → multi-agent review → fix into a single procedure. Six parallel reviewers do the same general review (no dimension split); the main session double-checks high-severity findings against source before posting one consolidated GitHub comment, then auto-fixes the critical/high items.

The fan-out's value is **agreement**, not coverage: when 4+ of 6 independent reviewers flag the same line, that's signal. Singletons get verified or dropped.

## Pre-flight checks

Refuse to proceed if any of these fail. Surface the specific failure to the user.

1. **Branch** — `git branch --show-current` is not `main`, `master`, or `$(git rev-parse --abbrev-ref origin/HEAD | sed 's|origin/||')`.
2. **Auth** — `gh auth status` exits 0.
3. **Changes** — either the working tree is dirty, or a PR already exists for the current branch.
4. **gitignore** — `.claude-pr-review/` is in `.gitignore` (the parent or any submodule). If missing, append the line and stage it as part of Phase 1's commit.

## Phase 1 — Commit, push, open PR

Mirror `/commit-push-pr` semantics inline. Read `git status`, `git diff HEAD`, and `git log -5 --oneline` first to draft the commit message in the repo's style.

1. **Stage selectively** — `git add` the specific files in the diff. **Do not** use `git add -A` or `git add .` (sweeps in secrets and unrelated work).
2. **Commit** with a HEREDOC body so multi-line messages render correctly:
   ```bash
   git commit -m "$(cat <<'EOF'
   <type>(<scope>): <one-line summary>

   <2-3 line body explaining WHY, not WHAT>

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   ```
3. **Push** — `git push -u origin <branch>` if the branch isn't tracked, otherwise `git push`.
4. **Open or reuse the PR** — first check: `gh pr view --json number 2>/dev/null`. If a number returns, reuse it. Otherwise:
   ```bash
   gh pr create --title "<title under 70 chars>" --body "$(cat <<'EOF'
   ## Summary
   - <1-3 bullets>

   ## Test plan
   - [ ] <bullet>

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   EOF
   )"
   ```
5. **Capture** the PR number into a shell variable for the rest of the skill: `PR=$(gh pr view --json number -q .number)`.

## Phase 2 — Simplify

Dispatch the `code-simplifier` agent (it's an agent, not a slash command — call via the Agent tool with `subagent_type: "code-simplifier"`). The agent reviews recently-modified code for clarity and consistency without altering behavior.

If it produced edits — i.e. `git status` shows changes after the agent returns — stage those specific files, commit with `refactor: simplify recently modified code`, push. If it produced nothing, continue silently.

## Phase 3 — Setup the review workspace

```bash
TS=$(date -u +%Y-%m-%dT%H-%M-%SZ)
WS=".claude-pr-review/$TS"
mkdir -p "$WS/reviewers"
gh pr diff "$PR" > "$WS/pr-diff.patch"
gh pr view "$PR" --json files,headRefOid > "$WS/pr-meta.json"
HEAD_SHA=$(jq -r .headRefOid < "$WS/pr-meta.json")
REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
```

Then enumerate every CLAUDE.md the PR touches. Start at the repo root, then for each unique directory containing a changed file walk up to the repo root collecting any `CLAUDE.md`. Write the deduped paths to `$WS/claude-md-paths.txt`. Reviewers consult these for project-specific conventions.

## Phase 4 — Fan out 6 reviewers in a single message

Make all 6 Agent calls in **one** assistant message so they run in parallel. Use `subagent_type: "general-purpose"` (reviewers are read-only — they don't need write/edit). The prompt to each is identical except for the `K` index. Template:

```
You are reviewer K of 6 doing a parallel general code review of PR #<PR>
in <REPO> (head sha <HEAD_SHA>).

Inputs:
- PR diff: .claude-pr-review/<TS>/pr-diff.patch
- PR meta: .claude-pr-review/<TS>/pr-meta.json
- CLAUDE.md paths to consult: .claude-pr-review/<TS>/claude-md-paths.txt
- You may read any file in the repo to understand context.

Find issues across ALL of these dimensions — you do NOT specialize:
correctness, design, error-handling, simplicity, tests-vs-impl,
security, performance, documentation, build.

For each finding, append a JSON object with these EXACT fields to your
output array (no extra fields, no missing fields):

{
  "id": "R<K>-<NNN>",          // e.g. "R3-007"
  "title": "<= 80 chars",
  "severity": "critical|high|medium|low|info",
  "category": "correctness|design|error-handling|simplicity|tests-vs-impl|security|performance|documentation|build",
  "file": "<path relative to repo root>",
  "line_range": "<start>-<end>",
  "description": "<what is wrong, in your own words>",
  "impact": "<what breaks for the user / system if this ships>",
  "recommendation": "<concrete fix>",
  "evidence": "<verbatim 1-5 line code quote from the PR diff>",
  "confidence": "high|medium|low"
}

Severity rubric (use it strictly):
- critical = exploitable security flaw, data loss, or contract violation
  that ships if merged. You MUST be able to describe the adversary path
  concretely.
- high = bug or design flaw the user will hit in normal use.
- medium = bug or design flaw under unusual but plausible conditions.
- low = stylistic, edge case, or minor robustness concern.
- info = observation or future-proofing note, no action implied.

Write your output as TWO files:
- .claude-pr-review/<TS>/reviewers/subagent-<K>.json — the JSON array
- .claude-pr-review/<TS>/reviewers/subagent-<K>.md — a brief narrative
  (executive summary + your top 3 concerns in prose, for the
  consolidator and the human reader)

Hard rules:
- Read-only. Do NOT modify any code.
- Do NOT call `gh pr comment` — the orchestrator posts the consolidated
  review.
- Skip pre-existing issues (lines outside the PR diff).
- Skip nitpicks a senior engineer wouldn't call out.
- Skip issues a typechecker/linter would catch — CI handles those.
- If you find nothing material, write an empty array `[]` and a
  one-paragraph narrative saying so. That's a valid result.
```

## Phase 5 — Consolidate (main session)

Read all six `subagent-K.json` files. Then:

1. **Cluster** — group findings whose `(file, line_range)` overlap (any line in common). Track per-cluster: `agreement_count` (number of distinct reviewers contributing), `max_severity`, `min_severity`, `categories` (set), and the underlying findings list.
2. **Verification pass** — for any cluster matching ANY of:
   - `max_severity ∈ {critical, high}`, OR
   - `agreement_count == 1 AND max_severity in {critical, high}` (singleton-high), OR
   - cluster contains ≥ 3 distinct categories at overlapping ranges (likely a mega-cluster — split it back into separate clusters by re-reading the raw findings).

   For each: open the cited file at the cited range ±30 lines. Trace one hop up (who calls this code) and one hop down (what does it call) to validate the impact claim. Re-derive severity from the rubric. Adjudicate as **confirm**, **downgrade**, **reject**, or **split**. For confirmed `critical`, you MUST be able to describe the adversary path concretely — if you can't, the severity is wrong.

3. **Drop noise** — singleton `low` and `info` findings are dropped unless they read as obvious bugs. Multiple reviewers flagging "needs more tests" collapse into one entry in the Test & coverage section, not three separate `high`s.

4. **Write `$WS/review.md`** using this template:

   ```markdown
   ### Code review

   <2-3 sentence executive summary. Pass/fail at a glance. Top 1-3 risks.>

   **Severity counts**

   | Severity | Count |
   |---|---|
   | critical | 0 |
   | high     | 1 |
   | medium   | 3 |
   | low      | 4 |
   | info     | 2 |

   #### Critical
   (none)

   #### High
   1. <brief description>. **File:** `path:line` (<reviewer agreement>/6).
      *Verification:* <one-line adjudication note>
      <full-sha file link — see format below>

   #### Medium
   ...

   #### Test & coverage
   - <one bullet, if reviewers flagged gaps>

   #### Methodology
   - 6 reviewers dispatched in parallel.
   - Coverage: <files × reviewers; flag rate>.
   - Clusters before split: M; after split: K.
   - Verification: <count of critical/high/disputed clusters re-read against source>.
   - Missing reviewers (if any): <K> failed to produce JSON; counted toward methodology only.

   🤖 Generated with [Claude Code](https://claude.com/claude-code)
   ```

   File link format (full sha required so the markdown previews correctly):
   `https://github.com/<REPO>/blob/<HEAD_SHA>/<path>#L<start>-L<end>`
   Always provide ≥1 line of context above and below the cited line.

## Phase 6 — Post one consolidated comment

```bash
gh pr comment "$PR" --body-file "$WS/review.md"
```

If the same skill invocation already posted a comment in a prior phase (it shouldn't, but defensively), skip. **Never post six comments** — only the consolidated one.

## Phase 7 — Auto-fix critical and high

For every cluster the verification pass left at `critical` or `high`:

1. **Read** the cited file at the cited range.
2. **Edit** the smallest possible region to address the finding. Do not refactor surrounding code, do not rename, do not add abstractions — minimal targeted change only. If a fix would require restructuring beyond the immediate region, leave it for the user instead of guessing.
3. After all fixes are applied, run cheap validators if they exist:
   - If `package.json` has a `typecheck` script: `pnpm typecheck` (or `npm run typecheck` if no `pnpm-lock.yaml`).
   - If the repo is a Move package: `move_diagnostics` MCP tool when available.
   - **Skip test runs** unless the user has signaled the suite is fast — keep this loop responsive.
4. If a validator fails, identify which finding's fix introduced the regression, revert that one Edit, and continue with the rest. Do not push broken code.
5. **Single commit + push**:
   ```bash
   git add <only the files just edited>
   git commit -m "$(cat <<'EOF'
   fix: address critical/high review findings

   <one bullet per fixed finding, referencing the R<K>-<NNN> id>

   Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
   EOF
   )"
   git push
   ```
6. **Final report** to the user: `Auto-fixed N critical+high. M medium / K low remain — see PR comment.`

If there were zero critical+high findings, skip Phase 7 entirely and report `No auto-fix needed. M medium / K low surfaced for your review — see PR comment.`

## Edge cases

- **PR already exists** — Phase 1 skips `gh pr create`, reuses the existing number.
- **Simplifier produces nothing** — Phase 2 commits nothing, no extra push.
- **A reviewer fails to write its JSON** — log the missing index in the methodology section; don't fail the whole skill.
- **Auto-fix introduces a typecheck regression** — revert just that fix and continue.
- **Submodule changes** — only commit submodule pin bumps if the user staged them. Don't touch other submodules.

## Don't

- **Don't auto-fix medium/low/info.** Too much surface for false positives. The user reads the comment and decides.
- **Don't `git add -A` or `git add .`** at any phase. Stage only the specific files the skill itself produced or that were already staged before invocation.
- **Don't bypass hooks** with `--no-verify`. If a pre-commit hook fails, surface the failure and stop — that's the hook doing its job.
- **Don't post six PR comments.** Only the consolidated one.
- **Don't recurse.** If Phase 7 ends up changing the diff substantially, don't re-run reviewers in the same invocation — the user can re-trigger the skill if they want a second pass.
- **Don't run long test suites** in Phase 7. Typecheck only, by default.

## Why this design

- **No dimension split** — the user opted for redundancy over depth-per-lens. Six reviewers doing the same job means agreement is the primary signal; the verification step picks up the slack on confidence.
- **Source-verified double-check** — copied from `code-forge-v2/agents/consolidator.md`. It's the part that distinguishes "real bug" from "reviewer saw it wrong" and is the most expensive thing to omit.
- **Auto-fix only critical+high** — these have been re-derived from rubric and verified against source. Lower severities haven't been verified, so auto-fixing them risks code churn for issues the user wouldn't have flagged.
