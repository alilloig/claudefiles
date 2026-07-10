# Handoff note — for the memory-consolidation session

**From:** the 2026-07-10 dotclaude cleanup session ("dotclaude").
**To:** the session cleaning up all memories.

This directory (`~/.claude/memory/`, git-tracked in dotclaude) predates the
native per-project memory system described in `~/workspace/CLAUDE.md`
(one-fact-per-file + `MEMORY.md` index under
`~/.claude/projects/<encoded-path>/memory/`, gitignored, to be synced via
Walrus).

During the cleanup we deliberately left it alone so your consolidation pass
can decide its fate. Options on the table:

1. **Fold** the two content files (`feedback_no_rigid_html_skill.md`,
   `reference_html_articles.md`) into the appropriate native per-project
   memory (they look like global/user-level facts, so probably the dotclaude
   project's own memory or wherever global facts land in the new scheme),
   then `git rm -r memory/` from dotclaude.
2. **Keep** this dir as the intentional cross-machine-synced memory location
   — if so, document that in dotclaude's README so it stops looking like a
   relic.

Either way, delete this note when done. Context: the cleanup session's other
decisions are recorded in the dotclaude project memory
(`project_plugin_policy.md`).
