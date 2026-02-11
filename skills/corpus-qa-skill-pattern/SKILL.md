---
name: corpus-qa-skill-pattern
description: |
  Architectural pattern for building Claude Code skills that answer questions
  from a large structured document corpus (course content, documentation sites,
  knowledge bases). Use when: (1) creating a Q&A skill over 50+ markdown files,
  (2) building a skill that searches a multi-module/multi-section repository,
  (3) implementing cited answers from a document collection. Covers the two-file
  pattern (CONTENT_MAP + SKILL.md), parallel multi-agent search, citation
  formatting, fallback handling, and common pitfalls.
author: Claude Code
version: 1.0.0
date: 2026-02-06
---

# Corpus Q&A Skill Pattern

## Problem
When a repository contains a large, structured document corpus (50+ files across
multiple directories), building a skill that accurately answers questions with
citations requires more than just Grep. Naive full-repo searches are slow, return
irrelevant matches, and can't distinguish between a topic's primary source and a
passing mention.

## Context / Trigger Conditions
- You need to build a Claude Code skill that answers user questions from a body of
  structured documents (course modules, documentation, knowledge base)
- The corpus has 50+ markdown files across multiple directories
- Answers must cite specific source files
- Questions may be broad (requiring refinement) or specific (direct answer)
- The skill should handle "not found" for topics outside the corpus

## Solution

### Architecture: Two-File Pattern

Create two files in the skill directory:

**1. CONTENT_MAP.md** — Pre-built topic-to-file index
- Organized by *thematic category* (not by directory structure)
- Each entry: topic name + specific file paths where content lives
- Cross-references topics that span multiple directories
- Includes all file categories: content, hands-on, instructor guides, quizzes

**2. SKILL.md** — Agent behavior definition with 4-step workflow:
1. **Question Refinement** (AskUserQuestion for broad questions, skip for specific)
2. **Content Map Lookup** (read CONTENT_MAP.md, identify 2-4 target files)
3. **Parallel Multi-Agent Search** (3 Explore agents via Task tool in single message)
4. **Answer Construction** (synthesize with citations, handle "not found")

### Agent Specialization

Spawn 3 agents with complementary roles:
- **concepts-agent**: Theory, definitions, architecture, key numbers
- **hands-on-agent**: CLI commands, code snippets, step-by-step procedures
- **navigator-agent**: Course structure, learning objectives, prerequisites, cross-refs

Each agent receives: the refined question, specific file paths from the map, repo root,
and instructions to report findings with exact paths + section headings.

### Citation Format

Use a consistent format like: `*(Module X: Title → filename.md)*`
Define a reference table of canonical titles in SKILL.md to prevent drift.

### Fallback Chain

```
CONTENT_MAP match → Targeted agent search → Broad Grep (**/*.md) → "Not found" response
```

## Verification

Test with these question types:
1. **Specific question** — Should produce direct answer with correct citation
2. **Broad question** — Should trigger AskUserQuestion refinement
3. **Ambiguous question** — Should disambiguate (e.g., "CLI or SDK?")
4. **Cross-cutting question** — Should cite multiple modules
5. **Off-topic question** — Should return "not found" response
6. **Navigation question** — Should list where topics are covered

For each test: verify cited file paths exist AND contain the claimed content.

## Example

See the walrus-qa skill in this project:
- `.claude/skills/walrus-qa/SKILL.md`
- `.claude/skills/walrus-qa/CONTENT_MAP.md`

## Notes

### Critical Pitfalls (Discovered During Implementation)

1. **Fallback glob scope**: Don't use `**/contents/*.md` — it misses files outside
   `contents/` directories (flat modules, root-level files, quizzes). Use `**/*.md`
   for the fallback search to catch all edge cases.

2. **Title consistency**: The CONTENT_MAP, SKILL.md's citation examples, and the
   module title reference table MUST use identical names. Inconsistency causes citation
   drift where agents produce citations that don't match expected format. Fix: define
   a single title reference table in SKILL.md and align CONTENT_MAP to it.

3. **Missing cross-reference entries**: Topics that span multiple modules (like "retry
   patterns" appearing in both SDK and Failure Handling) need entries in BOTH relevant
   CONTENT_MAP sections. Test by searching for the topic with Grep and comparing
   results against map entries.

4. **Non-standard directory structures**: Real repos have inconsistencies (some modules
   flat, others nested; some with `contents/`, others without). The CONTENT_MAP must
   account for these — validate EVERY path against the actual filesystem.

5. **"No map match" handling**: The skill must explicitly handle the case where
   CONTENT_MAP has no entry for a topic. Instruction: skip agent spawning entirely
   and go straight to the fallback Grep search.

6. **Deletable topics**: Common operations (delete, extend, share) often cross-cut
   many modules. If Grep finds 30+ files mentioning a term but the CONTENT_MAP has no
   dedicated entry, add one with the 2-3 most relevant source files.

### Building the CONTENT_MAP

1. Read every module's README.md and index.md for learning objectives and chapter lists
2. Read chapter headings (H1/H2) from each content file
3. Organize by theme, not by module number
4. Include instructor guides — they contain common Q&A
5. Validate every path with Glob after writing
6. Total effort: ~85 files takes one thorough Explore agent pass

### Performance

Reading CONTENT_MAP first narrows searches from ~100 files to ~5-10 targets.
Three parallel agents then search simultaneously. Expected time: 30-60 seconds
per question (vs. 2-3 minutes for full-repo search).
