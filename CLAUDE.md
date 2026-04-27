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
