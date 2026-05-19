---
name: routing-resolve
description: |
  Given a review-bundle's scope_files.txt and pr.diff, emit reviewers.json —
  an ordered list of `{id, subagent_type, focus_area, prompt_template, role}`
  triples that an orchestrator can feed to reviewer-fan-out. Implements the
  hybrid (per-cluster + dimension-lane) routing model documented at
  `_review-shared/references/routing.md`.

  Use this skill when an orchestrator (ship-reviewed-pr, stepped-pr Phase B,
  any custom flow) needs to decide which reviewer agents to dispatch for a
  given diff. Also use when the user explicitly says "resolve reviewers",
  "pick reviewer agents for this diff", "what should review this PR".

  Do NOT trigger for ad-hoc agent recommendations — this is specifically
  for review-bundle dispatch planning.
allowed-tools: Bash, Read, Write
---

# routing-resolve — pick reviewer agents for a bundle

Primitive #7 of the review-bundle pipeline. Writes `<bundle>/reviewers/reviewers.json`.

## Inputs

- `bundle` — context bundle directory (must contain `scope_files.txt` and `pr.diff`)
- `profile` — one of:
  - `redundancy` (default 3 reviewers, all same prompt → ship-reviewed-pr's model)
  - `dimensional` (one reviewer per focus area; orchestrator passes `--focuses`)
  - `hybrid` (per-cluster primaries + dimension lanes; the default)
- `--reviewer-count N` (default: 3 for redundancy; computed for dimensional/hybrid)
- `--focuses "focus1;focus2;..."` — only used in `dimensional` mode
- `--out <file>` (default `<bundle>/reviewers/reviewers.json`)

## Output

A JSON array. Each entry:

```jsonc
{
  "id":               1,
  "subagent_type":    "sui-pilot:sui-pilot-agent",
  "focus_area":       "general — find issues across all dimensions",
  "prompt_template":  "move-deep",
  "role":             "cluster-primary"   // or "dimension-lane" | "redundancy"
}
```

Subagent_type is the PREFERRED choice; the fan-out primitive handles fallback to bare-name → `general-purpose` if unavailable.

## Step-by-step

1. Read `<bundle>/scope_files.txt`.
2. Classify files into clusters: `move` (any `.move` or `Move.toml`), `ts-js` (any `.ts*` / `.js*`), `docs` (only `.md`), `infra` (`.github/`, `Dockerfile`, `*.yml` in CI dirs), `other`.
3. Sample `<bundle>/pr.diff` for dimension-lane signals:
   - error handling adds: `^\+.*(catch|try|throw|panic|unwrap)\b`
   - new types: `^\+.*(type|interface|struct|enum)\s+[A-Z]`
   - test changes: any file path matching `.test.*`, `__tests__/`, `*_test.move`
   - comment-only: ≥80% of added lines start with `//` or `#`
4. Apply profile rules (see below) → emit reviewers array.
5. Write to `--out`.

## Reference recipe

```bash
~/.claude/skills/routing-resolve/scripts/resolve.sh \
  --bundle "$BUNDLE" \
  --profile "${PROFILE:-hybrid}" \
  --reviewer-count "${COUNT:-3}" \
  --out "$BUNDLE/reviewers/reviewers.json"
```

Script at `scripts/resolve.sh`. For dimensional mode, also pass `--focuses "focus1;focus2;focus3"`.

## Profile rules

### redundancy (3 reviewers, same prompt → agreement is the signal)
- Pick the cluster-primary agent for the largest cluster (Move wins ties; then TS; then general-purpose).
- All N reviewers get the same agent + the `generic-redundancy` prompt template + focus_area = "general".

### dimensional (N reviewers, disjoint focus areas → coverage breadth)
- One reviewer per `--focuses` entry.
- Each reviewer's agent = the primary for the largest cluster (per-reviewer cluster routing is overkill in dimensional mode; the orchestrator handles per-file scope via the focus prompt).
- All use the `dimensional-focus` prompt template.

### hybrid (default — per-cluster primaries + dimension lanes)
- For each non-empty cluster: emit one reviewer with the cluster's primary agent + matching prompt template (`move-deep` for move, `ts-js-focused` for ts-js, `generic-redundancy` for others).
- For each fired dimension signal: emit one additional reviewer with the dimension agent + `dimensional-focus` template + the lane's focus_area.
- Cap at 10 reviewers total to keep dispatch parallelism manageable.

## Mapping table (mirrors `_review-shared/references/routing.md`)

| Cluster / signal | Agent | Template |
|---|---|---|
| `move` cluster | `sui-pilot:sui-pilot-agent` | `move-deep` |
| `ts-js` cluster (≥ 50 lines changed) | `pr-review-toolkit:code-reviewer` | `ts-js-focused` |
| `ts-js` cluster (< 50 lines changed) | `feature-dev:code-reviewer` | `ts-js-focused` |
| `docs` cluster | `pr-review-toolkit:comment-analyzer` | `dimensional-focus` |
| `infra` cluster (no specialist) | `general-purpose` | `generic-redundancy` |
| `other` cluster | `general-purpose` | `generic-redundancy` |
| error-handling signal | `pr-review-toolkit:silent-failure-hunter` | `dimensional-focus` |
| new-type signal | `pr-review-toolkit:type-design-analyzer` | `dimensional-focus` |
| test-change signal | `pr-review-toolkit:pr-test-analyzer` | `dimensional-focus` |
| comment-only signal | `pr-review-toolkit:comment-analyzer` | `dimensional-focus` |

## Hard rules

- Do NOT dispatch agents — this skill only emits the JSON plan. `reviewer-fan-out` does dispatch.
- Do NOT check whether agents are installed/enabled — that's a dispatch-time concern; routing emits the preference, not the available set.
- Do NOT cap reviewer count below 1 — even empty diffs get a 1-reviewer general-purpose plan (so the rest of the pipeline runs).
