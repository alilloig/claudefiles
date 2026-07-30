# Global Claude Code Guidelines

## Tooling defaults

- **TypeScript** over JavaScript — always `.ts`/`.tsx`
- **pnpm** — never npm or yarn
- Stack choices (frameworks, chains, languages) are per-project: define them
  in each project's own CLAUDE.md — when starting or adopting a project,
  write its preferred stack there (create the file if missing) rather than
  assuming global defaults

## Communication

- Truly concise, tl;dr by default — answer in a few sentences leading with the
  conclusion; never pad with process narration or restated context. If an
  answer genuinely can't fit that shape (deep explanations, multi-part
  analysis), keep the chat reply to the tl;dr and put the full version in an
  HTML artifact instead of a long chat message.
- Prefer asking over assuming — when a decision hinges on my intent or taste
  (scope, approach, design direction, priorities), use the AskUserQuestion
  tool with concrete options rather than guessing. Don't overdo it: technical
  judgment calls, implementation details, and creative choices are yours to
  make; ask when my answer would change what you build, not to seek permission.
- Spanish-friendly — user is native Spanish speaker, switch freely if helpful
- **ASD-STE100 Simplified Technical English** for scoped work — when the task
  is well-defined (implementing, fixing, reviewing, reporting status,
  explaining a specific change), write in STE style: active voice; present
  tense unless another tense is necessary; one topic per sentence; max ~20
  words per instruction sentence, ~25 per descriptive sentence; max 6
  sentences per paragraph; no idioms, phrasal verbs, or slang; use one word
  with one meaning throughout. Code identifiers, commands, error text, and
  quoted output are Technical Names — keep them verbatim, exempt from STE
  rules. Open-ended work — researching, brainstorming, exploring options,
  thinking out loud — uses normal language; switch to STE once the work
  converges on a concrete task. Non-technical conversation is unaffected.

## Deliverables

A "deliverable" = any document meant for review: report, audit, plan, review,
analysis, explainer, design doc. Not throwaway snippets or code-only output.

- Deliverables ship as self-contained HTML; markdown only for short chat
  replies and code-only outputs
- No specialized skill fits → `html-artifact`; share only via `publish-html`,
  never auto-publish
- End the turn with a clickable Vlervcode deep-link to every deliverable,
  unprompted:
  - Form: `[<filename or short title>](vlerv://open?path=<abs path>)` — never
    a bare URL. Finicky hands it to the running Vlervcode app.
  - Encode everything outside RFC 3986 unreserved chars (`A-Za-z0-9-_.~`);
    slashes become `%2F`
  - Fallback: plain path or `file://` when Vlervcode doesn't apply, or the
    user asked for a different app
