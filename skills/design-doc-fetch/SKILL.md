---
name: design-doc-fetch
description: |
  Detect Linear ticket IDs, Linear URLs, and Notion URLs in a PR's title /
  body / branch name; fetch them via the corresponding MCP tools when
  available; write each to a distilled markdown file under `design-docs/`.
  Silent no-op if no refs are found OR the MCPs aren't loaded.

  Use this skill when an orchestrator or user invokes the design-doc fetch
  step of the review pipeline ("fetch design docs", "pull Linear ticket",
  "enrich review with linked docs").

  Do NOT trigger for general Linear / Notion questions — use the MCP tools
  directly for those. This skill is specifically for review-bundle
  enrichment.
allowed-tools: Bash, Read, Write, mcp__claude_ai_Linear__get_issue, mcp__claude_ai_Notion__notion-fetch, WebFetch
---

# design-doc-fetch — enrich review bundle with linked design docs

Primitive #4 of the review-bundle pipeline. Writes `<out>/design-docs/*.md` and `<out>/design-docs/index.md`.

This skill is intentionally hybrid — a shell helper extracts refs, then Claude (via the MCP tools listed in `allowed-tools`) fetches the actual content. The MCPs may not be loaded; in that case, the skill writes an empty index and exits 0.

## Inputs

- `meta` — path to `pr.meta.json` (produced by `pr-meta-fetch`)
- `out` — output directory (a `design-docs/` subdir will be created)

## Step-by-step

1. Run the ref extractor to enumerate references:

   ```bash
   ~/.claude/skills/design-doc-fetch/scripts/extract-refs.sh \
     --meta "$OUT/pr.meta.json" \
     --out "$OUT/design-docs/_refs.json"
   ```

   Output is a JSON array: `[{"kind": "linear", "id": "COMG-123"}, {"kind": "notion", "url": "..."}]`. If empty, write an `index.md` saying "No referenced design docs" and stop.

2. For each ref in `_refs.json`:
   - `kind: "linear"` — call `mcp__claude_ai_Linear__get_issue` with the identifier. If unavailable, skip with a note.
   - `kind: "notion"` — call `mcp__claude_ai_Notion__notion-fetch` with the URL. If unavailable, attempt `WebFetch` as a degraded fallback (will fail for private pages).
   - Distill to ≤ 60 lines focused on: invariants, intended boundaries, threat model, design decisions.
   - Write to `<out>/design-docs/<kind>-<safe-id>.md` with a small frontmatter (`source: <url>`).

3. Write `<out>/design-docs/index.md` listing every file produced + source URLs.

## Hard rules

- Do NOT invent design intent if a doc is unavailable — just note it as unavailable.
- Do NOT include evaluative language in distillations ("this design is risky"). The bundle is descriptive.
- Do NOT fetch arbitrary URLs from PR body — only Linear / Notion (or another whitelist).

## Failure modes

- MCPs not loaded → write `index.md` noting "Linear/Notion MCP unavailable; manual fetch needed" and continue.
- Linear ID present but issue not accessible → note in index and continue.
- No refs found → empty `index.md` with "No referenced design docs"; exit 0.

## Companion primitives

- `pr-meta-fetch` — produces the `pr.meta.json` this skill reads.
- `context-bundle-write` — references `design-docs/index.md` in the composed `context.md`.
