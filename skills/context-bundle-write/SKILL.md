---
name: context-bundle-write
description: |
  Compose pr-diff-acquire + pr-meta-fetch + claude-md-walk + design-doc-fetch
  + dep-pins-capture into a standard review-bundle directory; then write the
  composed `context.md` briefing that every reviewer agent reads.

  Use this skill when an orchestrator (ship-reviewed-pr, stepped-pr Phase B,
  any custom review flow) needs the full review-bundle layout produced in
  one shot. Also use when the user explicitly invokes "build review bundle",
  "scaffold review context", or "write context.md for review".

  Supports `--anti-bias` to suppress any "leads"/"shortlist" sections,
  which stepped-pr Phase B requires to preserve reviewer independence.

  Do NOT trigger for individual primitive invocations — call the primitive
  directly (e.g. `pr-diff-acquire` alone). This skill is the composition
  layer.
allowed-tools: Bash, Read, Write, Glob, Skill
---

# context-bundle-write — compose the standard review bundle

Primitive #6 of the review-bundle pipeline. Composes primitives #1–5 and writes the briefing `context.md`.

## Inputs

- `target` — same shape as `pr-diff-acquire`: `pr:<N>` | `pr:<URL>` | `branch` | `worktree`
- `out` — output directory (created if missing)
- `--anti-bias` (optional) — when set, the composed `context.md` MUST omit any "leads", "shortlist", or evaluative characterization of changed files. Required by `stepped-pr` Phase B.
- `--force` (optional) — overwrite existing bundle files

## Outputs

A bundle directory matching `_review-shared/references/schemas.md` § 4:

```
<out>/
├── pr.diff
├── pr.meta.json
├── scope_files.txt
├── claude-md-paths.txt
├── dep-pins.json
├── design-docs/{index.md, *.md}
└── context.md
```

The `reviewers/`, `_consolidated.json`, `_verification_notes.md`, `review.{html,md}`, `pr-comment.md` slots stay empty — they're filled by downstream primitives (`reviewer-fan-out`, `findings-cluster`, `findings-render-*`).

## Step-by-step

1. Create `<out>/` and `<out>/design-docs/` and `<out>/reviewers/prompts/`.
2. Run the wrapper script:

   ```bash
   ~/.claude/skills/context-bundle-write/scripts/write.sh \
     --target "$TARGET" \
     --out "$OUT" \
     ${ANTI_BIAS:+--anti-bias}
   ```

   Internally it calls:
   - `~/.claude/skills/pr-diff-acquire/scripts/acquire.sh`
   - `~/.claude/skills/pr-meta-fetch/scripts/fetch.sh`
   - `~/.claude/skills/claude-md-walk/scripts/walk.sh`
   - `~/.claude/skills/dep-pins-capture/scripts/capture.sh`
   - `~/.claude/skills/design-doc-fetch/scripts/extract-refs.sh` (for ref extraction; the actual MCP fetches require Claude — see below)

3. If `design-docs/_refs.json` has entries AND the Linear / Notion MCPs are loaded: invoke the `design-doc-fetch` skill so it performs the MCP fetches and writes per-doc `.md` files. If MCPs unavailable, write `design-docs/index.md` noting that and continue.

4. Build `context.md` using the template in `_review-shared/references/context_md_template.md` (mirrors sections 1–7 + 11–12 of `move-pr-review`'s `context_bundle_template.md`, minus the leads/shortlist when `--anti-bias`).

## context.md sections

Always:
1. **PR / target** — number, title, base/head, head SHA, diff size
2. **Scope — IN** — files to audit (from `scope_files.txt`)
3. **Scope — OUT** — (rarely populated; only if orchestrator passed an out-of-scope list)
4. **Dep pins** — from `dep-pins.json` (one bullet per dep with rev + branch warning + local-clone HEAD)
5. **Repo conventions** — pointer to `claude-md-paths.txt`
6. **Design intent** — pointer to `design-docs/index.md`
7. **Schema + severity rubric** — pointer to `_review-shared/references/schemas.md`
8. **Working directory & prohibitions** — `cwd`, no mutations, no builds/runs/git pushes
9. **Budget** — target minutes per reviewer, target finding count

Conditionally (omitted when `--anti-bias`):
10. **Leads / orchestrator shortlist** — pre-read observations marked "do NOT trust"

## Hard rules

- Do NOT include reviewer findings, plan-mode notes, or evaluative characterization of changed files in `context.md` when `--anti-bias` is set.
- Do NOT skip primitives silently — if a primitive errors, abort and surface the failure.
- Do NOT mutate any state outside `<out>/`.

## Verifying the bundle

After writing, sanity-check:

- `[ -s $OUT/pr.diff ]` (non-empty diff)
- `[ -s $OUT/pr.meta.json ]`
- `[ -f $OUT/scope_files.txt ]` (may be empty for trivial PRs)
- `[ -f $OUT/claude-md-paths.txt ]`
- `[ -f $OUT/dep-pins.json ]`
- `[ -f $OUT/context.md ]`

If `--anti-bias` was set:
- `! grep -i -E '(leads|shortlist|suspicious|risky)' $OUT/context.md` (should return non-zero)

## Companion primitives (downstream)

- `routing-resolve` — reads `scope_files.txt` to recommend reviewer agents
- `reviewer-prompt-build` — builds per-reviewer prompts from the bundle
- `reviewer-fan-out` — dispatches the reviewers
- `findings-cluster` / `findings-verify` / `findings-render-*` — consolidation
