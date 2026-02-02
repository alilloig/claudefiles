---
name: technical-docs-to-learning-materials
description: |
  Transform technical documentation (official docs, reference material, specs)
  into structured educational content that highlights key concepts and orders
  them for progressive learning. Use when: (1) turning reference docs into
  bootcamp or workshop reading material, (2) distilling dense documentation
  into approachable guides for students, (3) creating a module with an index
  and one or more focused topic guides, (4) simplifying any technical subject
  into its essential concepts ordered for maximum clarity. Covers content
  decomposition, concept prioritization, progressive structure, and formatting
  choices for educational clarity.
author: Claude Code
version: 2.0.0
date: 2026-01-30
---

# Technical Docs to Learning Materials

## Problem

Technical documentation is structured for lookup -- alphabetical, exhaustive,
reference-oriented. Learning requires the opposite: progressive disclosure,
concept prioritization, and a narrative arc that builds understanding step by
step. This skill covers how to transform any technical documentation into
written guides that students actually want to read.

## Context / Trigger Conditions

- The user has reference documentation, official docs, or specs as input
- The output should teach, not just inform
- The material targets students, workshop attendees, or onboarding readers
- Dense documentation needs to be distilled into its essential concepts
- Multiple related topics need to be organized into a coherent module

## Solution

### 1. Identify the Essential Concepts

Read the source documentation and extract the concepts that matter most. Not
everything in a reference doc belongs in a learning guide. Apply these filters:

- **Would a beginner need this?** If it's an edge case or advanced override,
  cut it or move it to an "Advanced" section at the end.
- **Does this unlock other concepts?** Foundational ideas come first.
- **Is this actionable?** Prefer concepts the student will use over trivia.

Aim for 60-70% of the source material's breadth. The goal is coverage of what
matters, not completeness.

### 2. Order for Progressive Understanding

Arrange concepts so each one builds on the previous:

1. **What** -- define the thing (1-2 sentences, no jargon yet)
2. **Why** -- motivation (answer "why should I care?")
3. **How** -- mechanics (the core model, flow, or structure)
4. **Rules** -- constraints, requirements, gotchas
5. **Variations** -- alternatives, advanced options, edge cases

This mirrors how people naturally learn: name it, justify it, explain it,
bound it, then expand it.

### 3. Structure the Output

For a module with multiple topics, use a two-layer structure:

| Layer | File | Purpose |
|---|---|---|
| Index | `README.md` | Navigation hub -- one-liner per topic, links to guides |
| Guides | `topic_name.md` | One file per topic, carries the conceptual weight |

The index should be 5-15 lines. It tells the reader what the module covers
and where to find each piece. Nothing more.

Each guide is self-contained: a reader should be able to open one guide and
understand the topic without reading the others (though they may reference
each other).

### 4. Write Each Guide

Within a single guide, use these formatting principles:

**Opening paragraph:** 1-2 sentences that define the topic and state why it
matters. No headings yet -- just prose that orients the reader.

**Sections follow the progressive order** (What/Why/How/Rules/Variations).
Not every section needs an explicit heading -- short topics can flow naturally.
Long topics benefit from clear `##` section breaks.

**Formatting choices by content type:**

| Content Type | Best Format |
|---|---|
| Binary comparisons (yes/no, allowed/forbidden) | Table with two columns |
| Sequential processes or flows | Numbered list |
| Feature inventories or option lists | Bullet list |
| Syntax or configuration | Fenced code block |
| Key terms with definitions | Bold term followed by dash and explanation |
| Important caveats | Blockquote |

**Keep paragraphs short.** 2-4 sentences max. Dense walls of text lose
students. White space is a teaching tool.

**Use concrete examples** over abstract descriptions. "A package bundles
modules into a single on-chain object" is better than "packages are the
primary unit of code organization."

### 5. Manage Depth vs. Breadth

For each section, decide its depth tier:

- **Essential** (every student needs this): Full explanation with examples.
  This is the core of the guide.
- **Important** (most students benefit): Concise explanation, maybe one
  example. A solid paragraph or a short subsection.
- **Advanced** (power users only): Brief mention with a link to official
  docs for the full story. One or two sentences.

Label advanced sections explicitly (use a heading like "Advanced Features"
or "Further Details") so students know they can skip them on first read.

### 6. Link to Official Docs

Every guide should end with a "Further Reading" section linking to the
original documentation. The guide is a distillation, not a replacement.
Students who want the full reference should know where to find it.

Use descriptive link text (not "click here"):
```markdown
## Further Reading

- [Package Upgrades Documentation](https://docs.example.io/upgrades)
- [Compatibility Requirements](https://docs.example.io/upgrades#compatibility)
```

### 7. Self-Review Checklist

Before considering a guide complete, verify:

- [ ] Opens with a clear definition and motivation (no heading-first starts)
- [ ] Concepts build progressively -- no forward references to unexplained ideas
- [ ] Tables used for comparisons, lists for sequences, prose for narrative
- [ ] No section exceeds ~1 page of content (split if longer)
- [ ] Advanced material is clearly labeled and deferrable
- [ ] Further Reading section links to original source docs
- [ ] Terminology is consistent across all guides in the module
- [ ] Index README links resolve to actual files

## Example

**Input:** Official documentation covering package management and package
upgrades for a blockchain platform (50+ pages of reference material).

**Output:**
```
H1/
  README.md                # Index: one-liner + link per topic
  package_management.md    # Guide: what a package is, manifest, deps, CLI
  package_upgrades.md      # Guide: why upgrades, flow, rules, patterns
```

`README.md` (entire file):
```markdown
# Package Management & Upgrades

## Contents

### [Package Management](./package_management.md)
How packages are structured, configured, and published.

### [Package Upgrades](./package_upgrades.md)
How to safely upgrade published packages while preserving state.
```

`package_management.md` structure:
1. Opening paragraph defining what a package is
2. Package files (table: file → purpose)
3. Manifest structure (code block + field explanations)
4. Dependency types (subsections with examples)
5. Advanced features (brief, links to docs)
6. CLI commands (table: command → description)
7. Further Reading (links)

## Notes

- Resist the urge to include everything from the source docs. A guide that
  covers 70% of topics clearly is more valuable than one that covers 100%
  with no hierarchy.
- When two topics are tightly related but distinct, give them separate files
  rather than one long file. Shorter, focused guides are less intimidating.
- The same source material may produce different guides depending on the
  audience. A workshop for beginners needs more "Why" and less "Variations"
  than an advanced masterclass.
- If the source documentation is poorly organized, don't mirror its structure.
  Reorganize around the learner's journey, not the author's taxonomy.
