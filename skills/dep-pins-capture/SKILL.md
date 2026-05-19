---
name: dep-pins-capture
description: |
  For each git-tracked dependency in `Move.toml` (and optionally `Cargo.toml`,
  `package.json`), capture: pin rev, whether the pin is a branch name (a
  warning if so), and if a local clone exists under `~/workspace/`, its
  HEAD commit. Writes `dep-pins.json` for review-bundle reproducibility.

  Use this skill when an orchestrator or user invokes the dep-pin capture
  step of the review pipeline ("capture dep pins", "snapshot dependencies",
  "write dep-pins.json for review reproducibility").

  Do NOT trigger for general dependency questions — this is specifically
  for review-bundle dep snapshots.
allowed-tools: Bash, Read, Write, Glob
---

# dep-pins-capture — snapshot git dep pins for review reproducibility

Primitive #5 of the review-bundle pipeline. Writes `<out>/dep-pins.json`.

Initial implementation covers `Move.toml` (the most common case in this workspace). Stubs for `Cargo.toml` and `package.json` git deps left for future expansion.

## Inputs

- `repo-root` — absolute repo root (default: `$(git rev-parse --show-toplevel)`)
- `out` — output directory
- `local-clones-root` — where to look for local clones to cross-reference (default: `~/workspace`)

## Output

`dep-pins.json`:

```jsonc
{
  "captured_at": "2026-05-18T11:20:00Z",
  "deps": [
    {
      "manifest": "Move.toml",
      "name": "Sui",
      "rev": "framework/testnet-v1.45.0",
      "is_branch": true,                          // ⚠️ flag for reviewers
      "git_url": "https://github.com/MystenLabs/sui.git",
      "local_clone_path": "/Users/alilloig/workspace/sui",
      "local_head": "f1a2b3c4...",
      "local_head_subject": "chore: bump testnet"
    },
    ...
  ]
}
```

## Behavior

1. Find every `Move.toml` under `repo-root` (typically one, but multi-package repos may have several).
2. Parse each `[dependencies]` block (and `[dev-dependencies]`).
3. For each dep with a `git = "..."`, `rev = "..."` (or `branch = "..."` / `subdir = "..."`):
   - Capture the rev value.
   - Detect if `rev` looks like a branch (anything containing `/` or `-v` or alphabetic chars beyond a hex SHA prefix is a branch hint).
   - Check `<local-clones-root>/<name-lowercased>/` for a clone; if present, `git -C <path> rev-parse HEAD`.
4. Emit JSON.

If `Move.toml` is absent, write `{"captured_at": "...", "deps": []}` and exit 0.

## Reference recipe

```bash
~/.claude/skills/dep-pins-capture/scripts/capture.sh \
  --repo-root "$(git rev-parse --show-toplevel)" \
  --out "$OUT"
```

Script at `scripts/capture.sh`.

## Hard rules

- Do NOT mutate any local clone (no `git fetch`, no `git checkout`).
- Do NOT include sensitive metadata (private SSH URLs are fine; tokens are not).
- Branch-pin flag (`is_branch: true`) is informational, not a failure.
