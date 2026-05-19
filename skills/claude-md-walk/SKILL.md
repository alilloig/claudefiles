---
name: claude-md-walk
description: |
  Walk every CLAUDE.md file between the repo root and each changed file's
  directory; emit a deduped, root→leaf-ordered list to `claude-md-paths.txt`.
  Primitive used by review orchestrators so reviewers know which repo
  conventions to honor.

  Use this skill when an orchestrator or user invokes the CLAUDE.md
  enumeration step of the review pipeline ("walk CLAUDE.md files",
  "enumerate CLAUDE.md", "collect repo conventions for review").

  Do NOT trigger for "show me the CLAUDE.md" or general CLAUDE.md questions
  — those use `Read` directly.
allowed-tools: Bash, Read, Write, Glob
---

# claude-md-walk — enumerate ancestor CLAUDE.md files

Primitive #3 of the review-bundle pipeline. Writes `<out>/claude-md-paths.txt`.

## Inputs

- `files` — path to `scope_files.txt` (produced by `pr-meta-fetch`)
- `repo-root` — absolute path to the repo root (defaults to `$(git rev-parse --show-toplevel)`)
- `out` — output directory

## Behavior

For each file in `scope_files.txt`:
1. Start in the file's directory.
2. Walk up to `repo-root` collecting any `CLAUDE.md` encountered.
3. Always include the repo-root CLAUDE.md if present.

Dedupe and sort root → leaf (longest path last so reviewers reading top-down see broadest conventions first, then narrower local overrides).

## Reference recipe

```bash
~/.claude/skills/claude-md-walk/scripts/walk.sh \
  --files "$OUT/scope_files.txt" \
  --repo-root "$(git rev-parse --show-toplevel)" \
  --out "$OUT"
```

Script at `scripts/walk.sh`.

## Output format

`claude-md-paths.txt` is one absolute path per line, deduped, ordered root → leaf.

## Hard rules

- Do NOT read the CLAUDE.md contents — only list paths. (Reviewers read them.)
- Do NOT walk outside the repo root.
- If `scope_files.txt` is empty or missing, write an empty `claude-md-paths.txt` and exit 0.
