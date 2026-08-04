# design/

Design-system templates. **Assets, not instructions.**

Nothing here is auto-loaded, and nothing here should be `@import`ed into a
CLAUDE.md. These files are copied into a project when that project needs them.

## Why not auto-load

`impeccable`'s context loader (`scripts/context.mjs`) resolves `DESIGN.md` from
the **project tree only** — project root, then `.agents/context/`, then `docs/`,
then repo root, then `$IMPECCABLE_CONTEXT_DIR`. It never reads `~/.claude/`.
A CLAUDE.md line saying "use the Sui DESIGN.md" is prose the loader ignores, so
the surface still reports `WORLD_DISCOVERY_REQUIRED`.

Three mechanisms actually work:

| Mechanism | Effect | When |
|---|---|---|
| Copy into the project root | Loader finds it; project can diverge | **Default. Do this.** |
| `IMPECCABLE_CONTEXT_DIR` env var | Global fallback, yields to any project that has its own | Only if you want one everywhere |
| `@import` in CLAUDE.md | Inlines the whole file into every session | Avoid — expensive, always on |

## Usage

```sh
cp ~/.claude/design/sui/DESIGN.md ./DESIGN.md
```

Copy per project that has a user interface. Do not gate on "is this project
Sui" — most Sui repos here are Move packages with no UI, and a design system is
noise in those.

## sui/

Derived from the official Sui Media Kit (logos, fonts, gradients) — the kit
contains no palette spec, no component library, and no primary typeface, only
open-license alternates.

**Only `#298DFF` is verified Sui brand truth.** The ramp, type mapping, status
colours, seven of eight chart hues, and both greys were derived or computed
here. The file's **Known Gaps** section names all twelve derivations
individually — read it before treating any value as official.

Every colour pairing in the file is measured, not estimated: contrast ratios
computed from the token values, chart palettes validated against simulated
protanopia and deuteranopia, and the dark ramp re-spaced at even OKLCH
lightness intervals.

Source of truth: **`~/workspace/sui-design`** (`alilloig/sui-design`, private).
That repo holds `DESIGN.md`, the media kit it is derived from, and
`scripts/verify.py`, which re-derives every measured claim in the file and
fails on drift.

Make changes there, then re-copy here. This copy is a convenience mirror and
has no verification harness of its own.

Copied 2026-08-04.
