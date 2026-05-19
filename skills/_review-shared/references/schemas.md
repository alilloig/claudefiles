# Canonical Schemas — Finding JSON, Context Bundle Layout, Severity Rubric

Single source of truth for every `_review-shared/` primitive skill. Every reviewer agent reads from here; every consolidator validates against it.

---

## 1. Finding JSON schema

Each `subagent-<N>.json` is a JSON array. Each element is an object with the following keys.

### Required fields

```jsonc
{
  "id":             "R<reviewer-id>-<NNN>",   // e.g. R3-007
  "title":          "<= 80 chars",
  "severity":       "critical|high|medium|low|info",
  "category":       "<one of the 23 categories below>",
  "file":           "<repo-relative path, no leading ./>",
  "line_range":     "N | N-M",                  // single line OR inclusive range
  "description":    "what is wrong / suspicious",
  "impact":         "concrete consequence; for criticals, name attacker + call sequence",
  "recommendation": "specific actionable instruction (code change, check, test)",
  "evidence":       "literal quote, ≥ 1 full line, no ellipsis, no paraphrase",
  "confidence":     "high|medium|low"           // reviewer subjective certainty
}
```

### Optional / conditional fields

```jsonc
{
  "domain":         "move|ts-js|generic",       // optional; helps routing round-trips
  "spec_reference": "<AC#|doc§|file:line>"      // REQUIRED iff severity ∈ {critical, high}
}
```

`spec_reference` is the "primary source" demand: high-severity claims must cite something concrete (an acceptance criterion, a design-doc section, a file:line of upstream behavior). The consolidator will downgrade or drop high/critical findings without it.

### Field rules

- `id` — prefix `R<N>` where `<N>` is the reviewer number, e.g. `R3-007`. `R0` reserved for leader/orchestrator backfill.
- `title` — ≤ 80 characters; one-line summary.
- `severity` — exactly one of the five rubric values.
- `category` — exactly one of the categories below. Pick the best fit; do not invent.
- `file` — repo-relative path, no leading `./`.
- `line_range` — `N` or `N-M` (inclusive, M ≥ N).
- `evidence` — literal quote from the cited file. No `...`. If quoting upstream, include the upstream file path in the body.
- All string fields must be non-empty.

### Anti-patterns (rejected by consolidator)

- Empty fields.
- `evidence` that paraphrases instead of quoting.
- `id` collisions across reviewers (the `R<N>` prefix prevents this).
- Severity inflation without a concrete adversary path (criticals especially).
- Findings on out-of-scope files (consolidator ignores these).
- Multiple distinct concerns packed into one finding — file separately.

---

## 2. Category vocabulary (23 categories)

The union of `move-pr-review` (11), `stepped-pr` (8), and `ship-reviewed-pr` (9). Pick the best fit; do not invent.

| Category | Use when |
|---|---|
| `access-control` | Auth proofs, RBAC, permission checks, capability usage |
| `correctness` | Logic bugs, wrong assertions, incorrect state transitions |
| `arithmetic` | Overflow / underflow / precision loss / division semantics |
| `object-model` | Move object DOF/DF, ownership, sharing, derivation, lifecycle |
| `versioning` | Package version gates, migration paths, dep pin issues |
| `integration-boundary` | Cross-package call mismatches, signature drift, witness conventions |
| `events` | Missing events, wrong event types, audit-trail gaps |
| `move-quality` | Move 2024 idioms, unused abilities, edition-beta usage, naming |
| `testing` | Missing or weak tests, untested critical paths |
| `scripts` | Off-chain script / SDK usage / deploy fragility |
| `docs` | README / module doc / inline comment accuracy |
| `design` | Architectural concerns, coupling, separation of concerns |
| `error-handling` | Silent failures, swallowed exceptions, fallback hazards |
| `simplicity` | Accidental complexity, dead code, redundant indirection |
| `security` | Auth gaps, input validation, capability leaks, OWASP-class issues |
| `performance` | Algorithmic complexity, memory leaks, latency, bundle size |
| `build` | CI/CD, manifest, dependency, build-system issues |
| `api-contract` | Public API stability, request/response shape, versioning |
| `concurrency` | Race conditions, ordering, atomicity, shared mutable state |
| `data-integrity` | Schema validation, persistence, migration correctness |
| `observability` | Logging, metrics, tracing, debuggability gaps |
| `type-design` | Type-system invariants, encapsulation, overly weak types |
| `comments` | Code comment accuracy, completeness, rot |

---

## 3. Severity rubric

Canonical scale: `critical | high | medium | low | info`.

| Level | Use when |
|---|---|
| **critical** | Loss of funds, bypass of compliance/authorization, broken authorization boundary, lost upgrade path, or any flaw that immediately compromises the system. Reserve for findings where the adversary path can be described concretely. **Requires `spec_reference`.** |
| **high** | Incorrect behavior on the golden path, missing check that enables misuse, state corruption under legitimate call sequences, material weakening of security/operations. **Requires `spec_reference`.** |
| **medium** | Correctness ambiguity, missing event/error, unsafe default, fragile upstream dependency, test gaps for critical paths, operational issues that don't immediately enable misuse. |
| **low** | Style / idiom drift, redundant code, naming inconsistencies, non-essential test gaps, code-quality polish. |
| **info** | Observations, doc suggestions, follow-ups not blocking merge, design notes. |

### Mappings from other rubrics

The canonical scale absorbs the rubrics used by other tools. Reviewers running `code-review`-style flows or `pr-review-toolkit`'s 0–100 confidence model should map back to this scale before emitting findings.

| Source scale | Mapping to canonical |
|---|---|
| `Critical / Major / Minor / NiceToHave` (stepped-pr) | Critical → critical, Major → high, Minor → medium\|low (consolidator decides), NiceToHave → info |
| 0–100 confidence (code-review, pr-review-toolkit) | <50 → drop, 50–74 → low, 75–89 → medium, ≥90 → high; critical only when reviewer tags adversary path |
| `S1 / S2 / S3 / S4` (move-code-review checks) | S1 → critical, S2 → high, S3 → medium, S4 → low |

`confidence` is **separate** from severity — it expresses reviewer certainty, not impact. The consolidator uses both: severity sorts findings; confidence weights verification-pass priority.

---

## 4. Context bundle layout

The standard directory `pr-context-bundle` writes (and that every other primitive reads from).

```
<bundle-root>/
├── pr.diff                  # raw diff (gh pr diff OR git diff)
├── pr.meta.json             # {files, headRefOid, baseRefName, headRefName, title, body, additions, deletions, commits, number}
├── scope_files.txt          # newline-delimited changed files (deduped, repo-relative, no leading ./)
├── claude-md-paths.txt      # every CLAUDE.md between repo root and each changed file's dir (deduped, root→leaf)
├── dep-pins.json            # {deps: [{name, rev, is_branch, local_clone_path, local_head}, ...]}
├── design-docs/
│   ├── index.md             # what's in this dir
│   ├── linear-<TICKET>.md   # one file per fetched doc
│   └── notion-<slug>.md
├── context.md               # bundled briefing (composed from sections 1–7 + 11–12 of move-pr-review's context_bundle_template.md, MINUS leads if --anti-bias)
├── reviewers/
│   ├── prompts/
│   │   └── subagent-<N>.md  # per-reviewer prompt body
│   ├── subagent-<N>.json    # findings array (this schema)
│   ├── subagent-<N>.md      # short prose narrative
│   └── _dispatch.json       # {reviewer_id, subagent_type, fallback_reason?, ...} for methodology section
├── _consolidated.json       # clustering output (see consolidate.js)
├── _verification_notes.md   # adjudication log (private/scratch)
├── review.html              # primary deliverable
├── review.md                # markdown variant (optional)
└── pr-comment.md            # short TL;DR for gh pr comment (≤ 20 lines, links to review.html)
```

### Field semantics for `_consolidated.json`

See `scripts/consolidate.js` source. Each cluster object:

```jsonc
{
  "cluster_id":         "C001",
  "title":              "best title from the cluster",
  "file":               "...",
  "line_ranges":        ["45-48", "46-50"],
  "agreement_count":    3,
  "reviewers":          [1, 4, 7],
  "max_severity":       "high",
  "min_severity":       "medium",
  "disputed_severity":  false,
  "categories":         ["correctness"],
  "recommendations":    ["..."],
  "descriptions":       ["..."],
  "impacts":            ["..."],
  "evidence":           "longest evidence quote from the cluster",
  "confidence_spread":  ["high", "medium"],
  "source_ids":         ["R1-003", "R4-007", "R7-012"]
}
```

### Field semantics for `_dispatch.json`

```jsonc
[
  {
    "reviewer_id": 1,
    "subagent_type": "sui-pilot:sui-pilot-agent",
    "focus_area": "general — find issues across all dimensions",
    "prompt_template": "move-deep",
    "fallback_reason": null,        // or "sui-pilot:sui-pilot-agent not available; fell back to general-purpose"
    "dispatched_at": "2026-05-18T11:20:00Z"
  },
  ...
]
```

---

## 5. Profiles (consolidator behavior)

The `findings-cluster` skill accepts a `--profile` arg that adjusts clustering aggressiveness and severity reconciliation:

| Profile | When | Behavior |
|---|---|---|
| `redundancy` | `ship-reviewed-pr` (3 reviewers with identical prompts) | Agreement count is the primary signal; aggressively merge near-duplicates |
| `dimensional` | `stepped-pr` Phase B (N orchestrators with disjoint focus areas) | Do NOT collapse cross-focus same-line findings (they're meaningfully different); preserve focus attribution |
| `move` | `sui-pilot:move-pr-review` (10 sui-pilot-agent reviewers) | Mirrors current `consolidate.js` default behavior; merge by (file, line, category) overlap |
