---
name: lfg
description: |
  One-command "ship + harden + review + adjudicate" pipeline for a pull request.
  Runs four phases from the main session: (1) /commit-push-pr to branch, commit,
  push and open the PR; (2) /simplify then a second commit; (3) a team of
  dimension-specialised reviewer subagents + one consolidator that posts a single
  GitHub PR review with inline ```suggestion blocks and a walkthrough comment;
  (4) the main session accepts/rejects each suggestion, lands accepted ones as a
  third commit, and approves the PR, leaving it merge-ready for a human.

  Use when the user says "/lfg", "lfg", "ship it", "full send this PR", "ship and
  review", or wants the whole commit→PR→clean-up→review→address-review loop done in
  one shot on the current working-tree changes. Domain-aware: Move diffs are
  reviewed by sui-pilot-agent; everything else by generic reviewers.

  Do NOT use for: a deep Move-only audit with no ship step (use move-pr-review),
  a single review comment on an existing PR (use /code-review), or when the user
  only wants to commit without opening/reviewing a PR (use /commit or /commit-push-pr).
---

# /lfg — ship, harden, review, adjudicate

Run the full pipeline from the MAIN session, interactively — teammate startup can take
tens of minutes from headless/background sessions (see `references/spike-results.md`).
Never run /lfg from inside a spawned subagent (nested teammate spawning is restricted).

## Phase 0 — Preflight

You MUST be the main session. (Having the `Agent` tool is NOT proof — spawned teammates
carry it too.) If you were spawned by another session, STOP and tell the user to run
`/lfg` from the top-level session.

1. Confirm a GitHub remote + auth: `gh auth status` and `git remote get-url origin`.
   If either fails, stop and report what's missing.
2. Capture repo coordinates: `OWNER/REPO` from `gh repo view --json owner,name -q '.owner.login+"/"+.name'`.
3. Confirm there are changes to ship: `git status --porcelain`. If empty AND no branch-vs-main
   diff exists, stop — there is nothing to /lfg.
4. Create a gitignored run dir OUTSIDE the repo for findings/payloads:
   `RUN_DIR="${CLAUDE_JOB_DIR:-$TMPDIR}/lfg-$(git rev-parse --short HEAD 2>/dev/null || echo run)"`
   then `mkdir -p "$RUN_DIR"`. Remember this path for Phases 3–4.
5. Note `SKILL_DIR` = the absolute path of this skill's directory (for calling its scripts).

## Phase 1 — Ship (/commit-push-pr)

Invoke the `/commit-push-pr` skill. It branches off `main` if needed, makes one commit,
pushes, and opens the PR. After it completes, capture for later phases:

- `PR_NUMBER`: `gh pr view --json number -q .number`
- `BASE_REF` / `HEAD_REF`: `gh pr view --json baseRefName,headRefName -q '.baseRefName+" "+.headRefName'`
- `HEAD_SHA`: `git rev-parse HEAD`
- changed files vs base: `git diff --name-only "$BASE_REF"...HEAD` (this is the review scope)

If `/commit-push-pr` did not result in an open PR (e.g. push failed), stop and report.

## Phase 2 — Simplify (/simplify + second commit)

1. Invoke the `/simplify` skill. It edits the working tree for reuse/efficiency/clarity
   (quality only — it does NOT hunt bugs; that's Phase 3's job).
2. If `git status --porcelain` is now non-empty, land the cleanup as its own commit:
   ```bash
   git add -A && git commit -m "simplify" && git push
   ```
   If `/simplify` changed nothing, skip the commit (do not create an empty commit).
3. Refresh the changed-file list (it may have grown): `git diff --name-only "$BASE_REF"...HEAD`.

## Phase 3 — Team review

You orchestrate; you do NOT review yourself. All spawning happens here, in the main session.

### 3.1 Classify the diff and choose reviewers
- Split the changed-file list into Move files (`*.move`, `Move.toml`) and the rest.
- Pick dimensions to cover (scale count to diff size; small diff → fewer):
  correctness/bugs, security, performance, tests, docs/comments, CLAUDE.md & conventions,
  API/type design. Drop dimensions with no relevant files (e.g. no tests touched → you may
  still include `tests` to check for MISSING coverage; use judgment).
- Assign each dimension a reviewer:
  - If that dimension's scope is Move files → `subagent_type: sui-pilot:sui-pilot-agent`
    (fallback chain: `sui-pilot:sui-pilot-agent` → `sui-pilot-agent` → `general-purpose`;
    the sui-pilot reviewer additionally runs `/move-code-review` + `/move-code-quality`).
  - Otherwise → `subagent_type: general-purpose`.
- Determine reporting mode per reviewer from its agent type's tools grant alone: an agent
  reports via **Mode A (chat)** if its type grants `SendMessage`; any type without the
  grant falls back to **Mode B (file drop)**.

### 3.2 Spawn the team — parallel `Agent` calls in ONE assistant turn
- There is NO team-setup step — every session has a single implicit team, and spawning an
  agent with a `name` makes it a teammate. Do not pass `team_name` (accepted but ignored;
  history in `references/spike-results.md`).
- In a single turn, dispatch every reviewer + the consolidator as parallel `Agent` calls,
  each with a unique `name` — names are the `SendMessage` addresses and reused names get
  sends refused, so suffix with the PR number (e.g. `rev-security-17`):
  - Reviewers: prompt = `references/reviewer_prompt.md` with `{{...}}` filled
    (DIMENSION, DIMENSION_PREFIX, DIMENSION_GUIDANCE, FILE_LIST scoped to that reviewer,
    PR/repo refs, CONSOLIDATOR_NAME, RUN_DIR, and the chosen reporting mode).
  - Consolidator: `name` = the CONSOLIDATOR_NAME you gave reviewers,
    `subagent_type: general-purpose` (needs Bash + SendMessage), prompt =
    `references/consolidator_prompt.md` with `{{...}}` filled (REVIEWER_NAMES roster,
    LEAD_NAME = `team-lead` (fixed by the harness), RUN_DIR, SKILL_DIR, PR/repo refs).
- Reviewers report (chat or file); the consolidator collects, verifies, and posts the
  PR review.

### 3.3 Receive the consolidator's summary and sanity-check
- The consolidator reports on two channels — its `SendMessage` summary and its plain
  final message; both reach you (see `references/spike-results.md`). Accept whichever
  arrives first and treat them as the same report. Delivery can lag on slow-starting
  teammates: the read-only checks below (steps 1–2) are cheap to run anytime while you
  wait; reserve long waits for step 3 and for declaring a teammate dead.
- If the consolidator stays silent, recover in this order — do NOT block indefinitely:
  1. **Authoritative:** `gh pr view "$PR_NUMBER" --json reviews -q '.reviews | length'`
     ≥ 1 confirms the review posted; trust any review id the consolidator reported.
  2. Read `$RUN_DIR/review-payload.json` to see what it built.
  3. Best-effort only: peek the session team inbox for stuck queued messages (layout in
     `references/spike-results.md`), then nudge via `SendMessage` — it auto-resumes and
     wakes stopped teammates.
- Confirm the review posted with the `gh pr view` check above (skip if step 1 already ran).
- Keep the summary (kept/dropped counts, inline suggestions list, walkthrough-only items)
  — Phase 4 adjudicates from it + the posted review.

## Phase 4 — Self-adjudicate + approve

You now act as the PR author deciding what to take from the review.

1. Read the posted review and the consolidator's summary. For EACH inline suggestion and
   each walkthrough item, decide ACCEPT or REJECT on its merits (correctness + fit with the
   codebase). Be willing to reject low-value or wrong suggestions — explain why.
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
5. Approve, leaving the PR open + merge-ready for a human:
   ```bash
   gh pr review "$PR_NUMBER" --approve --body "lfg pipeline complete: shipped, simplified, reviewed (N kept / M dropped), suggestions adjudicated. Ready for human merge."
   ```
6. Report to the user: the PR URL (the deliverable), the commits made (feature /
   simplify / apply review suggestions), kept-vs-dropped finding counts, what you
   accepted vs rejected and why, and that the PR is approved and awaiting human merge.
