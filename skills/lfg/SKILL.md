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

Run the full pipeline from the MAIN session. Never run /lfg from inside a spawned
subagent: spawning the review team requires the `Agent` tool, which subagents lack.

## Phase 0 — Preflight

You MUST be the main session (you have the `Agent` tool). If you are a spawned subagent,
STOP and tell the user to run `/lfg` from the top-level session.

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
<!-- filled in Task 7 -->

## Phase 4 — Self-adjudicate + approve
<!-- filled in Task 8 -->
