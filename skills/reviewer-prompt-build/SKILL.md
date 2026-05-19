---
name: reviewer-prompt-build
description: |
  Build the per-reviewer prompt body from a template + bundle metadata.
  Substitutes placeholders ({REVIEWER_ID}, {BUNDLE_PATH}, {REVIEWER_COUNT},
  {FOCUS_AREA}, etc.) and writes `reviewers/prompts/subagent-<N>.md`.
  Templates live at `_review-shared/references/reviewer_prompts/`.

  Use this skill when an orchestrator needs to materialize the prompt text
  that each reviewer agent will receive. Typically invoked once per entry
  in `reviewers.json` (the output of routing-resolve).

  Do NOT trigger for ad-hoc prompt-writing — this is specifically the
  templated build step of the review-bundle pipeline.
allowed-tools: Bash, Read, Write
---

# reviewer-prompt-build — materialize a reviewer prompt from template

Primitive #8 of the review-bundle pipeline. Writes `<bundle>/reviewers/prompts/subagent-<N>.md`.

## Inputs

- `bundle` — context bundle directory
- `reviewer-id` — 1-based integer (used in prompt + filename)
- `template` — one of `generic-redundancy`, `dimensional-focus`, `move-deep`, `ts-js-focused`
- `focus` — optional; required for `dimensional-focus` template; ignored otherwise
- `reviewer-count` — total reviewers in the fan-out (so the prompt can say "you are N of M")
- `pr-number` — optional; defaults to value from `<bundle>/pr.meta.json` or `(branch)`/`(worktree)`

## Output

`<bundle>/reviewers/prompts/subagent-<N>.md` — fully substituted reviewer prompt ready to feed to the Agent tool.

## Step-by-step

```bash
~/.claude/skills/reviewer-prompt-build/scripts/build.sh \
  --bundle "$BUNDLE" \
  --reviewer-id 1 \
  --template move-deep \
  --reviewer-count 3 \
  ${FOCUS:+--focus "$FOCUS"}
```

Script at `scripts/build.sh`.

## Placeholders supported

| Placeholder | Source |
|---|---|
| `{REVIEWER_ID}` | `--reviewer-id` |
| `{REVIEWER_COUNT}` | `--reviewer-count` |
| `{BUNDLE_PATH}` | `--bundle` (absolute path) |
| `{PR_NUMBER}` | `pr.meta.json:.number`, fallback `(branch)` or `(worktree)` |
| `{FOCUS_AREA}` | `--focus` |
| `{SCHEMA_PATH}` | `~/.claude/skills/_review-shared/references/schemas.md` (resolved absolute) |

## Hard rules

- Do NOT modify the template files in-place. Read them; substitute into a copy.
- Do NOT fail if `--focus` is missing for non-dimensional templates — silently ignore.
- DO fail if `--focus` is missing for `dimensional-focus` template (it's load-bearing).
