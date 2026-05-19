# HTML Output Conventions

The canonical format for `findings-render-html` output. Vendored (distilled) from `sui-pilot:move-pr-review/SKILL.md` lines 277–294.

## Constraints

- Single self-contained `.html` file. No external CSS, no external JS, no CDN dependencies, no images requiring network access.
- No JavaScript. Reports are static documents.
- No syntax-highlighter dependencies. Plain `<pre><code>` for code blocks.
- No gradients, glass-morphism, or emoji. Professional palette.

## Document skeleton

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>PR #<N> — <repo> Review (<head-sha>)</title>
  <style>/* inline; see styling rules below */</style>
</head>
<body>
  <header>
    <h1>PR #<N>: <title></h1>
    <dl>
      <dt>Repo</dt><dd><owner/repo></dd>
      <dt>Branch</dt><dd><head-branch> → <base-branch></dd>
      <dt>HEAD commit</dt><dd><code><head-sha></code></dd>
      <dt>Dep pins</dt><dd>...</dd>
      <dt>Reviewed</dt><dd><date> · <reviewer-count> reviewers</dd>
    </dl>
  </header>

  <nav>
    <ul>
      <li><a href="#headline">Headline</a></li>
      <li><a href="#summary">Executive summary</a></li>
      <li><a href="#tally">Severity tally</a></li>
      <li><a href="#critical">Critical findings</a></li>
      <li><a href="#high">High findings</a></li>
      <li><a href="#medium">Medium findings</a></li>
      <li><a href="#low">Low findings</a></li>
      <li><a href="#info">Info</a></li>
      <li><a href="#methodology">Methodology</a></li>
    </ul>
  </nav>

  <main>
    <section id="headline"><h2>Headline</h2>...</section>
    <section id="summary"><h2>Executive summary</h2>...</section>
    <section id="tally"><h2>Severity tally</h2><table>...</table></section>

    <section id="critical">
      <h2>Critical findings</h2>
      <article class="finding critical">
        <header>
          <span class="id">C001</span>
          <h3>...</h3>
          <span class="severity badge">CRITICAL</span>
          <span class="agreement">7/10</span>
          <span class="category">access-control</span>
        </header>
        <dl>
          <dt>File</dt><dd><code>...</code></dd>
          <dt>Lines</dt><dd>...</dd>
          <dt>Found</dt><dd><pre><code>...evidence quote...</code></pre></dd>
          <dt>Required</dt><dd>...recommendation...</dd>
          <dt>Verified-by-consolidator</dt><dd>yes / downgraded / rejected</dd>
        </dl>
        <details><summary>Adversary path</summary>
          ...concrete attacker scenario...
        </details>
      </article>
      <!-- more findings -->
    </section>

    <!-- repeat sections for high / medium / low / info -->

    <section id="methodology">
      <h2>Methodology</h2>
      <ul>
        <li>Reviewer count: ...</li>
        <li>Coverage: ...</li>
        <li>Clusters before/after split: ...</li>
        <li>Verification pass: ... critical/high re-derived</li>
        <li>Fallback dispatches: ... (lists subagents that fell back to general-purpose)</li>
      </ul>
    </section>
  </main>
</body>
</html>
```

## Styling rules

- System-font stack (`-apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`).
- Max content width ~80–90ch; comfortable line-height (1.55).
- Mobile-responsive via `@media (max-width: 720px)`.
- Severity badge colors (muted, professional):
  - `.critical` — `#b91c1c` on `#fee2e2`
  - `.high` — `#c2410c` on `#ffedd5`
  - `.medium` — `#854d0e` on `#fef9c3`
  - `.low` — `#3730a3` on `#e0e7ff`
  - `.info` — `#374151` on `#f3f4f6`
- Article borders match severity color, light tint.
- `<code>` and `<pre>` use a monospace stack and a 1-line padding.
- Escape `<` and `>` in cited code (especially in Move generics).

## Required sections

In order:
1. Header (title + PR/commit/dep metadata)
2. Headline (1–3 sentences: approve / approve-with-changes / block; top 1–2 code findings)
3. Executive summary (6–10 bullets)
4. Severity tally (count + change-from-raw if applicable)
5. Findings — Critical
6. Findings — High
7. Findings — Medium
8. Findings — Low
9. Findings — Info
10. Methodology

## Optional sections (for Move PRs or where applicable)

- Integration-boundary notes (between Critical/High and Medium)
- Test & coverage plan (collapses `category: testing` findings into a single section, not per-finding HIGH/MEDIUM)
- Build reproducibility & ops (collapses `category: build|versioning|scripts` into a single section)
- Appendices (per-reviewer stats, coverage matrix, artifacts index)
- Postscript (multi-agent workflow observations)

## GitHub PR comment companion

GitHub strips `<style>` and `<script>` from PR comments. The companion `pr-comment.md` is short markdown (≤ 20 lines) with:
- 1-line verdict
- Severity tally
- Top 3 findings (title + file:line + severity)
- Link to the local HTML report path

Never paste the full HTML into a PR comment.
