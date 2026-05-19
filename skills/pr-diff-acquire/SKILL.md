---
name: pr-diff-acquire
description: |
  Acquire the raw diff for a PR, branch, or working tree and write it to
  `pr.diff` inside a target directory. Primitive used by review orchestrators
  (ship-reviewed-pr, stepped-pr, code-review). Accepts a target spec
  (`pr:<N>`, `pr:<URL>`, `branch`, `worktree`) and an output path.

  Use this skill when an orchestrator or the user explicitly asks to
  "acquire the diff", "fetch the PR diff", "write pr.diff for review",
  or any equivalent invocation of the diff-acquisition step of the review
  pipeline.

  Do NOT trigger for general "show me the diff" questions — those just
  warrant a direct `git diff` / `gh pr diff` call. This skill is for the
  formal review-bundle workflow.
allowed-tools: Bash, Read, Write
---

# pr-diff-acquire — acquire raw diff for review bundle

Primitive #1 of the review-bundle pipeline. Writes `<out>/pr.diff`.

## Inputs

- `target` — one of:
  - `pr:<N>` — PR number in the current repo (e.g. `pr:42`)
  - `pr:<URL>` — full GitHub PR URL
  - `branch` — current branch vs its merge-base with the repo's default branch
  - `worktree` — `git diff HEAD` (uncommitted changes only)
- `out` — output directory (must exist or be creatable)

## Behavior

1. Verify `gh` (when target starts with `pr:`) or `git` is available.
2. Resolve the target → emit the diff to `<out>/pr.diff`.
3. Print a one-line summary (`+<add> / -<del> across <N> files`).

## Reference recipe

The work fits in a shell script; the orchestrator calls it like:

```bash
mkdir -p "$OUT"
~/.claude/skills/pr-diff-acquire/scripts/acquire.sh --target "$TARGET" --out "$OUT"
```

The script is at `scripts/acquire.sh` next to this file.

## Hard rules

- Do NOT mutate any state (no `git fetch`, no `gh` mutating subcommands).
- Do NOT chase unrelated context. Output is exactly `pr.diff`.
- Skip silently if `pr.diff` already exists AND `--force` is not set.

## Companion primitives

- `pr-meta-fetch` — same target → `pr.meta.json` (PR metadata).
- `context-bundle-write` — orchestrates this + 4 other primitives into a full review bundle.
