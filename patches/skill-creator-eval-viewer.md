# Local patches: skill-creator plugin eval viewer

Applied 2026-08-06 to the installed plugin cache at
`~/.claude/plugins/cache/claude-plugins-official/skill-creator/unknown/skills/skill-creator/eval-viewer/`.
A plugin update overwrites the cache and reverts both fixes — re-apply from
this note (or upstream them) when the viewer breaks again the same way.

## 1. `generate_review.py` — `</script>` breaks the embedded data

The viewer embeds all run outputs as JSON inside a `<script>` tag. Any output
file containing a literal `</script>` (self-contained HTML deliverables with
inline JS) terminates that tag mid-payload; the browser then parses the rest
of the JSON as markup and the page renders garbage.

Fix — escape `</` in the serialized JSON (byte-identical after `JSON.parse`):

```python
# before
data_json = json.dumps(embedded)
# after
data_json = json.dumps(embedded).replace("</", "<\\/")
```

## 2. `viewer.html` — no preview for HTML output files

`.html` outputs rendered as raw `<pre>` source (only markdown/image/pdf had
render branches). Added a branch BEFORE the `file.type === "text"` markdown
branch, in the output-file rendering loop:

```js
if (file.type === "text" && /\.html?$/i.test(file.name)) {
  const iframe = document.createElement("iframe");
  iframe.sandbox = "allow-scripts";
  iframe.srcdoc = file.content;
  const raw = document.createElement("pre");
  raw.textContent = file.content;
  raw.style.display = "none";
  const toggle = document.createElement("span");
  toggle.className = "md-toggle";
  toggle.textContent = "View source";
  let showingRaw = false;
  toggle.addEventListener("click", () => {
    showingRaw = !showingRaw;
    iframe.style.display = showingRaw ? "none" : "";
    raw.style.display = showingRaw ? "" : "none";
    toggle.textContent = showingRaw ? "View preview" : "View source";
  });
  header.appendChild(toggle);
  content.appendChild(iframe);
  content.appendChild(raw);
} else if (file.type === "text") {   // original branch continues unchanged
```

The existing `.output-file-content iframe` CSS (100% width, 600px height)
already covers the preview sizing.
