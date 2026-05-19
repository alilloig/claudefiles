---
name: pr-meta-fetch
description: |
  Fetch PR metadata as JSON (`files`, `headRefOid`, `baseRefName`,
  `headRefName`, `title`, `body`, `additions`, `deletions`, `commits`,
  `number`) and write to `pr.meta.json`. For non-PR targets (branch /
  worktree), synthesize a comparable JSON from `git` so downstream
  consumers don't need to special-case.

  Use this skill when an orchestrator or user invokes the metadata-fetch
  step of the review-bundle pipeline ("fetch pr meta", "write pr.meta.json",
  "get PR JSON metadata", etc.).

  Do NOT trigger for ad-hoc questions about a PR's state — use `gh pr view`
  directly for those.
allowed-tools: Bash, Read, Write
---

# pr-meta-fetch — write pr.meta.json

Primitive #2 of the review-bundle pipeline. Writes `<out>/pr.meta.json` and `<out>/scope_files.txt`.

## Inputs

- `target` — same shape as `pr-diff-acquire`:
  - `pr:<N>` / `pr:<URL>` — uses `gh pr view --json …`
  - `branch` / `worktree` — synthesizes a comparable JSON via `git` commands
- `out` — output directory

## Outputs

- `<out>/pr.meta.json` — `{number, title, body, headRefName, baseRefName, headRefOid, files: [{path,additions,deletions}], additions, deletions, commits: [...] }`. For non-PR targets, `number` is `null` and `title`/`body` are best-effort (last commit subject / empty).
- `<out>/scope_files.txt` — newline-delimited file paths (deduped, repo-relative, no leading `./`).

## Reference recipe

```bash
mkdir -p "$OUT"
~/.claude/skills/pr-meta-fetch/scripts/fetch.sh --target "$TARGET" --out "$OUT"
```

Script at `scripts/fetch.sh`.

## Hard rules

- Do NOT make mutating `gh` calls.
- Do NOT include vendored / generated files filter — that's the orchestrator's job if needed (this primitive emits raw scope).

## Companion primitives

- `pr-diff-acquire` — sibling primitive (raw diff).
- `claude-md-walk` — consumes `scope_files.txt` to enumerate CLAUDE.md ancestors.
