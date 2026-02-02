---
name: pdf-visual-to-css-svg
description: |
  Translates visual design from PDF decks, mockups, or screenshots into
  programmatic CSS themes and SVG assets. Use when: (1) converting a corporate
  slide deck or brand guide PDF into a Marp/CSS theme, (2) extracting design
  tokens (colors, fonts, spacing) from a visual reference, (3) creating SVG
  product illustrations to match a brand aesthetic, (4) building CSS layout
  classes that reproduce specific page layouts from a PDF. Covers the full
  pipeline: visual analysis → token extraction → CSS authoring → SVG creation
  → template assembly.
author: Claude Code
version: 1.0.0
date: 2026-01-29
---

# PDF Visual Design → Programmatic CSS & SVG

## Problem

Converting a visual design reference (PDF deck, brand guide, mockup) into
functional CSS themes and SVG assets requires a systematic process. Without
a structured approach, you end up with CSS that doesn't match the source,
inconsistent colors, and illustrations that clash with the brand.

## Context / Trigger Conditions

- User provides a PDF slide deck and wants it reproduced as a Marp theme
- User has a brand guide or design system and needs CSS + SVG assets
- Converting a visual reference into a Marpit-compliant CSS theme
- Creating geometric/isometric SVG product illustrations to match a dark/branded aesthetic
- Building a library of CSS layout classes from page-by-page analysis of a deck

## Solution

### Phase 1: Visual Analysis & Token Extraction

Examine each page of the PDF systematically. Extract a design token table:

```
| Token         | Value     | Source Page | Usage                    |
|---------------|-----------|-------------|--------------------------|
| Background    | #000000   | All pages   | Slide background         |
| Heading color | #FFFFFF   | All pages   | h1, h2, h3               |
| Body text     | #8B8B8B   | All pages   | Paragraphs, lists        |
| Accent        | #4DA2FF   | pp. 7-20    | Markers, links, badges   |
| Separator     | #3A3A3A   | pp. 7-11    | Dotted column borders    |
| Font family   | Inter     | All pages   | All text                 |
| Slide size    | 1280×720  | All pages   | 16:9 ratio               |
| Padding       | 60px      | All pages   | Content margin           |
```

Key technique: **page-by-page inventory**. Assign each unique layout a class name
and note which PDF page it corresponds to. Example:

```
| Page | Layout Name      | Description                              |
|------|-----------------|-------------------------------------------|
| 6    | lead            | Title slide, large h1 bottom-left         |
| 7    | cols-4          | 4 columns with blue markers + body        |
| 8    | cols-3          | 3-column variant                          |
| 14   | cols-4-icon     | 4 columns with product icons above h3     |
| 15   | cols-4-stats    | 4 columns with large stat numbers         |
```

### Phase 2: CSS Theme Authoring

Structure the CSS in this order:

1. **Theme metadata** (required for Marpit): `/* @theme theme-name */`
2. **Font import**: `@import url('https://fonts.googleapis.com/css2?family=...')`
3. **Base section**: background, color, font-family, font-size, padding, dimensions
4. **Typography**: h1-h4, p, strong, em, a, code, pre, lists, tables, hr
5. **Pagination**: `section::after` styling
6. **Footer/header**: absolute positioning
7. **Grid system**: `.grid`, `.col` reusable containers
8. **Layout classes**: one `section.classname` block per layout
9. **Product-specific classes**: hero slides and content slides per product
10. **Utility classes**: text alignment, colors, spacing

Key CSS techniques for reproducing PDF layouts:

- **CSS Grid** for multi-column layouts: `grid-template-columns: repeat(4, 1fr)`
- **Blue square markers**: `::before` pseudo-element with `width:8px; height:8px; background:#4DA2FF`
- **Dotted separators**: `border-top: 1px dashed #3A3A3A`
- **Product watermarks**: `::before` with large text, `font-size: 160px`, `color: rgba(255,255,255,0.03)`
- **Stat numbers**: dedicated `.stat` class with large font-size, white or accent color
- **Card containers**: subtle dark background `#0A0A0A` with `#1A1A1A` border

Important: For presentation tools like Marp, HTML `<div>` elements pass through
to the output. Layout classes require explicit `<div class="grid"><div class="col">`
wrappers in the markdown.

### Phase 3: SVG Asset Creation

For product/brand illustrations:

1. **Consistent viewBox**: Use `viewBox="0 0 200 200"` for all product SVGs
2. **Color palette**: Use only the brand's accent color (`#4DA2FF`) and white (`#FFFFFF`)
   with opacity variations
3. **Transparent background**: No background fill — assets sit on the CSS background
4. **Glow effect**: Add a `<filter>` with `<feGaussianBlur>` and `<feMerge>` for
   subtle luminosity on dark backgrounds:
   ```xml
   <defs>
     <filter id="glow">
       <feGaussianBlur stdDeviation="3" result="blur"/>
       <feMerge>
         <feMergeNode in="blur"/>
         <feMergeNode in="SourceGraphic"/>
       </feMerge>
     </filter>
   </defs>
   ```
5. **Geometric/abstract style**: Use basic shapes (circles, rects, polygons, paths)
   to suggest the product's purpose rather than literal depictions
6. **Gradient fills**: `<linearGradient>` or `<radialGradient>` from accent color
   at 0.5-0.7 opacity to 0.1-0.2 opacity
7. **Each SVG tells a story**: Shield = security, layers = DEX, hexagons = enclave,
   fingerprint = biometric auth, circuit = zero-knowledge

### Phase 4: Template Assembly

Create a self-contained template that embeds the CSS in a `<style>` block:

```markdown
---
marp: true
paginate: true
footer: "Brand Name"
---

<style>
/* Full CSS from Phase 2 goes here */
</style>

<!-- Example slide per layout class -->
```

Include one working example slide per layout class so the AI has a structural
reference when generating new decks.

### Phase 5: Reference Documentation

Create supporting reference files:
- **Best practices**: Adapted for the specific theme (colors, font sizes, dark bg contrast)
- **Layout selection guide**: Table mapping content types to recommended layout classes
- **Product slides guide**: Table of products with hero/content class pairs

## Verification

1. **CSS compliance**: File starts with `/* @theme name */` and loads via `marp --theme file.css`
2. **Render test**: `marp template.md --html` produces correct dark background, layouts, colors
3. **Product slides**: Hero slides show watermark text, content slides have split layout
4. **SVG rendering**: All SVGs display correctly on dark backgrounds with no white artifacts
5. **Self-contained**: Generated `.md` files include full `<style>` block and render without external files

## Example

Converting a Sui corporate deck (black background, blue accent, Inter font):

1. Analyzed 41-page PDF → extracted 6 design tokens + 15 generic layouts + 10 product variants
2. Created `sui-theme.css` (500+ lines) with `/* @theme sui */` metadata
3. Created 10 SVG product illustrations (200×200 viewBox, #4DA2FF palette, glow filters)
4. Assembled `template-sui.md` with embedded CSS + 25 example slides
5. Wrote SKILL.md with layout class reference + product slide tables

## Notes

- **Embedded vs. external CSS**: For Marp, embedding CSS in `<style>` makes generated files
  self-contained. Keep a separate `.css` file for `marp --theme` CLI usage.
- **HTML passthrough**: Marp passes `<div>` elements through to output. Layout classes
  require explicit HTML wrappers — this is standard Marp behavior, not a workaround.
- **Google Fonts in CSS**: `@import url(...)` works in Marp's `<style>` blocks. Include a
  fallback chain: `'Inter', 'SF Pro Display', -apple-system, sans-serif`.
- **Product watermarks via CSS only**: Use `::before` pseudo-elements with large low-opacity
  text instead of creating watermark images. This keeps the system pure CSS.
- **SVG filter IDs must be unique**: When multiple SVGs appear on the same page, filter IDs
  like `id="glow"` will collide. Prefix each with the product name: `id="seal-glow"`.
- **Stat numbers are HTML, not markdown**: `<div class="stat">390ms</div>` renders as styled
  stat text. Regular markdown `# 390ms` would use heading styles instead.

## References

- [Marpit Theme CSS specification](https://marpit.marp.app/theme-css)
- [Marp CLI documentation](https://github.com/marp-team/marp-cli)
- [SVG filter effects (MDN)](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/filter)
- [CSS Grid Layout (MDN)](https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout)
