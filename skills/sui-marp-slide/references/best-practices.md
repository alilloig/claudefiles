# Sui Marp Slide Creation Best Practices

Guidelines for creating high-quality presentation slides with the Sui corporate theme.

## Slide Titles (h1 / h2)

### Good Examples
- **Concise**: 3-6 words maximum
- **Clear**: Content is immediately understandable
- **Consistent**: Same style at the same hierarchy level

```markdown
# Core Infrastructure
# Network Performance
# Developer Experience
# Platform Overview
```

### Bad Examples
```markdown
# In this section we will explain the core infrastructure of Sui
# What are the challenges we are currently facing with blockchain adoption
```

## Bullet Points

### Good Examples
- **3-5 items**: Not too many per slide
- **Concise**: One line per point
- **Parallel**: Same grammatical structure at the same level

```markdown
- Sub-second finality
- Parallel transaction execution
- Object-centric storage model
```

### Bad Examples
```markdown
- The Sui blockchain uses a novel approach to consensus that enables transactions to be finalized in under one second
- Fast
- The next item is completely different in format. This inconsistency makes it hard to read and follow.
```

## Slide Structure

### Basic Structure

1. **Cover Slide** (`<!-- _class: lead -->`)
   - Presentation title
   - Subtitle or tagline
   - Date/presenter (optional)

2. **Overview Slide** (standard or `cols-4-minimal`)
   - Show overall structure
   - 3-5 key sections

3. **Content Slides** (use appropriate layout classes)
   - 1 slide = 1 message
   - Title summarizes the slide content
   - Select layout class that matches the content type

4. **Summary / Call-to-Action Slide** (`split-right` or standard)
   - Reconfirm key points
   - Next steps or CTA

### Recommended Slide Count

- 5-minute pitch: 5-8 slides
- 10-minute talk: 10-15 slides
- 20-minute presentation: 15-25 slides

## Text Amount

### Good Balance

```markdown
# Object Model

- Every asset is a first-class object
- Unique ownership semantics
- Composable across protocols
- Parallel execution by default
```

### Too Crowded

```markdown
# About the Sui Object Model

The Sui blockchain introduces a revolutionary approach to data modeling
that treats every digital asset as a first-class object with unique
ownership semantics. The main features include the following 7 points:
- Feature 1: Detailed explanation continues at length...
- Feature 2: Even more detailed explanation...
(Continued)
```

## Using Whitespace

- **Adequate whitespace**: Don't cram too much information
- **Visual guidance**: Layout that naturally draws eyes to important information
- **Breathing room**: Appropriate pauses between dense content slides
- **Dark background advantage**: On black backgrounds, whitespace (empty black space) creates natural visual separation

## Using Colors — Sui Design Tokens

Use only colors defined in the Sui theme:

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#000000` | All slides — pure black |
| Headings | `#FFFFFF` | h1, h2, h3, `<strong>` |
| Body text | `#8B8B8B` | Paragraphs, list items |
| Accent | `#4DA2FF` | Blue markers, pagination, links, `<em>` |
| Separator | `#3A3A3A` | Dotted lines above columns |
| Cards | `#0A0A0A` bg / `#1A1A1A` border | Card containers |

### Additional Color Emphasis

```markdown
*This renders in accent blue* (via `<em>` styling)
**This renders in white** (via `<strong>` styling)
```

Use `<span class="accent">text</span>` for inline blue accent. Avoid introducing additional colors — the constrained palette is intentional.

### Dark Background Contrast

On a pure black background:
- **Never** use dark gray text below `#666666` — it becomes unreadable
- **Body text** at `#8B8B8B` provides comfortable reading contrast
- **Headings** at `#FFFFFF` create clear visual hierarchy
- **Blue accent** `#4DA2FF` should be used sparingly for maximum impact
- **Images**: Prefer transparent-background PNGs or SVGs. Avoid images with white backgrounds — they will create jarring bright rectangles

## Using Images

### Effective Usage

- **Clear purpose**: To aid understanding, not just decoration
- **Dark-friendly**: Use images that work on black backgrounds
- **Transparent backgrounds**: Prefer SVGs and transparent PNGs
- **Appropriate size**: Neither too large nor too small

### Layout Tips

```markdown
<!-- Text on left, image on right -->
![bg right:40%](image.png)

- Point 1
- Point 2
```

For product slides, use the dedicated layout classes:
```markdown
<!-- _class: product-deepbook-content -->

<div class="content">

# DeepBook Protocol

Description and bullet points here.

</div>

<div class="illustration">

![](../assets/images/product-deepbook.svg)

</div>
```

## Layout Class Selection Guide

Match your content type to the right layout class:

| Content Type | Recommended Class | Notes |
|---|---|---|
| Title / cover | `lead` | Large h1, subtitle |
| 4 features or pillars | `cols-4` | Blue markers + body text |
| 3 key concepts | `cols-3` | Three equal columns |
| 2 comparisons | `cols-2-center` | Centered title |
| 4 categories with detail | `grid-2x2` | 2x2 grid |
| 4 headlines only | `cols-4-minimal` | No body text |
| Full image | `fullbleed` | No padding |
| 4 products with icons | `cols-4-icon` | Icon above headline |
| Key metrics (4) | `cols-4-stats` | Large numbers |
| Narrative + stats | `stats-side` | Left story, right numbers |
| Big headline numbers | `stats-left` | Large stacked stats |
| Statement / quote | `split-right` | Right-aligned |
| Feature list | `list-right` | Cards on right |
| Product showcase (8) | `grid-products` | 4x2 with icons |
| Image gallery | `grid-images` | 4x2 image grid |
| Product introduction | `product-{name}` | Hero slide with watermark |
| Product deep-dive | `product-{name}-content` | Split with illustration |

## Font Size Guidelines

Defined in the Sui theme:
- h1: `42px` (standard) / `64px` (lead) / `56px` (product hero)
- h2: `32px`
- h3: `24px`
- Body text: `22px`
- Stat numbers: `48px` (standard) / `56px` (cols-4-stats) / `72-80px` (stats-left)
- Small text: `16px`
- Footer/header: `14px`

## Animations and Transitions

Marp does not support animations by default. Focus on clear slide progression and visual hierarchy through layout variation.

## Quality Checklist

After completing slides, verify:

- [ ] Are titles concise (3-6 words)?
- [ ] Are bullet points 3-5 items per slide?
- [ ] Is it 1 slide = 1 message?
- [ ] Is the text amount appropriate for 16:9 format?
- [ ] Is there sufficient black space (whitespace on dark bg)?
- [ ] Are images optimized for dark backgrounds?
- [ ] Is there overall visual consistency?
- [ ] Is the slide count appropriate for the time slot?
- [ ] Are layout classes correctly applied with proper HTML structure?
- [ ] Do multi-column layouts use `<div class="grid"><div class="col">` wrappers?
- [ ] Are stat numbers using `<div class="stat">` markup?
- [ ] Does the color palette stay within Sui design tokens?
- [ ] Are product slides using the correct product-specific class?
