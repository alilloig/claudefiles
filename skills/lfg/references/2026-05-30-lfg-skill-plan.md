# `/lfg` Skill Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `/lfg` skill that runs a one-command pipeline — commit+push+PR, simplify, multi-agent team review that posts a GitHub PR review, then main-session self-adjudication + auto-approve.

**Architecture:** A skill at `~/.claude/skills/lfg/SKILL.md` orchestrated entirely from the main session. The main session spawns a team of dimension reviewers + one consolidator; reviewers report findings via `SendMessage` (or a file-drop fallback for agent types without that grant, e.g. today's `sui-pilot-agent`); the consolidator verifies findings against source and posts one PR review with inline `suggestion` blocks; the main session then accepts/rejects suggestions, lands accepted ones as a commit, and approves. Two small executable helpers (a findings-JSON validator and a `gh api` review-poster) make the data plane reliable.

**Tech Stack:** Markdown skill authoring (SKILL.md + reference prompt files), Node.js for the findings validator (mirrors `move-pr-review/scripts/`), Bash + `gh` CLI (`gh api` for inline-suggestion reviews), the Agent/TeamCreate/SendMessage team tooling.

**Spec:** `docs/superpowers/specs/2026-05-30-lfg-skill-design.md`

**Working location:** All paths below are relative to the repo root `~/.claude` (= `/Users/alilloig/workspace/dotfiles/.claude`), currently checked out in worktree branch `worktree-lfg-skill`.

---

## File Structure

| File | Responsibility |
|---|---|
| `skills/lfg/SKILL.md` | The skill: frontmatter + the 4-phase orchestration the main session follows. |
| `skills/lfg/references/reviewer_prompt.md` | The prompt template each reviewer subagent runs (dimension review + dual-mode reporting + findings schema). |
| `skills/lfg/references/consolidator_prompt.md` | The prompt the consolidator subagent runs (collect → interrogate → verify → post PR review → return summary). |
| `skills/lfg/references/findings.schema.json` | JSON Schema for a reviewer's findings file (file-drop mode). |
| `skills/lfg/scripts/validate_findings.mjs` | Node validator: checks a findings file against the schema; exit 0/1. |
| `skills/lfg/scripts/post_review.sh` | Posts a PR review with inline suggestions via `gh api`; reads a payload JSON. |
| `skills/lfg/references/spike-results.md` | Recorded go/no-go outcome of the peer-`SendMessage` spike (Task 0). |
| `~/workspace/sui-pilot/agents/sui-pilot-agent.md` | **Separate repo.** Companion edit: add `SendMessage` to the `tools:` grant. |

---

## Task 0: Spike — verify peer-to-peer `SendMessage` between spawned teammates

**Why first:** The entire team model assumes a *spawned* reviewer can `SendMessage` a *sibling* consolidator. The docs only describe orchestrator→agent messaging. Prove it before building on it. The file-drop fallback is the safety net if it fails.

**Files:**
- Create: `skills/lfg/references/spike-results.md`

- [ ] **Step 1: Run the spike dispatch**

In the current (main) session, run this exact orchestration in a SINGLE assistant turn (two `Agent` tool calls, same `team_name`):

- Agent A — `name: "lfg-spike-consolidator"`, `team_name: "lfg-spike"`, `subagent_type: general-purpose`, prompt:
  > You are the consolidator in team "lfg-spike". Wait to receive a message from teammate "lfg-spike-reviewer". When you receive it, reply to that teammate via SendMessage with the text "ACK:" followed by the number they sent doubled. Then return a final report stating exactly what message you received and what you replied.
- Agent B — `name: "lfg-spike-reviewer"`, `team_name: "lfg-spike"`, `subagent_type: general-purpose`, prompt:
  > You are a reviewer in team "lfg-spike". Use SendMessage to send the teammate named "lfg-spike-consolidator" this exact text: "FINDING count=21". Then wait for their reply. Return a final report containing: (a) whether SendMessage succeeded, (b) the exact reply you received back, or "NO REPLY RECEIVED" if none arrived.

- [ ] **Step 2: Evaluate the outcome**

Expected if peer messaging WORKS: Agent B's report contains a reply like `ACK:42` (or the consolidator's reply text), and Agent A's report confirms it received `FINDING count=21`.
Expected if it FAILS: Agent B reports `NO REPLY RECEIVED`, or the `SendMessage` call errors / the teammate is not addressable.

- [ ] **Step 3: Record the result (go/no-go)**

Write `skills/lfg/references/spike-results.md` with the date, the verbatim reports from both agents, and a verdict line:
- `PEER_SENDMESSAGE: WORKS` → pure-team model is primary; file-drop is fallback only for non-grant agent types.
- `PEER_SENDMESSAGE: FAILS` → file-drop becomes the PRIMARY data plane for ALL reviewers; the consolidator still runs as a subagent but reads only files (no live interrogation). The rest of the plan still applies; in Tasks 4/5/7 prefer the file-drop branch.

- [ ] **Step 4: Commit**

```bash
git add skills/lfg/references/spike-results.md
git commit -m "lfg: record peer-SendMessage spike result"
```

---

## Task 1: Scaffold skill directory + SKILL.md frontmatter

**Files:**
- Create: `skills/lfg/SKILL.md`

- [ ] **Step 1: Create the skill file with frontmatter + section skeleton**

Write `skills/lfg/SKILL.md` with exactly this content (body phases are filled in Tasks 6–8; this establishes the frontmatter and headings):

````markdown
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
````

- [ ] **Step 2: Verify frontmatter is well-formed**

Run:
```bash
cd ~/.claude && awk '/^---$/{n++; next} n==1{print}' skills/lfg/SKILL.md | head -1
```
Expected: prints `name: lfg` (confirms the frontmatter block parses and `name` is first).

- [ ] **Step 3: Verify all five phase headings exist**

Run:
```bash
grep -c '^## Phase ' skills/lfg/SKILL.md
```
Expected: `5`

- [ ] **Step 4: Commit**

```bash
git add skills/lfg/SKILL.md
git commit -m "lfg: scaffold skill frontmatter + phase skeleton"
```

---

## Task 2: Findings schema + Node validator (TDD)

**Files:**
- Create: `skills/lfg/references/findings.schema.json`
- Create: `skills/lfg/scripts/validate_findings.mjs`
- Test: `skills/lfg/scripts/__fixtures__/valid.json`, `skills/lfg/scripts/__fixtures__/invalid.json`

- [ ] **Step 1: Write the schema**

Write `skills/lfg/references/findings.schema.json`:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "lfg reviewer findings",
  "type": "object",
  "required": ["reviewer", "agent_type", "findings"],
  "properties": {
    "reviewer": { "type": "string", "minLength": 1 },
    "agent_type": { "type": "string", "minLength": 1 },
    "findings": {
      "type": "array",
      "items": {
        "type": "object",
        "required": ["id", "dimension", "severity", "file", "title", "detail", "confidence"],
        "properties": {
          "id": { "type": "string", "pattern": "^[A-Z]+-[0-9]+$" },
          "dimension": { "type": "string" },
          "severity": { "enum": ["critical", "high", "medium", "low", "info"] },
          "file": { "type": "string" },
          "line": { "type": ["integer", "null"] },
          "title": { "type": "string", "minLength": 1 },
          "detail": { "type": "string", "minLength": 1 },
          "suggestion": { "type": ["string", "null"] },
          "confidence": { "type": "integer", "minimum": 0, "maximum": 100 }
        }
      }
    }
  }
}
```

- [ ] **Step 2: Write the test fixtures**

Write `skills/lfg/scripts/__fixtures__/valid.json`:
```json
{
  "reviewer": "security",
  "agent_type": "general-purpose",
  "findings": [
    { "id": "SEC-1", "dimension": "security", "severity": "high", "file": "src/a.ts", "line": 42, "title": "Unvalidated input", "detail": "X flows to Y unchecked.", "suggestion": "const v = sanitize(input);", "confidence": 85 }
  ]
}
```
Write `skills/lfg/scripts/__fixtures__/invalid.json` (bad severity, missing title):
```json
{
  "reviewer": "security",
  "agent_type": "general-purpose",
  "findings": [
    { "id": "SEC-1", "dimension": "security", "severity": "catastrophic", "file": "src/a.ts", "detail": "no title here", "confidence": 85 }
  ]
}
```

- [ ] **Step 3: Write the failing validator invocation**

Before writing the validator, run it to confirm it does not yet exist:
```bash
cd ~/.claude && node skills/lfg/scripts/validate_findings.mjs skills/lfg/scripts/__fixtures__/valid.json
```
Expected: FAIL — `Error: Cannot find module .../validate_findings.mjs`.

- [ ] **Step 4: Implement the validator (zero deps — hand-rolled, mirrors move-pr-review's no-dep style)**

Write `skills/lfg/scripts/validate_findings.mjs`:

```javascript
#!/usr/bin/env node
// Validates an lfg reviewer findings file. Exit 0 = valid, 1 = invalid, 2 = usage.
import { readFileSync } from "node:fs";

const SEVERITIES = ["critical", "high", "medium", "low", "info"];
const ID_RE = /^[A-Z]+-[0-9]+$/;

function fail(msg) { console.error(`INVALID: ${msg}`); process.exit(1); }

const path = process.argv[2];
if (!path) { console.error("usage: validate_findings.mjs <file.json>"); process.exit(2); }

let doc;
try { doc = JSON.parse(readFileSync(path, "utf8")); }
catch (e) { fail(`not parseable JSON: ${e.message}`); }

if (typeof doc !== "object" || doc === null) fail("top-level must be an object");
for (const k of ["reviewer", "agent_type"]) {
  if (typeof doc[k] !== "string" || doc[k].length === 0) fail(`${k} must be a non-empty string`);
}
if (!Array.isArray(doc.findings)) fail("findings must be an array");

doc.findings.forEach((f, i) => {
  const at = `findings[${i}]`;
  if (!ID_RE.test(f.id ?? "")) fail(`${at}.id must match ${ID_RE}`);
  if (typeof f.dimension !== "string" || !f.dimension) fail(`${at}.dimension required`);
  if (!SEVERITIES.includes(f.severity)) fail(`${at}.severity must be one of ${SEVERITIES.join(", ")}`);
  if (typeof f.file !== "string" || !f.file) fail(`${at}.file required`);
  if (f.line != null && !Number.isInteger(f.line)) fail(`${at}.line must be integer or null`);
  if (typeof f.title !== "string" || !f.title) fail(`${at}.title required`);
  if (typeof f.detail !== "string" || !f.detail) fail(`${at}.detail required`);
  if (f.suggestion != null && typeof f.suggestion !== "string") fail(`${at}.suggestion must be string or null`);
  if (!Number.isInteger(f.confidence) || f.confidence < 0 || f.confidence > 100) fail(`${at}.confidence must be 0..100`);
});

console.log(`VALID: ${doc.findings.length} finding(s) from reviewer "${doc.reviewer}"`);
process.exit(0);
```

- [ ] **Step 5: Run on the valid fixture (expect pass)**

```bash
cd ~/.claude && node skills/lfg/scripts/validate_findings.mjs skills/lfg/scripts/__fixtures__/valid.json; echo "exit=$?"
```
Expected: `VALID: 1 finding(s) from reviewer "security"` and `exit=0`.

- [ ] **Step 6: Run on the invalid fixture (expect fail)**

```bash
cd ~/.claude && node skills/lfg/scripts/validate_findings.mjs skills/lfg/scripts/__fixtures__/invalid.json; echo "exit=$?"
```
Expected: `INVALID: findings[0].severity must be one of ...` and `exit=1`.

- [ ] **Step 7: Commit**

```bash
git add skills/lfg/references/findings.schema.json skills/lfg/scripts/validate_findings.mjs skills/lfg/scripts/__fixtures__/
git commit -m "lfg: findings schema + zero-dep validator with fixtures"
```

---

## Task 3: PR-review poster script (`gh api`, inline suggestions)

**Files:**
- Create: `skills/lfg/scripts/post_review.sh`
- Test: `skills/lfg/scripts/__fixtures__/review-payload.json`

- [ ] **Step 1: Write a sample review payload fixture**

Write `skills/lfg/scripts/__fixtures__/review-payload.json` (the exact shape GitHub's reviews API expects; the suggestion is a fenced block inside `comments[].body`):

```json
{
  "event": "COMMENT",
  "body": "## /lfg review\n\nWalkthrough of proposed changes:\n\n1. **src/a.ts:42** — sanitize untrusted input before use.",
  "comments": [
    {
      "path": "src/a.ts",
      "line": 42,
      "side": "RIGHT",
      "body": "Untrusted input reaches the sink unchecked.\n\n```suggestion\nconst v = sanitize(input);\n```"
    }
  ]
}
```

- [ ] **Step 2: Write the failing test (script absent)**

```bash
cd ~/.claude && bash skills/lfg/scripts/post_review.sh --check skills/lfg/scripts/__fixtures__/review-payload.json
```
Expected: FAIL — `No such file or directory`.

- [ ] **Step 3: Implement the poster with a `--check` (dry-run/validate) mode**

Write `skills/lfg/scripts/post_review.sh`:

```bash
#!/usr/bin/env bash
# Post a PR review with inline suggestions via the GitHub reviews API.
# Usage:
#   post_review.sh <owner> <repo> <pr_number> <payload.json>   # posts the review
#   post_review.sh --check <payload.json>                      # validates payload only, no network
set -euo pipefail

if [[ "${1:-}" == "--check" ]]; then
  payload="${2:?usage: post_review.sh --check <payload.json>}"
  # Payload must be valid JSON with event + comments[] each having path/line/side/body.
  jq -e '
    (.event | type == "string") and
    (.body  | type == "string") and
    (.comments | type == "array") and
    (all(.comments[]; (.path|type=="string") and (.line|type=="number") and (.side|type=="string") and (.body|type=="string")))
  ' "$payload" > /dev/null
  echo "CHECK OK: $payload"
  exit 0
fi

owner="${1:?owner}"; repo="${2:?repo}"; pr="${3:?pr_number}"; payload="${4:?payload.json}"
bash "$0" --check "$payload"   # validate before sending
gh api -X POST "repos/${owner}/${repo}/pulls/${pr}/reviews" --input "$payload"
echo "POSTED review to ${owner}/${repo}#${pr}"
```

- [ ] **Step 4: Run `--check` on the fixture (expect pass)**

```bash
cd ~/.claude && bash skills/lfg/scripts/post_review.sh --check skills/lfg/scripts/__fixtures__/review-payload.json; echo "exit=$?"
```
Expected: `CHECK OK: ...` and `exit=0`.

- [ ] **Step 5: Negative check — malformed payload fails**

```bash
cd ~/.claude && echo '{"event":"COMMENT"}' > /tmp/lfg-bad.json && bash skills/lfg/scripts/post_review.sh --check /tmp/lfg-bad.json; echo "exit=$?"
```
Expected: non-zero exit (jq `-e` fails because `comments` is absent).

- [ ] **Step 6: Commit**

```bash
git add skills/lfg/scripts/post_review.sh skills/lfg/scripts/__fixtures__/review-payload.json
git commit -m "lfg: gh-api PR review poster with --check validation"
```

---

## Task 4: Reviewer prompt reference

**Files:**
- Create: `skills/lfg/references/reviewer_prompt.md`

- [ ] **Step 1: Write the reviewer prompt template**

Write `skills/lfg/references/reviewer_prompt.md`:

````markdown
# lfg reviewer prompt (template)

The orchestrator fills the `{{...}}` placeholders before dispatch.

---

You are the **{{DIMENSION}}** reviewer for pull request #{{PR_NUMBER}} in
`{{OWNER}}/{{REPO}}` (branch `{{HEAD_REF}}` vs `{{BASE_REF}}`).

## Scope
Review ONLY these changed files for {{DIMENSION}} issues:
{{FILE_LIST}}

The diff is the source of truth. Read the changed files and enough surrounding
context to judge each change. Do not review unmodified lines.

## What to flag (dimension: {{DIMENSION}})
{{DIMENSION_GUIDANCE}}

Ignore: pre-existing issues on unmodified lines; pure style a linter/compiler
catches; speculative nitpicks a senior engineer would not raise.

## For every finding, produce a record with:
- `id`: `{{DIMENSION_PREFIX}}-<n>` (e.g. `SEC-1`)
- `dimension`: "{{DIMENSION}}"
- `severity`: critical | high | medium | low | info
- `file`, `line` (integer or null)
- `title` (short), `detail` (why it's a problem, citing the code)
- `suggestion`: a CONCRETE replacement for the offending line(s) when a clear fix
  exists, else null. This becomes a GitHub ```suggestion block, so it must be the
  exact replacement text for the cited line(s) — no diff markers, no commentary.
- `confidence`: 0–100 (your honest confidence it's a real, in-practice issue)

## How to report — pick the mode the orchestrator told you to use:

**Mode A — team chat (you have SendMessage):**
When done, send ONE message to the teammate named "{{CONSOLIDATOR_NAME}}" whose body
is a fenced ```json block containing `{ "reviewer", "agent_type", "findings": [...] }`.
Then remain available: if the consolidator messages you to justify a finding, answer
with specific code evidence (file/line/quote). Return a one-line final report.

**Mode B — file drop (you lack SendMessage):**
Write the same `{ "reviewer", "agent_type", "findings": [...] }` JSON to
`{{RUN_DIR}}/findings-{{DIMENSION}}.json`. Return a one-line final report naming the
file you wrote. (Move reviewers via sui-pilot-agent use this mode until that agent
gains the SendMessage grant.)

If you found nothing, still report/write an empty `findings: []`.
````

- [ ] **Step 2: Verify both modes and the schema fields are present**

```bash
cd ~/.claude && grep -Ec 'Mode A|Mode B|confidence|suggestion|CONSOLIDATOR_NAME|RUN_DIR' skills/lfg/references/reviewer_prompt.md
```
Expected: a number ≥ 6 (all key tokens present).

- [ ] **Step 3: Commit**

```bash
git add skills/lfg/references/reviewer_prompt.md
git commit -m "lfg: reviewer prompt template (dual-mode reporting)"
```

---

## Task 5: Consolidator prompt reference

**Files:**
- Create: `skills/lfg/references/consolidator_prompt.md`

- [ ] **Step 1: Write the consolidator prompt template**

Write `skills/lfg/references/consolidator_prompt.md`:

````markdown
# lfg consolidator prompt (template)

The orchestrator fills `{{...}}` before dispatch.

---

You are the **consolidator** for pull request #{{PR_NUMBER}} in `{{OWNER}}/{{REPO}}`.
Your job: gather all reviewer findings, verify them against the actual source, drop
false positives, and post ONE GitHub PR review with inline suggestions + a walkthrough.

## Roster
Reviewers in your team: {{REVIEWER_NAMES}}
Run dir for file-drop findings: {{RUN_DIR}}

## 1. Collect
- For chat-capable reviewers: wait until each has sent you its findings JSON message.
- For file-drop reviewers: read every `{{RUN_DIR}}/findings-*.json`.
- Validate each file-drop file first:
  `node {{SKILL_DIR}}/scripts/validate_findings.mjs <file>` — skip + note any that fail.

## 2. Verify (false-positive filter)
For EACH critical/high finding, and any finding with confidence < 70:
- Re-read the cited file/lines yourself and re-derive the problem path.
- If a reviewer is chat-capable, SendMessage them to justify uncertain findings; weigh
  the reply against the code. (If peer messaging is unavailable per spike-results.md,
  rely on your own re-reading.)
- Drop findings that don't survive: not reachable, pre-existing, intended behavior, or
  a nitpick. Keep a short note of what you dropped and why.

## 3. Cluster + order
Dedupe findings that point at the same file/line/issue. Order kept findings by severity,
then by how many reviewers independently raised them.

## 4. Build the review payload
Write `{{RUN_DIR}}/review-payload.json` shaped as:
`{ "event": "COMMENT", "body": <walkthrough markdown>, "comments": [ {path, line, side:"RIGHT", body} ] }`
- One `comments[]` entry per finding that has a concrete `suggestion`; put the rationale
  text then a ```suggestion fenced block with the exact replacement.
- Findings without a clean single-line/range fix go in the top-level `body` walkthrough
  as prose (file:line + what to change), not as inline suggestions.
- The `body` is the "comment walking through all the proposed changes": list every
  proposed change with file:line and a one-line rationale, plus the dropped-FP count.

## 5. Post
- Validate: `bash {{SKILL_DIR}}/scripts/post_review.sh --check {{RUN_DIR}}/review-payload.json`
- Post: `bash {{SKILL_DIR}}/scripts/post_review.sh {{OWNER}} {{REPO}} {{PR_NUMBER}} {{RUN_DIR}}/review-payload.json`

## 6. Return to the orchestrator
Return a structured final report: counts (kept/dropped per severity), the list of inline
suggestions (file:line + title), the list of walkthrough-only items, and the review URL/id
from the `gh api` response. The orchestrator (main session) adjudicates from this.
````

- [ ] **Step 2: Verify the six numbered steps and the script references exist**

```bash
cd ~/.claude && grep -Ec '## [1-6]\.|validate_findings.mjs|post_review.sh|review-payload.json' skills/lfg/references/consolidator_prompt.md
```
Expected: a number ≥ 7.

- [ ] **Step 3: Commit**

```bash
git add skills/lfg/references/consolidator_prompt.md
git commit -m "lfg: consolidator prompt template (verify + post review)"
```

---

## Task 6: SKILL.md body — Phases 0, 1, 2

**Files:**
- Modify: `skills/lfg/SKILL.md` (replace the Phase 0/1/2 placeholder comments)

- [ ] **Step 1: Fill Phase 0 (Preflight)**

Replace `## Phase 0 — Preflight\n<!-- filled in Task 6 -->` with:

````markdown
## Phase 0 — Preflight

You MUST be the main session (you have the `Agent` tool). If you are a spawned subagent,
STOP and tell the user to run `/lfg` from the top-level session.

1. Confirm a GitHub remote + auth: `gh auth status` and `git remote get-url origin`.
   If either fails, stop and report what's missing.
2. Capture repo coordinates: `OWNER/REPO` from `gh repo view --json owner,name -q '.owner.login+"/"+.name'`.
3. Confirm there are changes to ship: `git status --porcelain`. If empty AND no branch-vs-main
   diff exists, stop — there is nothing to /lfg.
4. Create a gitignored run dir OUTSIDE the repo for findings/payloads:
   `RUN_DIR="${CLAUDE_JOB_DIR:-$TMPDIR}/lfg-$(git rev-parse --short HEAD 2>/dev/null || echo run)"`
   then `mkdir -p "$RUN_DIR"`. Remember this path for Phases 3–4.
5. Note `SKILL_DIR` = the absolute path of this skill's directory (for calling its scripts).
````

- [ ] **Step 2: Fill Phase 1 (Ship)**

Replace the Phase 1 placeholder with:

````markdown
## Phase 1 — Ship (/commit-push-pr)

Invoke the `/commit-push-pr` skill. It branches off `main` if needed, makes one commit,
pushes, and opens the PR. After it completes, capture for later phases:

- `PR_NUMBER`: `gh pr view --json number -q .number`
- `BASE_REF` / `HEAD_REF`: `gh pr view --json baseRefName,headRefName -q '.baseRefName+" "+.headRefName'`
- `HEAD_SHA`: `git rev-parse HEAD`
- changed files vs base: `git diff --name-only "$BASE_REF"...HEAD` (this is the review scope)

If `/commit-push-pr` did not result in an open PR (e.g. push failed), stop and report.
````

- [ ] **Step 3: Fill Phase 2 (Simplify)**

Replace the Phase 2 placeholder with:

````markdown
## Phase 2 — Simplify (/simplify + second commit)

1. Invoke the `/simplify` skill. It edits the working tree for reuse/efficiency/clarity
   (quality only — it does NOT hunt bugs; that's Phase 3's job).
2. If `git status --porcelain` is now non-empty, land the cleanup as its own commit:
   ```bash
   git add -A && git commit -m "simplify" && git push
   ```
   If `/simplify` changed nothing, skip the commit (do not create an empty commit).
3. Refresh the changed-file list (it may have grown): `git diff --name-only "$BASE_REF"...HEAD`.
````

- [ ] **Step 4: Verify the placeholders are gone**

```bash
cd ~/.claude && grep -c 'filled in Task 6' skills/lfg/SKILL.md
```
Expected: `0`.

- [ ] **Step 5: Commit**

```bash
git add skills/lfg/SKILL.md
git commit -m "lfg: SKILL body phases 0-2 (preflight, ship, simplify)"
```

---

## Task 7: SKILL.md body — Phase 3 (team review orchestration)

**Files:**
- Modify: `skills/lfg/SKILL.md` (replace the Phase 3 placeholder)

- [ ] **Step 1: Fill Phase 3**

Replace `## Phase 3 — Team review\n<!-- filled in Task 7 -->` with:

````markdown
## Phase 3 — Team review

You orchestrate; you do NOT review yourself. All spawning happens here, in the main session.

### 3.1 Classify the diff and choose reviewers
- Split the changed-file list into Move files (`*.move`, `Move.toml`) and the rest.
- Pick dimensions to cover (scale count to diff size; small diff → fewer):
  correctness/bugs, security, performance, tests, docs/comments, CLAUDE.md & conventions,
  API/type design. Drop dimensions with no relevant files (e.g. no tests touched → you may
  still include `tests` to check for MISSING coverage; use judgment).
- Assign each dimension a reviewer:
  - If that dimension's scope is Move files → `subagent_type: sui-pilot:sui-pilot-agent`
    (fallback chain: `sui-pilot:sui-pilot-agent` → `sui-pilot-agent` → `general-purpose`;
    the sui-pilot reviewer additionally runs `/move-code-review` + `/move-code-quality`).
  - Otherwise → `subagent_type: general-purpose`.
- Determine reporting mode per reviewer from `references/spike-results.md` + the agent's
  grant: an agent reports via **Mode A (chat)** only if peer-SendMessage WORKS *and* its
  type grants SendMessage (today: only generic agents). Everyone else uses **Mode B (file drop)**.

### 3.2 Spawn the team — ALL in ONE assistant turn
- `TeamCreate` a team (e.g. `lfg-review-<PR_NUMBER>`).
- In a single turn, dispatch every reviewer + the consolidator as parallel `Agent` calls,
  all with the same `team_name`, each with a unique `name`:
  - Reviewers: prompt = `references/reviewer_prompt.md` with `{{...}}` filled
    (DIMENSION, DIMENSION_PREFIX, DIMENSION_GUIDANCE, FILE_LIST scoped to that reviewer,
    PR/repo refs, CONSOLIDATOR_NAME, RUN_DIR, and the chosen reporting mode).
  - Consolidator: `name` = the CONSOLIDATOR_NAME you gave reviewers,
    `subagent_type: general-purpose` (needs Bash + SendMessage), prompt =
    `references/consolidator_prompt.md` with `{{...}}` filled (REVIEWER_NAMES roster,
    RUN_DIR, SKILL_DIR, PR/repo refs).
- Reviewers report (chat or file); the consolidator collects, verifies, and posts the
  PR review; it returns a structured summary to you.

### 3.3 Sanity-check before adjudicating
- Confirm a review was actually posted: `gh pr view "$PR_NUMBER" --json reviews -q '.reviews | length'`
  should be ≥ 1, or trust the review id the consolidator returned.
- Keep the consolidator's returned summary (kept/dropped counts, inline suggestions list,
  walkthrough-only items) — Phase 4 adjudicates from it + the posted review.
````

- [ ] **Step 2: Verify Phase 3 references the prompt files and TeamCreate**

```bash
cd ~/.claude && grep -Ec 'TeamCreate|reviewer_prompt.md|consolidator_prompt.md|sui-pilot:sui-pilot-agent|ONE assistant turn' skills/lfg/SKILL.md
```
Expected: a number ≥ 5.

- [ ] **Step 3: Commit**

```bash
git add skills/lfg/SKILL.md
git commit -m "lfg: SKILL body phase 3 (team review orchestration)"
```

---

## Task 8: SKILL.md body — Phase 4 (self-adjudicate + approve)

**Files:**
- Modify: `skills/lfg/SKILL.md` (replace the Phase 4 placeholder)

- [ ] **Step 1: Fill Phase 4**

Replace `## Phase 4 — Self-adjudicate + approve\n<!-- filled in Task 8 -->` with:

````markdown
## Phase 4 — Self-adjudicate + approve

You now act as the PR author deciding what to take from the review.

1. Read the posted review and the consolidator's summary. For EACH inline suggestion and
   each walkthrough item, decide ACCEPT or REJECT on its merits (correctness + fit with the
   codebase). Be willing to reject low-value or wrong suggestions — explain why.
2. Apply every ACCEPTED change locally by editing the file to match the suggestion. (We
   apply via local edits, not GitHub's "commit suggestion" button.)
3. If you accepted any change:
   ```bash
   git add -A && git commit -m "apply review suggestions" && git push
   ```
4. Post your adjudication so the threads aren't left dangling. Reply once summarizing
   per-item ACCEPT/REJECT (+ one-line reasons):
   ```bash
   gh pr comment "$PR_NUMBER" --body-file "$RUN_DIR/adjudication.md"
   ```
   (Best-effort: to resolve individual inline threads, fetch thread ids via
   `gh api graphql` querying `pullRequest.reviewThreads` then call the
   `resolveReviewThread` mutation per id. Skip if it adds no value.)
5. Approve, leaving the PR open + merge-ready for a human:
   ```bash
   gh pr review "$PR_NUMBER" --approve --body "lfg pipeline complete: shipped, simplified, reviewed (N kept / M dropped), suggestions adjudicated. Ready for human merge."
   ```
6. Report to the user: the PR URL (the deliverable), the commits made (feature /
   simplify / apply review suggestions), kept-vs-dropped finding counts, what you
   accepted vs rejected and why, and that the PR is approved and awaiting human merge.
````

- [ ] **Step 2: Verify no placeholders remain anywhere in the skill body**

```bash
cd ~/.claude && grep -c 'filled in Task' skills/lfg/SKILL.md
```
Expected: `0`.

- [ ] **Step 3: Verify the full skill has all phases + key actions**

```bash
cd ~/.claude && grep -Ec '^## Phase|gh pr review .* --approve|apply review suggestions|/commit-push-pr|/simplify' skills/lfg/SKILL.md
```
Expected: a number ≥ 7.

- [ ] **Step 4: Commit**

```bash
git add skills/lfg/SKILL.md
git commit -m "lfg: SKILL body phase 4 (adjudicate + approve)"
```

---

## Task 9: Companion change — grant `sui-pilot-agent` the `SendMessage` tool

> **SEPARATE REPO.** This change is in `~/workspace/sui-pilot`, not in `~/.claude`. It is a
> prerequisite for Move reviewers to use chat mode (until then they use file-drop, which works).
> Do NOT edit the marketplace cache under `~/.claude/plugins/cache/...` — it is clobbered on update.

**Files:**
- Modify: `~/workspace/sui-pilot/agents/sui-pilot-agent.md` (the `tools:` frontmatter list)

- [ ] **Step 1: Confirm current grant lacks SendMessage**

```bash
cd ~/workspace/sui-pilot && sed -n '/^tools:/,/^[a-z]/p' agents/sui-pilot-agent.md | grep -c SendMessage
```
Expected: `0`.

- [ ] **Step 2: Add `SendMessage` to the tools list**

Edit `~/workspace/sui-pilot/agents/sui-pilot-agent.md`: in the `tools:` YAML list, add a new
line `  - SendMessage` (match the existing 2-space-dash indentation, place it after `Bash`).

- [ ] **Step 3: Verify it's present and the file still has valid frontmatter**

```bash
cd ~/workspace/sui-pilot && grep -c '  - SendMessage' agents/sui-pilot-agent.md && head -1 agents/sui-pilot-agent.md
```
Expected: `1` then `---`.

- [ ] **Step 4: Commit (in the sui-pilot repo) and note republish**

```bash
cd ~/workspace/sui-pilot && git add agents/sui-pilot-agent.md && git commit -m "agent: grant sui-pilot-agent SendMessage for lfg team review"
```
Then publish to the contract-hero marketplace per the repo's normal release flow, and
`/reload-plugins` (or restart) so the new grant is live. Until republished, `/lfg` Move
reviewers stay in file-drop mode automatically.

---

## Task 10: End-to-end smoke test + finalize

**Files:** none created; this validates the assembled skill.

- [ ] **Step 1: Make `~/.claude` see the new skill**

The worktree branch isn't live yet. To smoke-test, either merge to `main` first (Step 4) or
copy the skill into place temporarily. Simplest: do Steps 2–3 as a structured dry-read, then
do the real run after merge.

- [ ] **Step 2: Dry-read validation (no network)**

```bash
cd ~/.claude && \
  node skills/lfg/scripts/validate_findings.mjs skills/lfg/scripts/__fixtures__/valid.json && \
  bash skills/lfg/scripts/post_review.sh --check skills/lfg/scripts/__fixtures__/review-payload.json && \
  grep -c 'filled in Task' skills/lfg/SKILL.md
```
Expected: validator `VALID...`, poster `CHECK OK...`, and `0` remaining placeholders.

- [ ] **Step 3: Live smoke test (after merge) on a throwaway change**

In a scratch git repo with a GitHub remote (or a disposable branch of a real repo), make one
trivial code change, then run `/lfg`. Verify the four phases produce: a branch + opened PR,
a `simplify` commit only if /simplify changed something, a posted PR review (walkthrough
comment, inline suggestions when applicable), an `apply review suggestions` commit only if
you accepted anything, an adjudication comment, and an approval. Confirm `gh pr view <n>
--json reviews` shows the review + approval.

- [ ] **Step 4: Merge the worktree branch to main (make the skill live)**

```bash
cd ~/.claude && git checkout main && git merge --no-ff worktree-lfg-skill -m "Add /lfg skill" && git push
```
(Per the user's git preference, direct push to main on this personal repo is fine.)

- [ ] **Step 5: Final verification — skill is discoverable**

Start a fresh session (or `/reload-plugins`) and confirm `/lfg` appears in the skill list with
the expected description.

---

## Self-Review (run by the plan author before handing off)

**Spec coverage** — every spec section maps to a task:
- Vehicle/location → Task 1. Phase 1 (/commit-push-pr) → Task 6. Phase 2 (/simplify + 2nd commit) → Task 6.
- Phase 3 team review + domain routing + reviewers → Tasks 4, 5, 7. Consolidator posts GH review w/ suggestions → Tasks 3, 5.
- Phase 4 adjudicate + apply (3rd commit) + auto-approve → Task 8. File-drop fallback → Tasks 2, 4, 5, 7.
- Companion sui-pilot SendMessage grant → Task 9. Top risk (peer-SendMessage spike) → Task 0.
- Mechanism decisions (gh api suggestions, local apply, run dir) → Tasks 3, 6, 8. Success criteria → Task 10.

**Placeholder scan:** the `{{...}}` tokens in reviewer/consolidator prompts are intentional template slots filled by the orchestrator at dispatch (documented as such), not plan placeholders. No "TBD/TODO" in executable steps.

**Type/name consistency:** findings JSON shape (`reviewer`, `agent_type`, `findings[]` with `id/dimension/severity/file/line/title/detail/suggestion/confidence`) is identical across `findings.schema.json` (Task 2), `validate_findings.mjs` (Task 2), reviewer prompt (Task 4), and consolidator prompt (Task 5). Review payload shape (`event/body/comments[].{path,line,side,body}`) is identical across `post_review.sh` (Task 3), the fixture (Task 3), and the consolidator prompt (Task 5). `CONSOLIDATOR_NAME`/`REVIEWER_NAMES`/`RUN_DIR`/`SKILL_DIR` are used consistently. `validate_findings.mjs` and `post_review.sh` names match every call site.
