# Reviewer Routing Doctrine

Maps file signals → recommended reviewer agent. Consumed by the `routing-resolve` primitive; documented here so it's auditable.

Inspired by `code-forge` v0.2.0's `project_domains` / `required_subagents` / `recommended_agents` system. See `~/.claude/plugins/cache/contract-hero/code-forge/0.1.0/docs/agent-routing.md` for the original pattern.

---

## 1. Routing model: hybrid (per-cluster + dimension-lane)

- **Per-cluster routing** picks the *main* reviewer agent for each file cluster (e.g. Move files → `sui-pilot:sui-pilot-agent`).
- **Dimension lanes** add cross-cutting reviewers triggered by diff *content* signals (e.g. new `catch`/`try` blocks → `silent-failure-hunter` runs in addition to the cluster's main reviewer).

This combines `code-forge`'s validated per-cluster precedent with `pr-review-toolkit:review-pr`'s dimensional approach.

---

## 2. Decision table

### 2.1 Per-cluster primary

| Trigger | Reviewer agent | Notes |
|---|---|---|
| `**/*.move` OR `Move.toml` present in changed paths | `sui-pilot:sui-pilot-agent` | Hard-required for Move; matches `move-pr-review`'s pattern. Has LSP + sui-prover MCPs. |
| `**/*.{ts,tsx,js,jsx}` cluster ≥ 50 lines changed | `pr-review-toolkit:code-reviewer` | Opus, ≥80 confidence filter, CLAUDE.md aware |
| `**/*.{ts,tsx,js,jsx}` cluster < 50 lines | `feature-dev:code-reviewer` | Sonnet (faster); good for redundancy slot |
| No specialist matches | `general-purpose` | Fallback; never blocks the fan-out |

### 2.2 Dimension lanes (triggered by diff content)

These run **in addition to** the per-cluster primary, not instead.

| Trigger (sampled from `pr.diff`) | Reviewer agent | Why |
|---|---|---|
| Diff adds `catch`/`try`/`throw`/`panic`/`unwrap` patterns | `pr-review-toolkit:silent-failure-hunter` | Zero-tolerance error-handling auditor |
| Diff adds `type`/`interface`/`struct`/`enum` declarations | `pr-review-toolkit:type-design-analyzer` | Invariant-focused type review (1–10 ratings) |
| `**/*.test.{ts,tsx}` OR `**/__tests__/**` OR `**/*_test.move` changed | `pr-review-toolkit:pr-test-analyzer` | Behavioral coverage, edge-case audit |
| ≥80% of changed lines are comments | `pr-review-toolkit:comment-analyzer` | Comment-rot + accuracy check |

### 2.3 Post-pass (run sequentially after fan-out)

| When | Agent | Role |
|---|---|---|
| Before fan-out (optional) | `pr-review-toolkit:code-simplifier` | Polish suggestions; current `ship-reviewed-pr` Phase 2 |

---

## 3. Fallback chain

When dispatching a specialized reviewer, `reviewer-fan-out` tries in this order:

```
preferred_subagent_type → bare_name → general-purpose
```

Example (Move): `sui-pilot:sui-pilot-agent` → `sui-pilot-agent` → `general-purpose`.

When a fallback fires, the dispatch record (`_dispatch.json`) gets a `fallback_reason` string. The render skills surface this in the Methodology section so reviewers/PR authors know they got a degraded run.

Detection happens at dispatch time, not at routing time. (The routing-resolve primitive emits *recommendations*; it doesn't gate on availability.)

---

## 4. Edge cases

| Case | Behavior |
|---|---|
| Mixed Move + TS PR | Two clusters; sui-pilot-agent on Move files, pr-review-toolkit:code-reviewer on TS files; dimension lanes apply across both |
| Docs-only diff (only `*.md`) | Single `comment-analyzer` lane + 1 `general-purpose` reviewer; skip code-cluster fan-out |
| Infra-only diff (only `.github/`, `Dockerfile`, etc.) | Single `general-purpose` reviewer (no specialist exists); document gap below |
| Monorepo (multiple manifests) | Cluster by manifest root; each cluster gets its own primary; dimension lanes run once across all clusters |
| Specialized agent matches but plugin disabled / MCP missing at runtime | Fall back via the chain; surface degradation in report |
| Two specialists could apply (Move file with `catch` block) | Cluster primary wins file ownership (sui-pilot for the Move file); dimension lane (silent-failure-hunter) runs IN ADDITION |

---

## 5. Profiles

`routing-resolve` accepts a `--profile` arg:

| Profile | Use case | Behavior |
|---|---|---|
| `redundancy` | `ship-reviewed-pr` (3 reviewers, identical prompts) | Three slots all routed to the cluster primary; dimension lanes added |
| `dimensional` | `stepped-pr` Phase B (N orchestrators, disjoint focus areas) | One slot per focus area; each slot routes per-cluster + carries its focus prompt |
| `hybrid` | most everyday PR review | Default cluster routing + dimension lanes as auto-suggested |

---

## 6. Known gaps

- **No standalone security reviewer.** `code-forge:forge-reviewer`'s security lens isn't portable. Until one is built, security findings fall to whatever cluster primary runs.
- **No React/component specialist.** General TS reviewers cover it but lack component-pattern depth.
- **No performance reviewer.** Currently nobody flags algorithmic complexity, bundle size, or rendering overhead.
- **Infra-only PRs** (workflows, Dockerfiles) get only `general-purpose`. Future: add a dedicated infra reviewer agent.
