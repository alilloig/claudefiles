# PR comment template: short-tldr

Used by `findings-render-markdown --emit pr-comment` to render a ≤ 20-line markdown comment for `gh pr comment`.

GitHub strips `<style>` and `<script>` from PR comments — never paste the full HTML report here. Link to it instead.

Placeholders:
- `{VERDICT}` — `Approve`, `Approve with changes`, or `Block`
- `{SEV_CRITICAL}` / `{SEV_HIGH}` / `{SEV_MEDIUM}` / `{SEV_LOW}` / `{SEV_INFO}` — finding counts per severity
- `{REVIEWER_COUNT}` — total reviewers in the fan-out
- `{TOP_3}` — top 3 findings (title + file:line + severity), bullet-formatted
- `{HTML_REPORT_PATH}` — absolute path to the rendered `review.html` (so the local viewer / Vlervcode link works)
- `{METHODOLOGY_SUMMARY}` — 1-line summary (e.g. "3 reviewers, hybrid routing, 0 fallbacks")
- `{FALLBACK_NOTE}` — empty string OR a 1-line callout if any specialist fell back to general-purpose

---

**Verdict: {VERDICT}**

Multi-agent review by {REVIEWER_COUNT} reviewers. {METHODOLOGY_SUMMARY}.

**Severity tally**

| Critical | High | Medium | Low | Info |
|---|---|---|---|---|
| {SEV_CRITICAL} | {SEV_HIGH} | {SEV_MEDIUM} | {SEV_LOW} | {SEV_INFO} |

**Top findings**

{TOP_3}

{FALLBACK_NOTE}

Full review: `{HTML_REPORT_PATH}` (open with Vlervcode for inline navigation).
