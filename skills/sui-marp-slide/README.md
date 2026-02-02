# Sui Marp Slide Creator

A Claude Code skill for creating Sui-branded presentations using [Marp](https://marp.app/) markdown.

## What It Does

Generates professional slide decks in Marp-compatible markdown using a single Sui corporate dark theme. The skill requires user-provided markdown files as the knowledge source — it does not fabricate content.

## File Structure

```
sui-marp-slide/
├── SKILL.md                          # Main skill instructions
├── README.md                         # This file
├── assets/
│   ├── sui-theme.css                 # Standalone Marpit CSS theme
│   ├── template-sui.md               # Self-contained Marp template
│   └── images/
│       ├── sui-logo.svg              # Sui droplet logo
│       ├── product-seal.svg          # Seal product illustration
│       ├── product-deepbook.svg      # DeepBook product illustration
│       ├── product-walrus.svg        # Walrus product illustration
│       ├── product-suins.svg         # SuiNS product illustration
│       ├── product-sui.svg           # Sui product illustration
│       ├── product-mysticeti.svg     # Mysticeti product illustration
│       ├── product-nautilus.svg      # Nautilus product illustration
│       ├── product-passkey.svg       # Passkey product illustration
│       ├── product-zklogin.svg       # zkLogin product illustration
│       └── product-move.svg          # Move product illustration
└── references/
    ├── best-practices.md             # Sui-adapted slide quality guidelines
    ├── marp-syntax.md                # Core Marp markdown syntax
    ├── image-patterns.md             # Image and background syntax
    ├── theme-css-guide.md            # CSS theme creation guide
    └── advanced-features.md          # Math, emoji, CLI features
```

## Design Tokens

| Token | Value | Usage |
|-------|-------|-------|
| Background | `#000000` | Pure black |
| Headings | `#FFFFFF` | h1, h2, h3 |
| Body text | `#8B8B8B` | Paragraphs, lists |
| Accent | `#4DA2FF` | Blue markers, links |
| Separator | `#3A3A3A` | Dotted borders |
| Font | Inter | Google Fonts import |
| Size | 1280x720 | 16:9 |

## Layout Classes Quick Reference

| Class | Description |
|-------|-------------|
| `lead` | Cover/title slide — large h1 bottom-left |
| `cols-4` | 4 columns with blue markers + body |
| `cols-3` | 3 columns |
| `cols-2-center` | 2 columns, centered title |
| `grid-2x2` | 2x2 grid, centered title |
| `cols-4-minimal` | 4 column headlines only |
| `fullbleed` | Full image, no padding |
| `cols-4-icon` | 4 columns with icons |
| `cols-4-stats` | 4 stat number columns |
| `stats-side` | Narrative left, stats right |
| `stats-left` | Large stacked stats |
| `split-right` | Right-aligned content |
| `list-right` | Title left, card list right |
| `grid-products` | 4x2 product grid with icons |
| `grid-images` | 4x2 image grid |
| `product-{name}` | Product hero (watermark) |
| `product-{name}-content` | Product content (split) |

Products: `seal`, `deepbook`, `walrus`, `suins`, `sui`, `mysticeti`, `nautilus`, `passkey`, `zklogin`, `move`

## Rendering

Generated `.md` files are self-contained (CSS embedded in `<style>` block).

```bash
# HTML
marp slides.md --html

# PDF
marp slides.md --html --pdf

# PowerPoint
marp slides.md --html --pptx

# With standalone theme file
marp slides.md --html --theme assets/sui-theme.css
```

The `--html` flag is required for layout class `<div>` elements.

## Based On

Forked from [marp-slide](https://github.com/davila7/claude-code-templates/tree/main/cli-tool/components/skills/creative-design/marp-slide), replacing its 7-theme system with a single Sui corporate theme and mandatory user-provided source material.
