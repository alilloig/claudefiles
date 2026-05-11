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
  choices for educational clarity. Outputs a module of self-contained HTML
  files: one `index.html` plus one `.html` per topic, cross-linked via
  semantic anchor tags.
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

For a module with multiple topics, use a two-layer structure of self-contained HTML files:

| Layer | File | Purpose |
|---|---|---|
| Index | `index.html` | Navigation hub — one-liner per topic, `<a href="topic.html">` per guide |
| Guides | `topic_name.html` | One self-contained HTML file per topic, carrying the conceptual weight |

The index should be short — a `<header>`, a brief `<p>` describing the module, and a `<nav>`/`<ul>` of topic links each with a one-line `<p>` description. It tells the reader what the module covers and where to find each piece. Nothing more.

Each guide is self-contained: a reader should be able to open one guide and understand the topic without reading the others (though they may reference each other via `<a href="other_topic.html">`). Each guide opens with a small breadcrumb `<nav>` (`<a href="index.html">← Module index</a>`) and is otherwise standalone.

### 4. Write Each Guide

Within a single guide, use these formatting principles:

**Opening paragraph:** 1-2 sentences that define the topic and state why it
matters. No headings yet -- just prose that orients the reader.

**Sections follow the progressive order** (What/Why/How/Rules/Variations).
Not every section needs an explicit heading — short topics can flow naturally.
Long topics benefit from clear `<section id="…"><h2>…</h2></section>` breaks with a top-of-page `<nav>` linking to each.

**Formatting choices by content type:**

| Content Type | Best HTML |
|---|---|
| Binary comparisons (yes/no, allowed/forbidden) | `<table>` with two columns |
| Sequential processes or flows | `<ol>` |
| Feature inventories or option lists | `<ul>` |
| Syntax or configuration | `<pre><code>…</code></pre>` |
| Key terms with definitions | `<dl><dt>term</dt><dd>explanation</dd></dl>` |
| Important caveats | `<aside class="note">` or `<aside class="warning">` |
| Optional / advanced drill-down | `<details><summary>…</summary>…</details>` |
| Inline diagrams | inline `<svg>` |

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

```html
<section id="further-reading">
  <h2>Further Reading</h2>
  <ul>
    <li><a href="https://docs.example.io/upgrades">Package Upgrades Documentation</a></li>
    <li><a href="https://docs.example.io/upgrades#compatibility">Compatibility Requirements</a></li>
  </ul>
</section>
```

### 7. Self-Review Checklist

Before considering a guide complete, verify:

- [ ] Opens with a clear definition and motivation (no heading-first starts)
- [ ] Concepts build progressively — no forward references to unexplained ideas
- [ ] `<table>` used for comparisons, `<ol>`/`<ul>` for sequences/inventories, prose `<p>` for narrative
- [ ] No `<section>` exceeds ~1 page of rendered content (split if longer)
- [ ] Advanced material is clearly labeled and deferrable (`<section id="advanced">` or `<details>`)
- [ ] Further Reading `<section>` links to original source docs
- [ ] Terminology is consistent across all guides in the module
- [ ] `index.html` links resolve to actual `.html` files in the module dir
- [ ] Every guide opens with a breadcrumb `<nav>` back to `index.html`
- [ ] Each file is self-contained: valid `<!DOCTYPE html>`, inline `<style>`, no external CSS/JS

## Example

**Input:** Official documentation covering package management and package
upgrades for a blockchain platform (50+ pages of reference material).

**Output:**
```
H1/
  index.html                # Index: one-liner + link per topic
  package_management.html   # Guide: what a package is, manifest, deps, CLI
  package_upgrades.html     # Guide: why upgrades, flow, rules, patterns
```

`index.html` (sketch):
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Package Management &amp; Upgrades</title>
  <style>/* inline CSS — see HTML Output Conventions below */</style>
</head>
<body>
  <header><h1>Package Management &amp; Upgrades</h1></header>
  <main>
    <nav aria-label="Module contents">
      <ul>
        <li>
          <a href="package_management.html"><strong>Package Management</strong></a>
          <p>How packages are structured, configured, and published.</p>
        </li>
        <li>
          <a href="package_upgrades.html"><strong>Package Upgrades</strong></a>
          <p>How to safely upgrade published packages while preserving state.</p>
        </li>
      </ul>
    </nav>
  </main>
</body>
</html>
```

`package_management.html` structure:
1. Breadcrumb `<nav>` back to `index.html`
2. Opening `<p>` defining what a package is
3. Package files (`<table>`: file → purpose)
4. Manifest structure (`<pre><code>` + field `<dl>`)
5. Dependency types (`<section>`s with examples)
6. Advanced features (`<section id="advanced">` or `<details>`, brief, links to docs)
7. CLI commands (`<table>`: command → description)
8. Further Reading (`<section id="further-reading">` with `<ul>` of links)

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

---

## HTML Output Conventions

Every file (index and each guide) is a single self-contained `.html`:

- **Doctype & shell**: `<!DOCTYPE html>`, `<html lang="en">`, `<head>` with `<meta charset="utf-8">`, viewport meta, descriptive `<title>`, single inline `<style>` block. No external CSS/JS, no CDNs.
- **Cross-file navigation**: every guide opens with a breadcrumb `<nav>` containing `<a href="index.html">← Module index</a>`. Cross-references between guides use `<a href="other_topic.html">`. The index lists topics as `<a href="topic.html">`.
- **Semantic tags**: `<header>`, `<nav>`, `<main>`, `<section id="…">`, `<aside class="note">`/`<aside class="warning">`, `<figure>`/`<figcaption>`, `<footer>` if it carries content (e.g. last-updated date).
- **Content types** map per the "Formatting choices" table in step 4.
- **CSS style**: small inline stylesheet (kept identical across all files in the module so they feel like one site) — system-font stack, max-width ~70–80ch on prose, comfortable line-height, mobile-responsive via one `@media (max-width: 720px)` block. Avoid gradients, glass-morphism, emoji-decorated headers.
- **No JavaScript** unless a topic genuinely needs interactivity (e.g. a small interactive demo of the concept). Default to static.

When unsure how rich to go, lean on the examples at https://thariqs.github.io/html-effectiveness/.
