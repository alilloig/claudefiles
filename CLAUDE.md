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
