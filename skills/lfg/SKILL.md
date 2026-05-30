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
<!-- filled in Task 6 -->

## Phase 1 — Ship (/commit-push-pr)
<!-- filled in Task 6 -->

## Phase 2 — Simplify (/simplify + second commit)
<!-- filled in Task 6 -->

## Phase 3 — Team review
<!-- filled in Task 7 -->

## Phase 4 — Self-adjudicate + approve
<!-- filled in Task 8 -->
