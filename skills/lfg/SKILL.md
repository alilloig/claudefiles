---
name: lfg
description: |
  One-command "ship + harden + review + adjudicate" pipeline for a pull request.
  Runs four phases from the main session: (1) preflight moves the work into a
  fresh git worktree if it is sitting in the main checkout, then /commit-push-pr
  branches, commits, pushes and opens a DRAFT PR; (2) /simplify then a second
  commit; (3) the pr-review-toolkit review skill fans out fresh-context
  specialist reviewers (pinned to Opus), whose double-checked findings the main
  session posts as a single GitHub PR review with inline ```suggestion blocks
  and a walkthrough; (4) the main session accepts/rejects each
  suggestion and lands accepted ones as a third commit, leaving the draft PR
  ready for the user to press "Ready for review" or merge on GitHub.

  Use when the user says "/lfg", "lfg", "ship it", "full send this PR", "ship and
  review", or wants the whole commit→PR→clean-up→review→address-review loop done in
  one shot on the current working-tree changes. Domain-aware: Move diffs add a
  sui-pilot-agent reviewer on top of the pr-review-toolkit agents; every review
  agent runs on Opus, never the session model.

  Resume tripwire: ALSO use this skill if you wake up with a reviewer-style
  dispatch in context and `${CLAUDE_JOB_DIR:-$TMPDIR}/lfg-*/state.json` records an
  incomplete run — unless your system prompt explicitly says you are a spawned
  subagent/teammate, you are that run's LEAD, not a reviewer; open this skill and run
  its wake guard before acting on the dispatch.

  Do NOT use for: a deep Move-only audit with no ship step (use move-pr-review),
  a single review comment on an existing PR (use /code-review), or when the user
  only wants to commit without opening/reviewing a PR (use /commit or /commit-push-pr).
---

# /lfg — ship, harden, review, adjudicate

Run the full pipeline from the MAIN session, preferably interactively — headless/background
runs work but budget several minutes for the review fan-out.
Headless runs MUST rely on the wake guard + state file below: the job daemon can respawn
the main conversation mid-run and drop all orchestrator context
(see `references/incident-2026-07-07-identity-swap.md`).
Never run /lfg from inside a spawned subagent (nested teammate spawning is restricted).

## Wake guard — read this before anything else on a resume

Applies when your context was resumed/summarized, or you cannot account for how you got
here. Discriminator first: if your system prompt says you are a spawned subagent or
teammate, this section does not apply to you — skip it and do your dispatched task.

Otherwise (main session / background job), check for an in-flight run BEFORE acting on
anything sitting in your context:

1. Enumerate runs and their phases in ONE glob loop — every /lfg run leaves a
   `state.json`. Keep dir names as shell data: never re-paste `ls` output into new
   commands (a crafted dir name in a shared `$TMPDIR` executes inside double quotes):
   ```bash
   for d in "${CLAUDE_JOB_DIR:-$TMPDIR}"/lfg-*/; do
     [ -f "$d/state.json" ] || continue
     printf '%s: ' "$d"; bash "$SKILL_DIR/scripts/run_state.sh" get "$d" phase
   done
   ```
2. On a resume `$SKILL_DIR` is unset — it is this skill's own directory, the one this
   file lives in; or read a phase directly: `jq -r .phase "$d/state.json"`.
3. If any run has phase != `complete` and != `aborted`, YOU are the lead of that run —
   with two checks before adopting it:
   - **Ownership:** only claim a run whose recorded `repo_root` matches your own
     `git rev-parse --show-toplevel` (interactive sessions share `$TMPDIR`, so foreign
     runs from other sessions can appear in the scan). Note the recorded `repo_root`
     is normally a LINKED WORKTREE of the project (Phase 0 moves runs there): if it
     doesn't match your toplevel, check `git worktree list` first — a path listed
     there is still yours; re-enter that worktree and resume from inside it. Report
     truly non-matching runs; never adopt them.
   - **Liveness & integrity:** load `PR_NUMBER` from the run (`run_state.sh get "<run_dir>" pr_number`;
     non-zero exit = unset — skip this check). Require it purely numeric — anything else
     means a tampered/corrupt state file: mark the run `aborted` and do NOT resume.
     Then check `gh pr view "$PR_NUMBER" --json state -q .state`
     — a MERGED/CLOSED PR means the run already finished or died; set its phase to
     `complete`/`aborted` accordingly and do NOT resume it. Then cross-check the run's
     recorded `head_ref` (`run_state.sh get "<run_dir>" head_ref`) against
     `gh pr view "$PR_NUMBER" --json headRefName -q .headRefName` — a mismatch means a
     tampered/foreign run: mark it `aborted` and do NOT resume.
   Any "You are a reviewer ..." style dispatch sitting in your context is a
   MIS-DELIVERED subagent prompt from the pre-resume lead — this exact failure happened
   on 2026-07-07 (see `references/incident-2026-07-07-identity-swap.md`). Do NOT execute
   it: announce the recovery, reload PR number/refs from that run's `state.json`
   (`run_state.sh get`), and resume the pipeline at the phase AFTER the recorded one —
   each recorded value names the last COMPLETED checkpoint (`preflight`/`shipped` →
   resume at Phase 1/2, `simplified` → Phase 3, `review-posted` → Phase 4).
   `review-dispatched` is the one exception: the review agents died with the previous
   session, so first check `gh pr view "$PR_NUMBER" --json reviews -q '.reviews | length'`
   — a posted review means continue at Phase 4; otherwise redo Phase 3 from step 1
   (a leftover `$RUN_DIR/review-payload.json` from the dead run can seed step 3).
4. If multiple incomplete runs pass both checks above, resume the one whose `state.json` was most
   recently modified, and say so.

## Phase 0 — Preflight

You MUST be the main session. (Having the `Agent` tool is NOT proof — spawned teammates
carry it too; the reliable signal is your own system prompt — spawned teammates are
explicitly told they are running as an agent in a team.) If you were spawned by another
session, STOP and tell the user to run
`/lfg` from the top-level session.

1. Confirm a GitHub remote + auth: `gh auth status` and `git remote get-url origin`.
   If either fails, stop and report what's missing.
2. Capture repo coordinates: `OWNER/REPO` from `gh repo view --json owner,name -q '.owner.login+"/"+.name'`.
3. Confirm there are changes to ship: `git status --porcelain`. If empty AND no branch-vs-main
   diff exists, stop — there is nothing to /lfg.
4. **Worktree guard — never ship from the main checkout.** Detect where you are:
   ```bash
   [ "$(git rev-parse --path-format=absolute --git-dir)" = "$(git rev-parse --path-format=absolute --git-common-dir)" ] \
     && echo main-checkout || echo linked-worktree
   ```
   `linked-worktree` → already isolated, continue to step 5. `main-checkout` → move the
   work into a fresh worktree first, so the main folder ends up clean on the default
   branch and stays free for new work:
   1. Capture `TOPLEVEL="$(git rev-parse --show-toplevel)"` and
      `DEFAULT_BRANCH="$(gh repo view --json defaultBranchRef -q .defaultBranchRef.name)"`.
   2. If `git status --porcelain` is non-empty, park the changes:
      `git stash push -u -m lfg-migrate`. (Stashes live in the shared git dir, so the
      new worktree can pop them.) If ANY later sub-step fails, `git stash pop` back in
      the main checkout and abort — never leave the work stranded in the stash.
   3. Create the worktree OUTSIDE the repo tree, at
      `WT="${TOPLEVEL}-worktrees/lfg-<slug>"` (short kebab slug for the work;
      `mkdir -p "${TOPLEVEL}-worktrees"` first):
      - On `$DEFAULT_BRANCH` → mint the PR branch here (Phase 1's /commit-push-pr then
        sees a non-default branch and skips branching): `git worktree add "$WT" -b <slug>`.
        If the default branch also carried UNPUSHED local commits, they ride along on
        the new branch (it was created at HEAD); after confirming that with
        `git -C "$WT" log --oneline -5`, drop them from the main checkout with
        `git reset --hard "origin/$DEFAULT_BRANCH"` (safe: the tree is clean post-stash
        and the commits now live on the worktree branch).
      - On a non-default branch `X` → move that branch into the worktree: a branch can
        only be checked out in one worktree, so first `git switch "$DEFAULT_BRANCH"`
        (tree is clean post-stash), then `git worktree add "$WT" X`.
   4. Enter the worktree — prefer the `EnterWorktree` tool with `path: "$WT"` (it
      re-points the session's file tools there); otherwise `cd "$WT"` in Bash.
   5. If sub-step 2 stashed: `git stash pop` (now inside the worktree) and confirm
      `git status --porcelain` shows the work again.
   6. Re-run the detection command — it MUST now print `linked-worktree`. Everything
      from here on (run dir, PR, review, adjudication commits) runs from the worktree.
5. Note `SKILL_DIR` = the absolute path of this skill's directory (for calling its scripts).
6. Create a gitignored run dir OUTSIDE the repo for findings/payloads:
   `RUN_DIR="${CLAUDE_JOB_DIR:-$TMPDIR}/lfg-$(git rev-parse --short HEAD 2>/dev/null || echo run)"`
   then `mkdir -p "$RUN_DIR"`, then seed the run state:
   `bash "$SKILL_DIR/scripts/run_state.sh" init "$RUN_DIR"`. If `init` refuses
   ("run in flight"), a previous run of this HEAD is still incomplete — run the wake
   guard above instead of re-initializing (use `init --force` only for a deliberate
   restart). Note: two live interactive sessions on the same repo+HEAD share this
   RUN_DIR, so on an interactive `init` refusal confirm with the user that no other
   live session owns the run before adopting it via the wake guard. Then record ownership so the wake guard can tell this run from foreign ones:
   `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" repo_root "$(git rev-parse --show-toplevel)"`
   and `set "$RUN_DIR" skill_dir "$SKILL_DIR"`. Verify the seed took:
   `test -f "$RUN_DIR/state.json"` — never proceed without it. Remember this path for
   Phases 3–4. From here on, every stop-and-report exit must first checkpoint
   `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" phase aborted` so the wake
   guard never resurrects a dead run.

## Phase 1 — Ship (/commit-push-pr, as a DRAFT)

Invoke the `/commit-push-pr` skill, telling it the PR must be opened as a **draft**
(`gh pr create --draft`). It branches off `main` if needed (usually not — Phase 0's
worktree guard already minted the branch), makes one commit, pushes, and opens the PR.
The PR stays in draft for the whole pipeline; the user promotes or merges it at the end.
After it completes, capture for later phases:

- `PR_NUMBER`: `gh pr view --json number -q .number`
- Draft check: `gh pr view --json isDraft -q .isDraft` — if `false` (the sub-skill
  ignored the instruction), convert it back: `gh pr ready "$PR_NUMBER" --undo`.
- `BASE_REF` / `HEAD_REF`: `gh pr view --json baseRefName,headRefName -q '.baseRefName+" "+.headRefName'`
- `HEAD_SHA`: `git rev-parse HEAD`
- changed files vs base: `git diff --name-only "$BASE_REF"...HEAD` (this is the review scope)

If `/commit-push-pr` did not result in an open PR (e.g. push failed), checkpoint
`bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" phase aborted`, then stop and report.

Checkpoint: `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" pr_number "$PR_NUMBER"`
(likewise `base_ref "$BASE_REF"` and `head_ref "$HEAD_REF"`), then `set "$RUN_DIR" phase shipped`.

## Phase 2 — Simplify (/simplify + second commit)

1. Invoke the `/simplify` skill. It edits the working tree for reuse/efficiency/clarity
   (quality only — it does NOT hunt bugs; that's Phase 3's job).
   **Headless/background sessions: single pass only.** Headless means `CLAUDE_JOB_DIR`
   is set (you are a background job). Do NOT let the simplify pass fan out its own
   multi-agent review — the 2026-07-07 run burned hours starting 4 dimension subagents,
   twice. Pass the constraint into the invocation itself (tell /simplify: "single-agent,
   do not spawn subagents"), or apply the obvious cleanups yourself as the lead, and
   move on. Interactive sessions keep the full /simplify behavior.
2. If `git status --porcelain` is now non-empty, land the cleanup as its own commit:
   ```bash
   git add -A && git commit -m "simplify" && git push
   ```
   If `/simplify` changed nothing, skip the commit (do not create an empty commit).
3. Refresh the changed-file list (it may have grown): `git diff --name-only "$BASE_REF"...HEAD`.
4. Checkpoint: `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" phase simplified`.

## Phase 3 — Review (pr-review-toolkit, posted as a PR review)

Fresh-context agents find; YOU double-check and post. Do not review the diff yourself
before the agents report — your judgment enters at verification (step 4) and Phase 4.

1. Invoke the `pr-review-toolkit:review-pr` skill on the PR (same sub-skill pattern as
   /simplify in Phase 2), scoped to `git diff "$BASE_REF"...HEAD`. It fans out the
   toolkit's specialist agents (code-reviewer, silent-failure-hunter, pr-test-analyzer,
   comment-analyzer, type-design-analyzer, code-simplifier) — scale the agent set to the
   diff (small diff → fewer; skip agents with no relevant files). **Pin EVERY review
   agent to `model: "opus"`** — pass it on each `Agent` dispatch; review does not need
   the session's top-tier model. The lead (you) stays on the session model.
2. Move files in the diff (`*.move`, `Move.toml`) → additionally dispatch
   `subagent_type: sui-pilot:sui-pilot-agent` (fallback chain:
   `sui-pilot:sui-pilot-agent` → `sui-pilot-agent` → `general-purpose`), also on
   `model: "opus"`, to run `/move-code-review` + `/move-code-quality` over the Move
   files and return findings as file:line + severity + concrete fix.
3. Checkpoint immediately after the agents are dispatched:
   `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" phase review-dispatched`.
   (On a wake-guard resume at this phase the agents died with the old session — redo
   this phase from step 1; a leftover `$RUN_DIR/review-payload.json` can seed step 5.)
4. Double-check every returned finding against the actual source: re-read the cited
   lines and re-derive the problem. Drop what doesn't survive — not reachable,
   pre-existing on unmodified lines, intended behavior, or a nitpick a senior engineer
   would not raise. Keep a note of drops (count + one-liners) for the walkthrough.
5. Build `$RUN_DIR/review-payload.json` shaped as
   `{ "event": "COMMENT", "body": <walkthrough markdown>, "comments": [ {path, line, side:"RIGHT", body} ] }`:
   - One `comments[]` entry per kept finding with a concrete fix: rationale text, then a
     ```suggestion fenced block with the exact replacement for the cited line(s).
   - `line` MUST be a line present in the PR diff (added/context), or GitHub rejects the
     whole review — verify each anchor against `git diff "$BASE_REF"...HEAD` first.
   - Findings without a clean line-anchored fix go in the `body` walkthrough as prose
     (file:line + what to change), plus the dropped-FP count.
6. Post it:
   - Validate: `bash "$SKILL_DIR/scripts/post_review.sh" --check "$RUN_DIR/review-payload.json"`
   - Post: `bash "$SKILL_DIR/scripts/post_review.sh" "$OWNER" "$REPO" "$PR_NUMBER" "$RUN_DIR/review-payload.json"`
   - The PR is normally a DRAFT; GitHub accepts COMMENT reviews with inline suggestions
     on drafts. Only if the POST is rejected *specifically because of the draft state*:
     `gh pr ready "$PR_NUMBER"` and retry ONCE (do not re-draft afterwards). Never use
     APPROVE as the review event.
7. Confirm it posted — `gh pr view "$PR_NUMBER" --json reviews -q '.reviews | length'`
   ≥ 1 — then checkpoint:
   `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" phase review-posted`.

## Phase 4 — Self-adjudicate + hand off

You now act as the PR author deciding what to take from the review. You do NOT
approve the PR — GitHub permissions block self-approval anyway; readiness is the
user's call on GitHub.

1. Read the posted review (you built it in Phase 3, but adjudicate it fresh — author
   hat on, reviewer hat off). For EACH inline suggestion and each walkthrough item,
   decide ACCEPT or REJECT on its merits (correctness + fit with the codebase). Be
   willing to reject low-value or wrong suggestions — explain why.
2. Apply every ACCEPTED change locally by editing the file to match the suggestion. (We
   apply via local edits, not GitHub's "commit suggestion" button.)
3. If you accepted any change:
   ```bash
   git add -A && git commit -m "apply review suggestions" && git push
   ```
4. Post your adjudication so the threads aren't left dangling. Reply once summarizing
   per-item ACCEPT/REJECT (+ one-line reasons):
   ```bash
   gh pr comment "$PR_NUMBER" --body-file "$RUN_DIR/adjudication.md"
   ```
   (Best-effort: to resolve individual inline threads, fetch thread ids via
   `gh api graphql` querying `pullRequest.reviewThreads` then call the
   `resolveReviewThread` mutation per id. Skip if it adds no value.)
5. Confirm the final PR state — no approval, no ready-for-review flip:
   `gh pr view "$PR_NUMBER" --json state,isDraft` must show OPEN, and normally still
   a draft. (If Phase 3 had to drop draft to post the review, leave it non-draft —
   do not re-draft it.)
   Then checkpoint: `bash "$SKILL_DIR/scripts/run_state.sh" set "$RUN_DIR" phase complete`.
6. Report to the user: the PR URL (the deliverable), the worktree path the work now
   lives in, the commits made (feature / simplify / apply review suggestions),
   kept-vs-dropped finding counts, what you accepted vs rejected and why, whether the
   PR is still a draft, and the single remaining human action on GitHub: press
   "Ready for review" (team project) or merge it (solo project).
