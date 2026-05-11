---
name: Don't create a rigid /html skill
description: When migrating document-producing workflows to HTML, keep guidance flexible — the article author explicitly warns against locking Claude into a fixed HTML template skill
type: feedback
---

Do NOT create or propose a new `/html` skill (or any rigid "always produce HTML this exact way" skill) when migrating document-producing workflows to HTML. Migrate by adding flexible "HTML Output Conventions" sections to existing per-task skills, and let the global CLAUDE.md preference do the rest.

**Why:** Thariq Shihipar's article (the source of Alvaro's HTML-over-markdown preference) explicitly says: *"I'm a little bit afraid that people will read this article and turn it into a /html skill or something. While there might be some value in that, I want to emphasize that you don't need to do much to get Claude to do this. You can just ask it to 'make a HTML file' or 'make a HTML artifact'."* When the May 2026 migration of Alvaro's skills was planned, we deliberately reflected this — each migrated SKILL.md got a flexible "HTML Output Conventions" section, not a locked template.

**How to apply:** If asked to create an HTML skill, or to extract HTML conventions into a shared/reusable skill, push back first — propose adding the guidance to the relevant per-task skill or to CLAUDE.md instead. Only build a dedicated skill if the user pushes back with a concrete reason that overrides Thariq's caution.
