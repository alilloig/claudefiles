---
name: cli-documentation-verification
description: |
  Verify CLI tool documentation (course materials, READMEs, cheatsheets) against the
  actual installed CLI binary. Use when: (1) auditing course or tutorial materials for
  accuracy against a specific CLI version, (2) a CLI tool has been updated and docs may
  have drifted, (3) you need to distinguish between canonical flags, hidden aliases, and
  truly nonexistent options. Covers Rust Clap alias detection, hidden flag discovery,
  and systematic --help cross-referencing methodology. Produces a self-contained HTML
  verification report with severity-tagged discrepancies and recommended fixes.
author: Claude Code
version: 1.0.0
date: 2026-02-04
---

# CLI Documentation Verification

## Problem

Documentation for CLI tools (tutorials, cheatsheets, course materials) drifts out of sync
with the actual CLI as the tool evolves. Flags get renamed, removed, or hidden. Subcommands
change. Simply grepping `--help` output is insufficient because CLI frameworks like Clap
(Rust) silently accept aliases and hidden flags that don't appear in help text.

## Context / Trigger Conditions

- Auditing course materials, tutorials, or cheatsheets against a specific CLI version
- A CLI tool has released new versions since documentation was written
- Users report commands from docs not working
- You need to verify whether a flag is canonical, an alias, or nonexistent

## Solution

### Phase 1: Extract all commands from documentation

```bash
# Find all CLI invocations in docs (adjust tool name)
rg '^\s*<tool>\s+[a-z]' --line-number  # freestanding commands
rg '`<tool>\s+[a-z]' --line-number     # inline code references
```

### Phase 2: Verify subcommands exist

```bash
# Get canonical subcommand list
<tool> --help 2>&1 | grep '^  [a-z]' | awk '{print $1}'

# Test each subcommand from docs
<tool> <subcommand> --help 2>&1
# Exit code 0 = exists, exit code 2 = doesn't exist
```

### Phase 3: Verify flags — the critical nuance

**Do NOT just grep `--help` output.** This misses Clap aliases and hidden flags.

Instead, test each flag directly:

```bash
# Test if a flag is accepted (even if not in --help)
<tool> <subcommand> --<flag> 2>&1
```

Interpret the output:

| CLI Response | Meaning |
|---|---|
| "unexpected argument '--flag'" | Flag truly doesn't exist |
| "a value is required for '--other-flag'" | Flag is an alias for `--other-flag` |
| Proceeds to run (or asks for other required args) | Flag is accepted (canonical or hidden) |
| "a similar argument exists: '--similar'" | Flag doesn't exist but CLI suggests the correct one |

### Phase 4: Classify each discrepancy

| Category | Description | Action |
|---|---|---|
| **Breaking** | CLI rejects the flag/subcommand entirely | Must fix in docs |
| **Alias** | CLI accepts it but maps to a different canonical name | Should update to canonical form |
| **Hidden/deprecated** | CLI accepts it but it's not in `--help` | Should remove from docs, explain new behavior |
| **No-op** | CLI accepts it but it does nothing | Should remove from docs, explain why |

## Key Insight: Rust Clap Alias Behavior

Rust's `clap` argument parser provides **automatic prefix-matching** for long options:

- A struct field named `blob_ids` registers `--blob-ids` as canonical
- Clap silently accepts `--blob-id` as an unambiguous prefix match
- These aliases **do not appear in `--help` output**
- Error messages reveal the canonical form: `"a value is required for '--blob-ids'"`

Similarly, Clap supports `#[arg(hide = true)]` for backwards-compatible hidden flags:
- The flag works but doesn't appear in `--help`
- Useful for deprecated flags kept for backwards compatibility
- Only discoverable by testing directly

## Phase 5: Report

Write a single self-contained HTML file (`cli-doc-verification.html` in the project root unless the user specifies otherwise). Skeleton:

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>CLI Documentation Verification — {tool} {version}</title>
  <style>/* inline CSS — see HTML Output Conventions below */</style>
</head>
<body>
  <header>
    <h1>CLI Documentation Verification</h1>
    <p class="subtitle">Tool: <code>{tool}</code> · Version: <code>{version}</code> · Audited: <time datetime="…">…</time></p>
  </header>

  <nav aria-label="Contents">
    <ul>
      <li><a href="#summary">Summary</a></li>
      <li><a href="#breaking">Breaking discrepancies</a></li>
      <li><a href="#aliases">Aliases</a></li>
      <li><a href="#hidden">Hidden / deprecated</a></li>
      <li><a href="#noop">No-op</a></li>
      <li><a href="#methodology">Methodology</a></li>
    </ul>
  </nav>

  <main>
    <section id="summary">
      <h2>Summary</h2>
      <table>
        <thead><tr><th>Category</th><th>Count</th></tr></thead>
        <tbody>
          <tr class="breaking"><td>Breaking</td><td>X</td></tr>
          <tr class="alias"><td>Alias</td><td>Y</td></tr>
          <tr class="hidden"><td>Hidden / deprecated</td><td>Z</td></tr>
          <tr class="noop"><td>No-op</td><td>W</td></tr>
        </tbody>
      </table>
    </section>

    <section id="breaking">
      <h2>Breaking discrepancies</h2>
      <!-- one <article class="finding breaking"> per item -->
      <article class="finding breaking" id="breaking-1">
        <header>
          <h3>{doc location}</h3>
          <span class="severity">BREAKING</span>
        </header>
        <dl>
          <dt>Found in docs</dt><dd><pre><code>walrus delete --blob-obj-id …</code></pre></dd>
          <dt>CLI response</dt><dd><pre><code>unexpected argument '--blob-obj-id'…</code></pre></dd>
          <dt>Canonical form</dt><dd><pre><code>walrus delete --shared-blob-obj-id …</code></pre></dd>
        </dl>
        <details>
          <summary>Fix</summary>
          <p>Update the docs at {file:line} to use the canonical flag name.</p>
        </details>
      </article>
    </section>

    <section id="aliases">  <h2>Aliases</h2>   <!-- same shape, class="alias" -->  </section>
    <section id="hidden">   <h2>Hidden / deprecated</h2>   <!-- same shape, class="hidden" -->  </section>
    <section id="noop">     <h2>No-op</h2>                  <!-- same shape, class="noop" -->     </section>

    <section id="methodology">
      <h2>Methodology</h2>
      <p>Commands extracted via <code>rg</code>; each subcommand and flag tested directly against the installed binary; CLI responses interpreted per the four-category table in this skill.</p>
    </section>
  </main>
</body>
</html>
```

## Verification (after writing the report)

1. Re-run the full extraction sweep to confirm no old patterns remain
2. Exclude upstream/imported docs from fixes (only fix what you authored)
3. Test each fixed command against the CLI to confirm the new form works

## Example

```bash
# Documentation says: walrus delete --blob-id <ID>
# Step 1: Check --help
walrus delete --help 2>&1 | grep 'blob-id'
# Shows: --blob-ids <BLOB_IDS>  (plural!)

# Step 2: Test the documented form directly
walrus delete --blob-id abc123 2>&1
# Output: "invalid value 'abc123' for '--blob-ids <BLOB_IDS>'"
# Interpretation: --blob-id is accepted as a Clap alias for --blob-ids

# Step 3: Test a truly wrong flag
walrus fund-shared-blob --blob-obj-id 2>&1
# Output: "unexpected argument '--blob-obj-id', tip: a similar argument exists: '--shared-blob-obj-id'"
# Interpretation: This flag truly doesn't exist — must fix in docs
```

## Notes

- When docs and official upstream reference material both use the old form, the alias may
  be intentional. Still update course materials to canonical form for pedagogical clarity.
- Exclude imported/upstream documentation from fixes — only fix what you author.
- Always record the CLI version being verified against for future reference.
- This methodology works for any Clap-based CLI (Rust ecosystem), and the general
  principle of testing flags directly applies to any CLI framework.

---

## HTML Output Conventions

**REQUIRED REFERENCE:** Use [html-artifact:html-conventions](../html-artifact/references/html-conventions.md) for the self-contained HTML output rules — semantic HTML5, inline CSS, no external assets, system-font stack, max-width ~80ch, mobile-responsive, no JavaScript.

Skill-specific conventions:

- **Severity classes** on `<tr>`/`<article>`: `breaking`, `alias`, `hidden`, `noop`. Tint with muted reds for breaking, muted ambers for alias, neutral greys for hidden/no-op. Keep contrast accessible.
- **Per-discrepancy `<article class="finding {category}">`** with a `<header>` (location + severity badge), a `<dl>` of metadata (Found in docs, CLI response, Canonical form), and `<details><summary>Fix</summary>…</details>` for the remediation.
- **Code blocks** must escape `<`/`>` in displayed CLI output — `<pre><code>` for multi-line, `<code>` inline.
