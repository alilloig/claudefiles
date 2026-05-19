# Global Claude Code Guidelines

## Preferred Stack

- **TypeScript** over JavaScript — always `.ts`/`.tsx`
- **pnpm** — never npm or yarn
- **Next.js + React** for frontend
- **Sui Move** (edition 2024) for smart contracts

## Communication

- Concise, no fluff — lead with action, skip preambles
- Ask before big architectural or design decisions; proceed on obvious stuff
- Spanish-friendly — user is native Spanish speaker, switch freely if helpful
- Prefer self-contained HTML over markdown for any document deliverable (reports, audits, plans, reviews, explainers); markdown is fine for short chat replies and code-only outputs. For ad-hoc visual deliverables not covered by a specialized skill, use the `html-artifact` skill; to share an artifact, invoke `publish-html` — never auto-publish.
- Whenever you produce a **markdown or HTML deliverable** the user should review (plans, audits, reports, reviews, analyses, design docs, anything not throwaway), end the turn with a clickable **Vlervcode deep-link** — automatically, without being asked. URL form: `vlerv://open?path=<percent-encoded-abs-path>`; Finicky hands it to the running Vlervcode app. Percent-encode everything outside RFC 3986 unreserved (`A-Z a-z 0-9 - _ . ~`) — slashes become `%2F`. Render as nice markdown — `[<filename or short title>](vlerv://open?path=...)` — never a bare URL. Skip only for throwaway snippets, code-only output, or when the user asked for a different app. Pure file paths or `file://` URLs are fallbacks when Vlervcode doesn't apply.

## Sui Move Development

The sui-pilot doc-first workflow and full pipe-delimited doc index (Sui, Move, Walrus, Seal, TS SDK) is auto-loaded into every session via the `@`-import below. Always prefer those bundled docs over training memory.

@~/.claude/sui-pilot/agents/sui-pilot-agent.md

### Code Quality Workflow (MANDATORY)

After completing Move implementation, run `/move-code-quality` and iterate until the tool reports no issues. Treat the imported agent's "After Implementation" steps as the baseline; this rule strengthens it — do not skip the quality pass for non-trivial changes.

### Move.toml Configuration

```toml
[package]
name = "my_package"
edition = "2024"
```

## Plan Mode Behavior

When in plan mode, actively use the AskUserQuestion tool to clarify requirements, validate assumptions, and present implementation choices before finalizing the plan. Do not write a complete plan without first gathering input through structured questions. Prefer interactive refinement over monologue-style planning.
