---
name: reviewer-fan-out
description: |
  Dispatch N reviewer subagents IN PARALLEL in a single assistant turn,
  collect their JSON findings into the standard bundle layout, and record
  every dispatch (including fallback chains) in `_dispatch.json`. This is
  the central fan-out primitive used by ship-reviewed-pr, stepped-pr Phase B,
  and any other multi-agent review orchestrator.

  Use this skill when an orchestrator is ready to actually run the reviewers
  (after routing-resolve + reviewer-prompt-build). The orchestrator must
  ensure `reviewers.json` exists in the bundle and each reviewer's prompt
  has been built.

  Do NOT trigger for ad-hoc agent dispatches — this is the multi-reviewer
  parallel-fan-out step of the review pipeline.
allowed-tools: Bash, Read, Write, Agent
---

# reviewer-fan-out — dispatch N reviewer agents in parallel

Primitive #9 of the review-bundle pipeline. Materializes `<bundle>/reviewers/subagent-<N>.{json,md}` and `_dispatch.json`.

## Critical invariant

**All Agent calls in this step MUST go into a single assistant message.** Splitting them across multiple messages serializes the dispatch and defeats the parallelism. The fan-out's whole value is that reviewers run concurrently and independently.

## Inputs

- `bundle` — context bundle directory
- `reviewers` — path to `reviewers.json` (default `<bundle>/reviewers/reviewers.json`)
- `background` — boolean; pass `run_in_background: true` to each Agent call (recommended for >3 reviewers; mandatory for slow specialists like sui-pilot-agent)

## Outputs (after dispatch returns)

- `<bundle>/reviewers/subagent-<N>.json` — strict-schema findings (each reviewer writes its own)
- `<bundle>/reviewers/subagent-<N>.md` — short prose narrative (each reviewer writes its own)
- `<bundle>/reviewers/_dispatch.json` — orchestrator-written record of what was dispatched, with any fallback notes

## Step-by-step (for the orchestrator)

### 1. Pre-flight

```bash
~/.claude/skills/reviewer-fan-out/scripts/prepare.sh --bundle "$BUNDLE"
```

This script validates:
- `reviewers.json` exists and is a non-empty array
- Each entry has all required fields (`id`, `subagent_type`, `focus_area`, `prompt_template`, `role`)
- A prompt file exists at `<bundle>/reviewers/prompts/subagent-<id>.md` for every entry
- Writes an initial `_dispatch.json` skeleton

### 2. Dispatch (the Agent calls)

For each entry in `reviewers.json`, build an Agent call:

- `description`: short — e.g. `"Reviewer #1 (sui-pilot)"`
- `subagent_type`: the entry's `subagent_type` value
- `prompt`: the body of `<bundle>/reviewers/prompts/subagent-<id>.md`, prefixed with one line: `You are reviewer #<id>. Your bundle is at <bundle>. Write your findings to <bundle>/reviewers/subagent-<id>.json and a short prose narrative to <bundle>/reviewers/subagent-<id>.md. Follow the prompt body below.`
- `run_in_background`: `true` when `--background` is set OR reviewer count > 3

**Make all Agent calls in ONE message.** Multiple `Agent` tool blocks inside a single assistant turn are dispatched concurrently.

### 3. Fallback chain

If the Agent tool returns "unknown subagent_type" for a specialized name:

1. Retry once with the bare name (strip plugin prefix): `sui-pilot:sui-pilot-agent` → `sui-pilot-agent`
2. If still unknown, fall back to `general-purpose` with the SAME prompt body
3. Record the fallback in `_dispatch.json` (`"fallback_reason": "<original-name> not available"`)

### 4. Post-dispatch

After all reviewers return:

```bash
~/.claude/skills/reviewer-fan-out/scripts/finalize.sh --bundle "$BUNDLE"
```

This script:
- Verifies every expected `subagent-<N>.json` exists
- Runs the schema validator: `~/.claude/skills/_review-shared/scripts/validate_schema.sh "$BUNDLE/reviewers"` (with `REVIEWERS=<max-id>`)
- Updates `_dispatch.json` with completion timestamps + any reviewer that failed to write output

## Hard rules

- Do NOT serialize dispatch — all Agent calls in one message.
- Do NOT continue if `prepare.sh` exits non-zero — fix the inputs first.
- Do NOT swallow Agent errors — record them in `_dispatch.json` so the consolidator knows.
- Do NOT modify a reviewer's `subagent-<N>.json` after they write it — that's the consolidator's job.

## Companion primitives (downstream)

- `findings-validate-schema` — sanity check the JSONs (already called by `finalize.sh`)
- `findings-cluster` — cluster findings by (file, line_range, category)
- `findings-verify` — re-derive severity for critical/high; write `_verification_notes.md`
- `findings-render-html` / `findings-render-markdown` — emit final reports
