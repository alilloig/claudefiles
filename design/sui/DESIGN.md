---
version: alpha
name: Sui-design-analysis
description: A dark-first, blue-native system built on one voltage — Sui Blue (#298DFF) — set against a near-black navy void (#000206) that is never pure black in the light. The whole palette is a single hue ramp sampled from the official Sui primary gradient, which reads as a horizon: deep space at the top, a blue dawn at mid-height, ice-white at the bottom. Sui Blue is a light blue, so filled controls carry a dark navy label rather than white — 6.28:1 rather than 3.31:1 — and brightening on hover raises contrast instead of destroying it. Type runs Inter Tight for display (tight tracking, weights 600-700) over Inter for body and DM Mono for addresses, hashes, and code — the three open-license faces the media kit actually ships. Shape language is soft and liquid, taken from the droplet mark: fully rounded pills for actions, 16px cards, 24px feature panels, and circular icon targets. Elevation on the dark canvas is expressed as a surface lift plus a blue glow, because black-on-black shadows do not read. Every colour pairing in this file is measured, and every interactive element ships hover, focus, disabled, loading, error and empty states.

palette:
  # Blue ramp — re-spaced at even perceptual intervals (OKLCH ΔL 0.068–0.076), dark to light
  blue-950: "#000206"
  blue-900: "#000B26"
  blue-800: "#001944"
  blue-750: "#002A66"
  blue-700: "#003A89"
  blue-650: "#004CAF"
  blue-600: "#0061CD"
  blue-550: "#1A7FF0"
  blue-500: "#298DFF"
  blue-450: "#439BFF"
  blue-400: "#72B3FF"
  blue-300: "#A2CDFF"
  blue-200: "#C3E0FF"
  blue-100: "#DBECFF"
  blue-050: "#EFF7FF"
  # Neutrals — the only non-blue achromatics in the system
  white: "#FFFFFF"
  black: "#000000"
  neutral-050: "#F8F9FA"
  neutral-200: "#D5D5D5"
  neutral-600: "#424242"
  # Status hues — extensions, not media-kit values
  green-500: "#12B981"
  green-700: "#0A7A55"
  green-tint: "#021F22"
  amber-500: "#F0A417"
  amber-700: "#8A5D00"
  amber-tint: "#1D1C15"
  red-500: "#FF4D4F"
  red-700: "#C0272A"
  red-tint: "#1F121C"
  blue-tint: "#051A31"

stack:
  display: "'Inter Tight', Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"
  body: "Inter, -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif"
  mono: "'DM Mono', ui-monospace, SFMono-Regular, Menlo, monospace"

colors:
  # Brand
  brand: "{palette.blue-500}"
  brand-hover: "{palette.blue-450}"
  brand-active: "{palette.blue-550}"
  brand-disabled: "{palette.blue-750}"
  brand-subtle: "{palette.blue-800}"
  brand-solid: "{palette.blue-600}"
  brand-solid-hover: "{palette.blue-650}"
  on-brand: "{palette.blue-950}"
  on-brand-solid: "{palette.white}"
  # Dark surfaces
  canvas: "{palette.blue-950}"
  surface: "{palette.blue-900}"
  surface-raised: "{palette.blue-800}"
  surface-overlay: "{palette.blue-750}"
  surface-sunken: "{palette.blue-950}"
  # Borders — decorative
  hairline: "{palette.blue-700}"
  hairline-soft: "{palette.blue-800}"
  hairline-strong: "{palette.blue-650}"
  # Borders — interactive, 3:1 floor
  hairline-interactive: "{palette.blue-600}"
  # Text on dark
  ink: "{palette.white}"
  ink-body: "{palette.blue-200}"
  ink-muted: "{palette.blue-400}"
  ink-faint: "{palette.blue-650}"
  ink-placeholder: "{palette.blue-400}"
  ink-disabled: "{palette.blue-600}"
  ink-code: "{palette.blue-300}"
  # Links and selection
  link: "{palette.blue-400}"
  link-hover: "{palette.blue-200}"
  link-visited: "{palette.blue-300}"
  selection-bg: "{palette.blue-600}"
  selection-ink: "{palette.white}"
  # Light theme
  canvas-light: "{palette.neutral-050}"
  surface-light: "{palette.white}"
  surface-light-soft: "{palette.blue-050}"
  hairline-light: "{palette.blue-100}"
  hairline-light-strong: "{palette.blue-300}"
  hairline-light-interactive: "{palette.blue-500}"
  ink-light: "{palette.blue-950}"
  ink-light-body: "{palette.blue-800}"
  ink-light-muted: "{palette.blue-650}"
  link-light: "{palette.blue-600}"
  link-light-hover: "{palette.blue-650}"
  # Focus and scrim
  focus-ring: "{palette.blue-450}"
  focus-ring-on-brand: "{palette.white}"
  focus-ring-light: "{palette.blue-600}"
  scrim: "{palette.blue-950}"
  # Status
  success: "{palette.green-500}"
  warning: "{palette.amber-500}"
  danger: "{palette.red-500}"
  info: "{palette.blue-500}"
  success-subtle: "{palette.green-tint}"
  warning-subtle: "{palette.amber-tint}"
  danger-subtle: "{palette.red-tint}"
  info-subtle: "{palette.blue-tint}"
  success-light: "{palette.green-700}"
  warning-light: "{palette.amber-700}"
  danger-light: "{palette.red-700}"
  # Skeleton
  skeleton-base: "{palette.blue-750}"
  skeleton-sheen: "{palette.blue-700}"
  # Legacy value names kept for readability
  ice: "{palette.blue-050}"
  paper: "{palette.neutral-050}"
  logo-white: "{palette.white}"
  logo-black: "{palette.black}"

gradients:
  primary-horizon: "radial-gradient(ellipse 140% 105% at 50% 128%, #EFF7FF 0%, #C3E0FF 14%, #82BDFF 24%, #439BFF 34%, #1A7FF0 44%, #0061CD 54%, #002A66 68%, #001631 80%, #000206 100%)"
  primary-linear: "linear-gradient(180deg, #000206 0%, #000A15 10%, #001631 20%, #002A66 35%, #0061CD 50%, #1A7FF0 60%, #439BFF 70%, #82BDFF 80%, #C3E0FF 90%, #DBECFF 100%)"
  brand-sweep: "linear-gradient(90deg, #0061CD 0%, #298DFF 50%, #72B3FF 100%)"
  brand-fade: "linear-gradient(180deg, #298DFF 0%, rgba(41,141,255,0) 100%)"
  surface-veil: "linear-gradient(180deg, #001944 0%, #000206 100%)"
  glow-radial: "radial-gradient(circle at 50% 0%, rgba(41,141,255,0.28) 0%, rgba(41,141,255,0) 62%)"
  skeleton-sheen: "linear-gradient(90deg, #002A66 0%, #003A89 50%, #002A66 100%)"

chart:
  theme: "brand · green · pink · amber · violet · orange · teal · red"
  categorical-dark:
    - "#298DFF"
    - "#009800"
    - "#BA1E88"
    - "#968800"
    - "#883AC8"
    - "#EE5C00"
    - "#00A898"
    - "#C60032"
  categorical-light:
    - "#0268F0"
    - "#00AC00"
    - "#CA127A"
    - "#9E9000"
    - "#8420B8"
    - "#D85200"
    - "#00A494"
    - "#D6121A"
  sequential-dark:
    - "#004CAF"
    - "#0061CD"
    - "#1A7FF0"
    - "#439BFF"
    - "#72B3FF"
    - "#C3E0FF"
  sequential-light:
    - "#72B3FF"
    - "#298DFF"
    - "#0061CD"
    - "#004CAF"
    - "#002A66"
    - "#001944"
  diverging-dark:
    - "#298DFF"
    - "#006EEC"
    - "#0056BC"
    - "#424242"
    - "#9A3A00"
    - "#C14B00"
    - "#EB5C00"
  diverging-light:
    - "#0268F0"
    - "#1C92FF"
    - "#76B7FF"
    - "#D5D5D5"
    - "#FF9254"
    - "#F25F00"
    - "#BF4A00"
  zero-dark: "#424242"
  zero-light: "#D5D5D5"
  surface-dark: "#000B26"
  surface-light: "#FFFFFF"
  grid: "#003A89"
  tick-label: "#72B3FF"
  value-label: "#C3E0FF"
  title: "#FFFFFF"
  all-pairs-cap: 3

typography:
  display-2xl:
    fontFamily: "{stack.display}"
    fontSize: 72px
    fontWeight: 700
    lineHeight: 1.04
    letterSpacing: -2.16px
  display-xl:
    fontFamily: "{stack.display}"
    fontSize: 56px
    fontWeight: 700
    lineHeight: 1.07
    letterSpacing: -1.68px
  display-lg:
    fontFamily: "{stack.display}"
    fontSize: 44px
    fontWeight: 600
    lineHeight: 1.1
    letterSpacing: -1.1px
  display-md:
    fontFamily: "{stack.display}"
    fontSize: 36px
    fontWeight: 600
    lineHeight: 1.15
    letterSpacing: -0.72px
  heading-lg:
    fontFamily: "{stack.display}"
    fontSize: 28px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.42px
  heading-md:
    fontFamily: "{stack.display}"
    fontSize: 22px
    fontWeight: 600
    lineHeight: 1.27
    letterSpacing: -0.22px
  heading-sm:
    fontFamily: "{stack.body}"
    fontSize: 18px
    fontWeight: 600
    lineHeight: 1.33
    letterSpacing: -0.09px
  body-lg:
    fontFamily: "{stack.body}"
    fontSize: 18px
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0
  body-md:
    fontFamily: "{stack.body}"
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0
  body-sm:
    fontFamily: "{stack.body}"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.57
    letterSpacing: 0
  label-md:
    fontFamily: "{stack.body}"
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1.43
    letterSpacing: 0
  label-sm:
    fontFamily: "{stack.body}"
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.38
    letterSpacing: 0
  caption:
    fontFamily: "{stack.body}"
    fontSize: 12px
    fontWeight: 400
    lineHeight: 1.5
    letterSpacing: 0
  overline:
    fontFamily: "{stack.mono}"
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1.33
    letterSpacing: 1.2px
    textTransform: uppercase
  button-lg:
    fontFamily: "{stack.body}"
    fontSize: 16px
    fontWeight: 500
    lineHeight: 1
    letterSpacing: 0
  button-md:
    fontFamily: "{stack.body}"
    fontSize: 14px
    fontWeight: 500
    lineHeight: 1
    letterSpacing: 0
  nav-link:
    fontFamily: "{stack.body}"
    fontSize: 15px
    fontWeight: 500
    lineHeight: 1.33
    letterSpacing: 0
  code-md:
    fontFamily: "{stack.mono}"
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.6
    letterSpacing: 0
  code-sm:
    fontFamily: "{stack.mono}"
    fontSize: 13px
    fontWeight: 400
    lineHeight: 1.54
    letterSpacing: 0
  address-mono:
    fontFamily: "{stack.mono}"
    fontSize: 13px
    fontWeight: 300
    lineHeight: 1.4
    letterSpacing: 0.13px
  numeric-display:
    fontFamily: "{stack.mono}"
    fontSize: 40px
    fontWeight: 500
    lineHeight: 1.1
    letterSpacing: -0.8px

rounded:
  none: 0px
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 24px
  xxl: 32px
  full: 9999px

spacing:
  xxs: 2px
  xs: 4px
  sm: 8px
  md: 12px
  base: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
  section: 96px
  section-lg: 160px

elevation:
  flat: "none"
  raised: "inset 0 1px 0 0 #003A89, 0 2px 8px rgba(0,2,6,0.6)"
  overlay: "0 8px 32px rgba(0,2,6,0.72), 0 0 0 1px #003A89"
  glow-brand: "0 0 0 1px #298DFF, 0 0 24px rgba(41,141,255,0.35)"
  glow-soft: "0 0 40px rgba(41,141,255,0.18)"
  light-raised: "0 1px 2px rgba(0,2,6,0.06), 0 4px 12px rgba(0,2,6,0.06)"
  light-overlay: "0 12px 40px rgba(0,2,6,0.12)"

motion:
  duration-fast: 120ms
  duration-base: 200ms
  duration-slow: 400ms
  duration-ambient: 1200ms
  ease-standard: "cubic-bezier(0.2, 0, 0, 1)"
  ease-out: "cubic-bezier(0.16, 1, 0.3, 1)"

components:
  button-primary:
    backgroundColor: "{colors.brand}"
    textColor: "{colors.on-brand}"
    typography: "{typography.button-lg}"
    rounded: "{rounded.full}"
    padding: 0 24px
    height: 48px
  button-primary-hover:
    backgroundColor: "{colors.brand-hover}"
    textColor: "{colors.on-brand}"
    rounded: "{rounded.full}"
  button-primary-active:
    backgroundColor: "{colors.brand-active}"
    textColor: "{colors.on-brand}"
    rounded: "{rounded.full}"
  button-primary-disabled:
    backgroundColor: "{colors.brand-disabled}"
    textColor: "{colors.ink-muted}"
    rounded: "{rounded.full}"
    cursor: not-allowed
  button-primary-loading:
    backgroundColor: "{colors.brand}"
    textColor: "{colors.on-brand}"
    rounded: "{rounded.full}"
    height: 48px
    ariaBusy: true
    note: "Label stays; a 16px spinner replaces the leading icon slot. Width is locked before the swap so the button never resizes."
  button-primary-solid:
    backgroundColor: "{colors.brand-solid}"
    textColor: "{colors.on-brand-solid}"
    typography: "{typography.button-lg}"
    rounded: "{rounded.full}"
    padding: 0 24px
    height: 48px
    note: "Sanctioned alternate lockup for projects that must keep a white label. 5.85:1."
  button-secondary:
    backgroundColor: transparent
    borderColor: "{colors.hairline-interactive}"
    textColor: "{colors.ink}"
    typography: "{typography.button-lg}"
    rounded: "{rounded.full}"
    padding: 0 24px
    height: 48px
  button-secondary-hover:
    backgroundColor: "{colors.surface-raised}"
    borderColor: "{colors.brand}"
    textColor: "{colors.ink}"
    rounded: "{rounded.full}"
  button-secondary-disabled:
    backgroundColor: transparent
    borderColor: "{colors.hairline}"
    textColor: "{colors.ink-disabled}"
    rounded: "{rounded.full}"
    cursor: not-allowed
  button-ghost:
    backgroundColor: transparent
    textColor: "{colors.ink-body}"
    typography: "{typography.button-md}"
    rounded: "{rounded.full}"
    padding: 0 16px
    height: 40px
  button-ghost-hover:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.ink}"
    rounded: "{rounded.full}"
  button-danger:
    backgroundColor: "{colors.danger-subtle}"
    borderColor: "{colors.danger}"
    textColor: "{colors.danger}"
    typography: "{typography.button-lg}"
    rounded: "{rounded.full}"
    padding: 0 24px
    height: 48px
  button-sm:
    backgroundColor: "{colors.brand}"
    textColor: "{colors.on-brand}"
    typography: "{typography.button-md}"
    rounded: "{rounded.full}"
    padding: 0 16px
    height: 36px
  icon-button:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.ink-body}"
    rounded: "{rounded.full}"
    height: 40px
    minHitArea: 44px
    ariaLabel: required
  top-nav:
    backgroundColor: "rgba(0,2,6,0.72)"
    textColor: "{colors.ink-body}"
    typography: "{typography.nav-link}"
    borderColor: "{colors.hairline-soft}"
    height: 72px
    backdropFilter: "blur(16px)"
  nav-link-active:
    backgroundColor: transparent
    textColor: "{colors.ink}"
    typography: "{typography.nav-link}"
  card:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.hairline-soft}"
    textColor: "{colors.ink-body}"
    typography: "{typography.body-md}"
    rounded: "{rounded.lg}"
    padding: 24px
    elevation: "{elevation.raised}"
  card-hover:
    backgroundColor: "{colors.surface-raised}"
    borderColor: "{colors.hairline}"
    rounded: "{rounded.lg}"
    elevation: "{elevation.glow-soft}"
  card-featured:
    backgroundImage: "{gradients.surface-veil}"
    borderColor: "{colors.hairline}"
    textColor: "{colors.ink}"
    rounded: "{rounded.xl}"
    padding: 32px
  stat-tile:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.hairline-soft}"
    textColor: "{colors.ink}"
    typography: "{typography.numeric-display}"
    rounded: "{rounded.md}"
    padding: 20px 24px
  text-input:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.hairline-interactive}"
    textColor: "{colors.ink}"
    placeholderColor: "{colors.ink-placeholder}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    padding: 0 16px
    height: 48px
  text-input-focus:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.brand}"
    rounded: "{rounded.md}"
    elevation: "{elevation.glow-brand}"
  text-input-error:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.danger}"
    textColor: "{colors.ink}"
    rounded: "{rounded.md}"
    height: 48px
    ariaInvalid: true
  text-input-disabled:
    backgroundColor: "{colors.canvas}"
    borderColor: "{colors.hairline}"
    textColor: "{colors.ink-disabled}"
    rounded: "{rounded.md}"
    height: 48px
    cursor: not-allowed
  text-input-readonly:
    backgroundColor: "{colors.canvas}"
    borderColor: "{colors.hairline}"
    textColor: "{colors.ink-body}"
    rounded: "{rounded.md}"
    height: 48px
  input-label:
    backgroundColor: transparent
    textColor: "{colors.ink-body}"
    typography: "{typography.label-md}"
  input-helper:
    backgroundColor: transparent
    textColor: "{colors.ink-muted}"
    typography: "{typography.caption}"
  input-error-message:
    backgroundColor: transparent
    textColor: "{colors.danger}"
    typography: "{typography.caption}"
    ariaLive: polite
    note: "Prefixed by a 16px alert icon — never colour alone."
  input-required:
    backgroundColor: transparent
    textColor: "{colors.danger}"
    typography: "{typography.label-md}"
  select:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.hairline-interactive}"
    textColor: "{colors.ink}"
    typography: "{typography.body-md}"
    rounded: "{rounded.md}"
    height: 48px
  badge-brand:
    backgroundColor: "{colors.brand-subtle}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 10px
  badge-neutral:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 10px
  badge-success:
    backgroundColor: "{colors.success-subtle}"
    borderColor: "{colors.success}"
    textColor: "{colors.success}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 10px
    icon: required
  badge-warning:
    backgroundColor: "{colors.warning-subtle}"
    borderColor: "{colors.warning}"
    textColor: "{colors.warning}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 10px
    icon: required
  badge-danger:
    backgroundColor: "{colors.danger-subtle}"
    borderColor: "{colors.danger}"
    textColor: "{colors.danger}"
    typography: "{typography.label-sm}"
    rounded: "{rounded.full}"
    padding: 4px 10px
    icon: required
  address-chip:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.ink-body}"
    typography: "{typography.address-mono}"
    rounded: "{rounded.sm}"
    padding: 4px 8px
    minHeight: 44px
    note: "44px is the hit area; the painted chip stays 26px and is centred inside it."
  code-block:
    backgroundColor: "{colors.surface-sunken}"
    borderColor: "{colors.hairline-soft}"
    textColor: "{colors.ink-body}"
    typography: "{typography.code-md}"
    rounded: "{rounded.md}"
    padding: 20px
  inline-code:
    backgroundColor: "{colors.brand-subtle}"
    textColor: "{colors.ink-code}"
    typography: "{typography.code-sm}"
    rounded: "{rounded.xs}"
    padding: 2px 6px
  table-header:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-sm}"
    borderColor: "{colors.hairline}"
    height: 44px
  table-row:
    backgroundColor: transparent
    textColor: "{colors.ink-body}"
    typography: "{typography.body-sm}"
    borderColor: "{colors.hairline-soft}"
    height: 56px
  table-row-hover:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.ink}"
  table-row-selected:
    backgroundColor: "{colors.brand-subtle}"
    borderColor: "{colors.hairline-interactive}"
    textColor: "{colors.ink}"
  skeleton:
    backgroundColor: "{colors.skeleton-base}"
    backgroundImage: "{gradients.skeleton-sheen}"
    rounded: "{rounded.xs}"
    ariaHidden: true
    note: "Sheen sweeps over 1200ms; static fill under prefers-reduced-motion."
  empty-state:
    backgroundColor: transparent
    textColor: "{colors.ink-muted}"
    typography: "{typography.body-md}"
    padding: 64px 24px
    note: "Heading in {typography.heading-md} on {colors.ink}, one sentence of cause, one primary action."
  alert-info:
    backgroundColor: "{colors.info-subtle}"
    borderColor: "{colors.hairline-interactive}"
    textColor: "{colors.ink-body}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.md}"
    padding: 16px
    icon: required
  alert-danger:
    backgroundColor: "{colors.danger-subtle}"
    borderColor: "{colors.danger}"
    textColor: "{colors.ink-body}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.md}"
    padding: 16px
    icon: required
    ariaLive: assertive
  tooltip:
    backgroundColor: "{colors.ink-body}"
    textColor: "{colors.ink-light}"
    typography: "{typography.caption}"
    rounded: "{rounded.sm}"
    padding: 6px 10px
  tab-active:
    backgroundColor: "{colors.surface-raised}"
    textColor: "{colors.ink}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 12px 16px
    minHitArea: 44px
  tab-inactive:
    backgroundColor: transparent
    textColor: "{colors.ink-muted}"
    typography: "{typography.label-md}"
    rounded: "{rounded.full}"
    padding: 12px 16px
    minHitArea: 44px
  modal:
    backgroundColor: "{colors.surface}"
    borderColor: "{colors.hairline}"
    textColor: "{colors.ink}"
    rounded: "{rounded.xl}"
    padding: 32px
    elevation: "{elevation.overlay}"
  toast:
    backgroundColor: "{colors.surface-overlay}"
    borderColor: "{colors.hairline-strong}"
    textColor: "{colors.ink}"
    typography: "{typography.body-sm}"
    rounded: "{rounded.md}"
    padding: 12px 16px
    elevation: "{elevation.overlay}"
  hero-gradient:
    backgroundImage: "{gradients.primary-horizon}"
    textColor: "{colors.ink}"
    typography: "{typography.display-xl}"
    padding: 160px 24px
  footer:
    backgroundColor: "{colors.canvas}"
    borderColor: "{colors.hairline-soft}"
    textColor: "{colors.ink-muted}"
    typography: "{typography.body-sm}"
    padding: 64px 24px
  divider:
    backgroundColor: "{colors.hairline-soft}"
    height: 1px
---

## Overview

Sui's visual identity is a **single-hue system**. The official media kit ships exactly one literal color — `#298DFF`, the "Sui Blue" fill inside the logo SVGs — plus pure black and pure white. Every other value in this document is sampled from the four gradient renders in `03_Sui_Gradients/`, which are the real palette carrier.

That gradient is the whole idea. The primary gradient reads as a **horizon**: a near-black navy void at the top (`{palette.blue-950}` — #000206), a saturated blue dawn through the middle (`{palette.blue-500}` → `{colors.brand}`), and ice-white at the bottom (`{colors.ice}` — #EFF7FF). Sampling its center column at 5% steps produces a clean, evenly-spaced tonal ramp, which is why `blue-950` through `blue-050` in this system are not invented — they are measured.

The gradient is **not linear**. At 60% height the center column reads #1A7FF0 while the left and right edges read #71B4FF and #ACD3FF. The bright band curves upward at the edges, so the correct CSS reproduction is an ellipse anchored below the frame (`{gradients.primary-horizon}`), not a top-to-bottom `linear-gradient`. The linear form is kept as `{gradients.primary-linear}` for narrow strips where the curvature would not be visible anyway.

Because the canvas is a near-black navy and never pure black in the lit areas, this is a **dark-first system**. Light mode exists and is derived from the same ramp's bright end (`{colors.paper}` — #F8F9FA, which appears literally in `Sui_Secondary-Gradient_2.png`), but the identity lives in the dark.

Type runs on the three open-license faces the kit actually ships in `02_Sui_Typography/Sui_Typography_Alternates/`: **Inter Tight** for display, **Inter** for body and UI, **DM Mono** for addresses, hashes, amounts, and code. Noto Sans is the multilingual fallback for scripts Inter does not cover. See **Known Gaps** — the folder name says "Alternates," so a proprietary primary face exists that the kit does not include.

Shape language comes from the droplet mark: **liquid and soft**. Actions are fully-rounded pills (`{rounded.full}`), cards are 16px (`{rounded.lg}`), feature panels 24px (`{rounded.xl}`), and icon targets are circles. Hard corners appear only on tables, code blocks, and full-bleed gradient bands.

**Key Characteristics:**
- One accent, one hue: `{colors.brand}` (#298DFF) carries every primary CTA, focus ring, and active state. There is no secondary brand color — depth comes from the tonal ramp, not from a second hue.
- Sui Blue is a light blue, and the system treats it as one. Filled controls take `{colors.on-brand}` (#000206) for their label — 6.28:1, against 3.31:1 for white. This is the single most consequential rule in the file; white-on-Sui-Blue fails WCAG AA at every button size.
- Dark canvas is navy, not black: `{colors.canvas}` (#000206) has a measurable blue cast. Pure `#000000` appears only as a logo variant, never as a page floor.
- Elevation is the surface ladder first: on a #000206 canvas a drop shadow has nowhere to darken into, so depth comes from stepping up the ramp at a consistent OKLCH ΔL of about 0.072. Blue glow (`{elevation.glow-soft}`, `{elevation.glow-brand}`) is an accent reserved for focus and the primary action, not the depth model.
- Monospace is a first-class citizen: `{typography.address-mono}` and `{typography.numeric-display}` exist because this is blockchain UI — object IDs, addresses, digests, and balances need tabular, unambiguous glyphs.
- Tight display tracking: `{typography.display-2xl}` runs -2.16px (-0.03em) letter-spacing in Inter Tight 700. Headlines are dense and engineered, not airy. Emphasis comes from weight and size — never from gradient-filled text.
- Gradient as a surface, not a decoration: the primary horizon is a full-bleed hero floor, not an accent bar. Content sits on the dark half; the bright half is the fold.
- 8px spacing rhythm with a wide `{spacing.section}` (96px) and `{spacing.section-lg}` (160px) — marketing pages breathe; app surfaces use `{spacing.lg}` and below.

## Colors

### Token architecture

Colors live in **two layers**, and the separation is the point.

**`palette`** holds 30 primitives. Each is a literal hex named for what it *is* — `blue-700`, `neutral-050`, `red-tint`. Primitives never reference anything. This is the only place a hex appears in the whole file.

**`colors`** holds 62 semantics. Each is a reference named for the *job it does* — `hairline`, `ink-placeholder`, `focus-ring-on-brand`. Semantics never contain a hex; they always point at a primitive.

```
palette.blue-700: "#003A89"        ← the value, named for what it is
colors.hairline:  "{palette.blue-700}"   ← the role, named for what it does
colors.skeleton-sheen: "{palette.blue-700}"
```

Two semantics share one primitive above. Before this separation the file stated `#003A89` twice, and nothing recorded that they were ever the same decision — retuning one silently diverged from the others. Now the relationship is structural: change `blue-700` and all three move; repoint `hairline` alone and only the border changes. **That choice is now explicit in both directions**, which is the entire reason for the layer.

Two rules keep it honest, and both are mechanically checkable:

1. **No component ever references a primitive.** Components address `{colors.*}` only. A component reaching past the semantic layer is a missing token, not a shortcut.
2. **Theme changes remap semantics, never primitives.** The light theme is a separate set of semantic names pointing into the same ramp — not a second palette.

`{stack.display}`, `{stack.body}`, and `{stack.mono}` apply the same idea to type. The file previously declared five different font-stack strings for what were meant to be three families; every `fontFamily` now references one of the three.

### Brand

- **Sui Blue** (`{colors.brand}` — #298DFF): The only literal brand color in the media kit, taken from `Logo_Sui_Full_Sui Blue.svg` and `Logo_Sui_Droplet_Sui Blue.svg`. Primary CTA fill, active nav state, focus ring seed, and the brand-tinted logo variant. As *text* on the dark canvas it measures 6.28:1 and passes AA at any size. As a *fill*, its label must be `{colors.on-brand}` — see below.
- **On Brand** (`{colors.on-brand}` — #000206): The label color on every Sui Blue fill. **6.28:1.** White on #298DFF measures 3.31:1 and fails SC 1.4.3 for the 16px button label the system specifies; do not use it.
- **Brand Hover** (`{colors.brand-hover}` — #439BFF): One ramp step lighter. The system brightens on hover because the canvas is dark — and with a dark label that also *raises* contrast, to 7.29:1. Brightening a fill under a white label would do the opposite, which is why the label color is not negotiable.
- **Brand Active** (`{colors.brand-active}` — #1A7FF0): The press-down state. 5.28:1 with `{colors.on-brand}`.
- **Brand Solid** (`{colors.brand-solid}` — #0061CD) and **Brand Solid Hover** (`{colors.brand-solid-hover}` — #004CAF): The sanctioned alternate lockup for projects that must keep a white label — `{component.button-primary-solid}`. 5.85:1 and 7.92:1 with `{colors.on-brand-solid}`. #0061CD is the exact 50% midpoint of the primary gradient.
- **Brand Disabled** (`{colors.brand-disabled}` — #002A66): A deep, desaturated ramp step. Disabled CTAs keep the hue but drop to near-surface luminance; their label is `{colors.ink-muted}` at 6.31:1, so the action stays readable while reading as inert.
- **Brand Subtle** (`{colors.brand-subtle}` — #001944): The tint fill behind badges, inline code, and selected rows.

### The primitive ramp

Sampled from `Sui_Primary-Gradient.png` (5760×3240) down its center column, dark to light. These are values, not roles — reach for a semantic token instead unless you are defining one.

| Primitive | Hex | OKLCH L | Semantics that point here |
|---|---|---|---|
| `{palette.blue-950}` | #000206 | 0.083 | `canvas`, `surface-sunken`, `on-brand`, `ink-light`, `scrim` |
| `{palette.blue-900}` | #000B26 | 0.158 | `surface` |
| `{palette.blue-800}` | #001944 | 0.227 | `surface-raised`, `hairline-soft`, `brand-subtle`, `ink-light-body` |
| `{palette.blue-750}` | #002A66 | 0.301 | `surface-overlay`, `brand-disabled`, `skeleton-base` |
| `{palette.blue-700}` | #003A89 | 0.370 | `hairline`, `skeleton-sheen` |
| `{palette.blue-650}` | #004CAF | 0.442 | `hairline-strong`, `ink-faint`, `ink-light-muted`, `brand-solid-hover`, `link-light-hover` |
| `{palette.blue-600}` | #0061CD | 0.512 | `hairline-interactive`, `ink-disabled`, `brand-solid`, `link-light`, `selection-bg`, `focus-ring-light` |
| `{palette.blue-550}` | #1A7FF0 | 0.605 | `brand-active` |
| `{palette.blue-500}` | #298DFF | 0.648 | `brand`, `info`, `hairline-light-interactive` |
| `{palette.blue-450}` | #439BFF | 0.684 | `brand-hover`, `focus-ring` |
| `{palette.blue-400}` | #72B3FF | 0.754 | `ink-muted`, `ink-placeholder`, `link` |
| `{palette.blue-300}` | #A2CDFF | 0.812 | `ink-code`, `link-visited`, `hairline-light-strong` |
| `{palette.blue-200}` | #C3E0FF | 0.877 | `ink-body`, `link-hover` |
| `{palette.blue-100}` | #DBECFF | 0.929 | `hairline-light` |
| `{palette.blue-050}` | #EFF7FF | 0.970 | `surface-light-soft`, `ice` |

Non-blue primitives: `{palette.white}` #FFFFFF, `{palette.black}` #000000, `{palette.neutral-050}` #F8F9FA (the light canvas, sampled from `Sui_Secondary-Gradient_2.png`), plus `{palette.neutral-200}` and `{palette.neutral-600}` — the two chart midpoint greys — and the six status hues with their tints.

**Sui Blue is `blue-500`.** The brand sits on the scale's canonical brand step, where its measured lightness places it. It previously had no numeric name at all, which made it the one value the ramp could not address.

**The dark end is re-spaced.** As first sampled, the six steps from `blue-950` to `blue-600` were taken at even *spatial* intervals down the gradient image, which produced uneven perceptual intervals — OKLCH ΔL ranging from 0.042 to 0.076, an 1.8× variation, with the tightest pinch exactly where the overlay surface sits. Five steps were re-solved at even lightness targets along the same hue (258–259°) and the same natural chroma curve. Every interval is now **ΔL 0.068–0.076**, a 1.12× spread against the 1.8× it replaced.

`blue-950` and everything from `blue-600` upward keep their original sampled values, so the canvas identity and every verified text pairing survive untouched.

A caution on reading the numbers: **contrast ratio understates separation at the dark end.** The +0.05 flare constant in the WCAG formula compresses all near-black pairs, so `canvas` → `surface` still reports 1.06:1 even though the two are a full perceptual step apart. Judge the surface ladder by ΔL; judge text and boundaries by contrast ratio.


### Dark Surfaces (default theme)

- **Canvas** (`{colors.canvas}` — #000206): The page floor. Never #000000 — the blue cast is what separates the system from a generic dark theme.
- **Surface** (`{colors.surface}` — #000B26): Cards, panels, input fills. One step off the canvas.
- **Surface Raised** (`{colors.surface-raised}` — #001944): Hovered cards, icon buttons, active tabs, chips.
- **Surface Overlay** (`{colors.surface-overlay}` — #002A66): Toasts, popovers, dropdowns — anything floating above a modal scrim.

### Light Surfaces

- **Canvas Light** (`{colors.canvas-light}` — #F8F9FA): The light page floor.
- **Surface Light** (`{colors.surface-light}` — #FFFFFF): Cards on the light canvas.
- **Surface Light Soft** (`{colors.surface-light-soft}` — #EFF7FF): Tinted panels, callouts, table zebra striping.

### Hairlines & Borders

Borders split into two roles, and the split is not cosmetic. A rule that merely separates content is decorative and exempt from contrast requirements. A rule that defines the boundary of a control — an input, a secondary button, a checkbox — is the only thing telling the user that thing is operable, and WCAG 2.2 SC 1.4.11 puts a 3:1 floor on it.

**Decorative** — no contrast floor:

- **Hairline** (`{colors.hairline}` — #003A89): The default 1px rule on dark — card borders, table row dividers, section separators. 1.94:1 on canvas.
- **Hairline Soft** (`{colors.hairline-soft}` — #001944): Low-contrast dividers inside dense lists where the default rule is too loud.
- **Hairline Strong** (`{colors.hairline-strong}` — #004CAF): Heavier decorative separation. 2.62:1 — note this still does *not* reach the interactive floor.
- **Hairline Light** (`{colors.hairline-light}` — #DBECFF) and **Hairline Light Strong** (`{colors.hairline-light-strong}` — #A2CDFF): The light-theme decorative equivalents. Borders stay blue-tinted rather than neutral gray. The system has exactly two greys, both chart diverging midpoints, and neither is available for UI.

**Interactive** — 3:1 floor, mandatory:

- **Hairline Interactive** (`{colors.hairline-interactive}` — #0061CD): **3.55:1 on canvas.** The boundary of every input, select, secondary button, checkbox, and radio on the dark theme. It cannot be swapped for `{colors.hairline}`, which measures 1.94:1 — and the surface fill behind it is only 1.06:1 off the canvas, so the border is genuinely the sole cue that a control exists.
- **Hairline Light Interactive** (`{colors.hairline-light-interactive}` — #298DFF): **3.14:1 on `{colors.canvas-light}`.** The lightest value in the ramp that clears the floor on paper.

### Text

- **Ink** (`{colors.ink}` — #FFFFFF): Headlines and primary text on dark. Pure white, matching the `White` logo variant.
- **Ink Body** (`{colors.ink-body}` — #C3E0FF): Running body copy on dark. The slight blue cast reduces the harshness of pure white on a near-black field over long paragraphs.
- **Ink Muted** (`{colors.ink-muted}` — #72B3FF): Captions, table headers, secondary labels, inactive tabs. 9.50:1.
- **Ink Placeholder** (`{colors.ink-placeholder}` — #72B3FF): Input placeholder text. **8.93:1 on `{colors.surface}`.** Placeholder text is real text and carries the field's hint — it takes the same 4.5:1 floor as body copy. The filled value renders in `{colors.ink}` (white), so the two remain clearly distinct.
- **Ink Disabled** (`{colors.ink-disabled}` — #0061CD): Disabled control text. 3.34:1 — deliberately below the body floor so the control reads as inert, but well above the point where the label becomes unguessable.
- **Ink Faint** (`{colors.ink-faint}` — #004CAF): Decorative glyphs and non-informational marks only. 2.62:1. Never carries text a user must read.
- **Ink Light** (`{colors.ink-light}` — #000206), **Ink Light Body** (`{colors.ink-light-body}` — #001944), **Ink Light Muted** (`{colors.ink-light-muted}` — #004CAF): The light-theme text ladder. Headlines use the void color rather than #000000.

### Links

Links are the one place the brand hue steps aside. `{colors.brand}` as inline body text on the canvas measures 6.28:1 and passes, but it is also the CTA fill color — using it for text as well collapses the distinction between "click this button" and "this word is a link".

- **Link** (`{colors.link}` — #72B3FF): 9.50:1 on canvas. Underlined by default; underline is never the only affordance removed on hover.
- **Link Hover** (`{colors.link-hover}` — #C3E0FF): 15.25:1.
- **Link Visited** (`{colors.link-visited}` — #A2CDFF): 12.57:1.
- **Link Light** (`{colors.link-light}` — #0061CD) and **Link Light Hover** (`{colors.link-light-hover}` — #004CAF): 5.55:1 and 7.51:1 on `{colors.canvas-light}`. Sui Blue itself measures only 3.14:1 on paper and must not carry body-size link text in light mode.

### Selection

- **Selection** (`{colors.selection-bg}` — #0061CD with `{colors.selection-ink}` — #FFFFFF): 5.85:1. Specified because the browser default selection color is a system blue that collides with the brand hue and reads as a rendering fault.

### Semantic

The media kit contains **no** status colors. These are an extension chosen to sit beside the blue without competing with it — see **Known Gaps** before shipping them as brand-official.

- **Success** (`{colors.success}` — #12B981): Confirmed transactions, healthy nodes. 8.19:1 on canvas.
- **Warning** (`{colors.warning}` — #F0A417): Pending states, gas warnings. 9.92:1.
- **Danger** (`{colors.danger}` — #FF4D4F): Failed transactions, destructive actions. 6.35:1.
- **Info** (`{colors.info}` — #298DFF): Aliased to the brand. Informational callouts use the brand blue rather than a separate hue.

Each has a 12% tint for fills — `{colors.success-subtle}` #021F22, `{colors.warning-subtle}` #1D1C15, `{colors.danger-subtle}` #1F121C, `{colors.info-subtle}` #051A31. The status color remains legible on its own tint: 6.78:1, 8.16:1, 5.53:1 and 5.30:1 respectively.

The three status hues are far too light for the light theme — #12B981 measures 2.41:1 on `{colors.canvas-light}`, #F0A417 just 1.99:1. Light mode uses the darkened set instead: `{colors.success-light}` #0A7A55 (5.07:1), `{colors.warning-light}` #8A5D00 (5.46:1), `{colors.danger-light}` #C0272A (5.59:1).

**Status is never encoded by color alone.** Every status badge, alert, and inline message pairs its color with an icon and a text label. Around 1 in 12 people cannot separate the success green from the danger red, and a transaction state is not a place to make them guess.

### Focus & Scrim

- **Focus Ring** (`{colors.focus-ring}` — #439BFF): A 2px ring at a 2px offset, so it lands on the canvas rather than on the control — **7.29:1**. The offset is what makes it work; the same color sitting *on* a Sui Blue fill measures 1.16:1 and is invisible.
- **Focus Ring on Brand** (`{colors.focus-ring-on-brand}` — #FFFFFF): For focus indicators that must render on top of a brand fill rather than beside it. 3.31:1 — clears the SC 1.4.11 non-text floor.
- **Focus Ring Light** (`{colors.focus-ring-light}` — #0061CD): 5.55:1 on `{colors.canvas-light}`.
- **Scrim** (`{colors.scrim}` — #000206): Modal backdrop at 72% opacity plus a 16px blur.

### Skeleton

- **Skeleton** (`{colors.skeleton-base}` — #002A66, sheen `{colors.skeleton-sheen}` — #003A89): Loading placeholders. The base sits 1.42:1 above `{colors.surface}` — visible as structure, quiet enough not to read as content.

## Gradients

Four gradient renders ship in the kit at 5760×3240. They are backgrounds, not accents — use them full-bleed.

### Primary — the Horizon

`Sui_Primary-Gradient.png`. The canonical Sui background: void at the top, blue dawn through the middle, ice at the bottom, with the bright band curving upward at the left and right edges.

Use `{gradients.primary-horizon}` for hero sections, splash screens, and full-page marketing floors. Place headline text in the top third where the field is #000206–#002041; text over the bright band needs `{colors.ink-light}`, not white. Never crop only the bright half and put white text on it.

### Secondary 1 — Liquid Shards

`Sui_Secondary-Gradient_1.png`. A cluster of horizontally-sheared blue slabs floating on pure black, with specular white highlights. This is the most decorative asset in the kit. Use it as a centered hero object on a `{colors.canvas}` field, or as an oversized watermark behind a section. Do not put text on top of the shard cluster — it is high-contrast and busy.

### Secondary 2 — Vertical Bars

`Sui_Secondary-Gradient_2.png`. Hard vertical stripes cycling through #F8F9FA, #298DFF, #0C5BD1, and black. The only kit asset that contains the light canvas value. Use it as a thin full-bleed divider band (48–96px tall), a card header strip, or a section transition. It is unusable as a text background at any size.

### Secondary 3 — Stepped Panels

`Sui_Secondary-Gradient_3.png`. Five vertical panels, each a soft top-to-bottom blue fade, with visible film grain. This is the most text-safe secondary — the lower two-thirds hold a stable dark field. Use it for section backgrounds and card covers. Keep the grain; it is part of the texture, not a compression artifact.

### Secondary 4 — Diagonal Cascade

`Sui_Secondary-Gradient_4.png`. A staircase of blue blocks descending left to right on black. Reads as a data structure or a chain. Use it for empty states, 404 pages, and feature illustrations where a literal blockchain metaphor is wanted.

### CSS-only gradients

**The two gradient reproductions above intentionally keep their originally sampled values.** `{gradients.primary-horizon}` and `{gradients.primary-linear}` reproduce a specific image file; they are not built from the token ramp, and the dark-end re-spacing does not apply to them. Re-deriving them from current tokens would make them stop matching the asset.

For UI surfaces where a 5760px PNG is overkill:

- `{gradients.brand-sweep}` — button and badge fills that need motion without a hue shift.
- `{gradients.brand-fade}` — top-of-section glow bleeding into the canvas.
- `{gradients.surface-veil}` — featured-card backgrounds; a quiet lift off the canvas.
- `{gradients.glow-radial}` — the ambient light behind a hero headline or above a nav bar.
- `{gradients.skeleton-sheen}` — the sweep across loading placeholders.

Gradient-filled *text* is not part of this system. Headline emphasis comes from weight and size, both of which survive text selection, high-contrast mode, and forced colors; a `background-clip: text` fill survives none of them.

## Data Visualisation

A single-hue brand gives a multi-series chart nothing. Shade alone is also the weakest encoding for colour-vision deficiency, so a blue-only "palette" of five tints is not a palette — it is five colours nobody can tell apart. This section supplies the categorical, sequential, and diverging scales the rest of the system deliberately does not contain.

**Every value here was computed and validated, not chosen.** Candidate steps were generated inside the OKLCH lightness band for each mode, then the slot order was optimised to maximise the worst adjacent pair under simulated protanopia and deuteranopia. The measured results appear below.

### The theme

Eight hue families in a **fixed order**:

| Slot | Family | Dark | Light |
|---|---|---|---|
| 1 | brand | `#298DFF` | `#0268F0` |
| 2 | green | `#009800` | `#00AC00` |
| 3 | pink | `#BA1E88` | `#CA127A` |
| 4 | amber | `#968800` | `#9E9000` |
| 5 | violet | `#883AC8` | `#8420B8` |
| 6 | orange | `#EE5C00` | `#D85200` |
| 7 | teal | `#00A898` | `#00A494` |
| 8 | red | `#C60032` | `#D6121A` |

Slot 1 is `{colors.brand}` itself, unmodified. Sui Blue measures OKLCH L 0.648 / C 0.191, which sits inside the dark band and above the chroma floor with no adjustment — the brand is a legal chart colour as shipped, so the first series a reader sees is the brand.

**The order is the safety mechanism and never changes.** Assign slots in sequence: one series takes slot 1, three series take slots 1–3. Never cycle, never reorder to suit a chart, and never generate a ninth hue — a ninth series folds into "Other", becomes small multiples, or the chart is the wrong form.

**Colour follows the entity, not its rank.** A filter that removes series does not repaint the survivors; "Validators" stays slot 2 whether it is second or fifth in the sorted list.

### Measured results

| Check | Dark (on `chart.surface-dark`) | Light (on `chart.surface-light`) |
|---|---|---|
| Lightness band | all 8 inside 0.48–0.67 | all 8 inside 0.43–0.77 |
| Chroma floor | all 8 ≥ 0.10 | all 8 ≥ 0.10 |
| Worst adjacent pair, CVD | **ΔE 15.4** (deutan) | **ΔE 14.5** (deutan) |
| Worst adjacent pair, normal vision | **ΔE 29.6** | **ΔE 28.3** |
| Contrast vs surface | all 8 ≥ 3:1 | all 8 ≥ 3:1 |

The CVD target is ΔE 8 and the normal-vision floor is 15; both modes clear them with roughly double the margin.

### The three-series cap on all-pairs forms

Line, bar, and stacked charts only put *adjacent* slots next to each other, so all eight are usable. Scatter, bubble, choropleth, and small-multiple charts can place **any** two marks side by side, and under that harder test the palette carries **three series** (`chart.all-pairs-cap`). Slots 4 and 2 — amber and green — collapse to ΔE 0.9 under protanopia when they can touch.

This is a property of eight distinct hues, not a defect in these eight. No reordering fixes it. Past three series in an all-pairs form, reduce the series count, facet into small multiples, or change the chart form.

### Status never becomes a series

`{colors.success}`, `{colors.warning}`, and `{colors.danger}` are reserved. They sit close to two categorical slots — success is ΔE 6.9 from slot 7 (teal), danger is ΔE 6.9 from slot 6 (orange) — and a constrained re-solve that forced ΔE ≥ 10 from all three status hues could not satisfy the adjacent-separation gates at eight slots. The separation is therefore enforced by rule rather than by distance:

**Status colours and categorical colours never appear in the same chart.** When a series *means* good or bad — error rate, pass/fail, health — it wears status tokens. When it is merely "series 4", it wears categorical. Never both. Status always ships with an icon and a label, which categorical never does; that pairing is what keeps the two readable side by side across a dashboard.

### Sequential — magnitude

One hue, monotone lightness. `chart.sequential-dark` runs `#004CAF` → `#C3E0FF`; `chart.sequential-light` runs `#72B3FF` → `#001944`. Both validate as ordinal ramps: monotone lightness, every adjacent gap ≥ 0.06 ΔL, single hue within 6–9°, and the faint end clearing 2:1 against its surface (2.62:1 dark, 2.19:1 light).

Note the direction flips. On the dark canvas, more magnitude means *brighter*; on paper it means *deeper*. A sequential ramp is anchored to its surface, never mechanically inverted.

Use sequential only for magnitude, and use it for ordered categories too — funnel stages, size tiers, age bands — where the reader should see the order in the colour.

### Diverging — polarity

Two hues around a neutral midpoint, for values that sit on either side of a baseline: net flow, price change, delta against a target.

`chart.diverging-dark` and `chart.diverging-light` both run **blue ↔ orange**, not red ↔ green — red-green diverging is unreadable for the most common colour-vision deficiency. Each arm holds its hue within 3° and steps evenly: ΔL 0.084–0.098 on dark, 0.098–0.109 on light.

The midpoint is `chart.zero-dark` (#424242) or `chart.zero-light` (#D5D5D5), both at **OKLCH chroma 0.000**. These are the only true greys in this system, and their neutrality is the point — any hue at the midpoint reads as a third category and destroys the "this value is zero" signal. This is a deliberate, scoped exception to the system's no-grey rule.

The neutral midpoint and the steps beside it fall below 3:1 by construction, because near-zero is *supposed* to recede. Diverging fills therefore require a relief channel: visible cell values, a colour legend with numbers, or the table view.

### Chart chrome

- **Grid and axis lines** — `chart.grid` (#003A89) at 1px, 1.83:1 on the chart surface. Grid is a reference, not content; it stays recessive and horizontal-only on bar and line charts.
- **Tick labels** — `chart.tick-label` (#72B3FF), 8.93:1.
- **Value and direct labels** — `chart.value-label` (#C3E0FF), 14.34:1.
- **Title** — `chart.title` (#FFFFFF), 19.52:1.

**Text always wears text tokens, never the series colour.** A coloured mark sits beside the label and carries the identity; tinting the number itself costs contrast and gains nothing.

### Rules that hold for every chart

- **One axis.** Never two y-scales. Two measures of different magnitude become two charts, small multiples, or values indexed to a common base.
- **Colour is never the only channel.** Two or more series always have a legend; four or fewer are also direct-labelled. A table view exists for every chart.
- **Thin marks.** 2px lines, ≥8px markers, a 2px surface gap between adjacent fills and stacked segments, and a 2px surface ring where marks overlap.
- **Dark mode is composed, not flipped.** `chart.categorical-dark` and `chart.categorical-light` are separate solves against separate surfaces. Never invert one to make the other.
- **No decoration standing in for data.** Sparklines, progress rings, and soft rounded rectangles are not content. If there is a number, show the number.

## Typography

### The stack

The media kit ships four families under `Sui_Typography_Alternates`, all SIL Open Font License:

- **Inter Tight** (variable, `wght`; static Thin→Black + italics) — display and headings.
- **Inter** (variable, `opsz` + `wght`; static 18pt/24pt/28pt optical sizes + italics) — body, UI, labels.
- **DM Mono** (Light / Regular / Medium + italics) — addresses, hashes, balances, code, and data overlines.
- **Noto Sans** (variable, `wdth` + `wght`; Condensed / SemiCondensed / ExtraCondensed statics) — multilingual fallback for scripts Inter does not cover.

Prefer the variable files. If a project pins static cuts, Inter's optical sizes matter: use `Inter_18pt` below 20px, `Inter_24pt` from 20–32px, `Inter_28pt` above.

### The split

Display and headings use **Inter Tight**; body and UI use **Inter**. This is deliberate — Inter Tight's narrower sidebearings let 56–72px headlines set densely without manual kerning, while regular Inter keeps body copy open and readable. The crossover is at 18px: `{typography.heading-sm}` (18px/600) is the first step that returns to Inter.

### Tracking

Display sizes carry negative tracking that scales with size: -0.03em at 72px, -0.025em at 44–56px, -0.02em at 36px, -0.015em at 28px, easing to 0 at body sizes. Never apply negative tracking below 18px.

`{typography.overline}` is the exception — DM Mono uppercase at +1.2px (+0.1em) positive tracking. Its scope is narrow and deliberate: **column headers, metric captions, and legend keys inside data displays.** It is not a section-label device. A small colored label floating above a heading adds no information the heading does not already carry, and it costs the heading its opening position; write the heading so it does the work alone.

### Monospace roles

This is blockchain UI, so mono is structural rather than decorative:

- `{typography.address-mono}` (DM Mono 300 / 13px) — object IDs, addresses, digests. Always truncate middle-out (`0x1a2b…9f8e`), never at the tail.
- `{typography.code-md}` / `{typography.code-sm}` — code blocks and inline code.
- `{typography.numeric-display}` (DM Mono 500 / 40px) — balances and stat tiles. DM Mono's tabular figures keep columns of numbers aligned as values change.

### Weights in use

400 body, 500 labels/buttons/nav, 600 headings, 700 display only. The system never uses 800/900 — Inter Tight at 700 with tight tracking already reads as heavy, and the extra weights break the engineered feel.

## Layout

- **Grid**: 12 columns, 24px gutters, 24px page margin on desktop / 16px on mobile.
- **Content max-width**: 1280px for app shells, 1120px for marketing, 680px for long-form prose. The prose figure is derived, not chosen: at `{typography.body-md}` in Inter, 680px lands at roughly 70 characters per line, inside the 65–75ch band where reading speed peaks. Setting it by round number instead — 720px, 768px — pushes the measure past 75ch and the reader starts losing their place on line returns.
- **Vertical rhythm**: 8px base. Component internals use `{spacing.sm}`–`{spacing.lg}`; section gaps use `{spacing.section}` (96px) on marketing pages and `{spacing.xl}` (32px) inside app surfaces. `{spacing.section-lg}` (160px) is reserved for the space above and below a full-bleed gradient band.
- **Header**: 72px tall, sticky, `rgba(0,2,6,0.72)` with a 16px backdrop blur and a `{colors.hairline-soft}` bottom rule. It becomes opaque once the page scrolls past the hero.
- **Gradient bands**: full-bleed, edge to edge, ignoring the content max-width. Content inside the band still respects it.
- **Icon grid**: 24px default with a 1.5px stroke; 20px in dense tables; 32px for feature marks.

## Elevation

On a #000206 canvas a shadow has almost nowhere to darken into. Depth is therefore built from the surface ladder first, with light used sparingly on top.

**1. Surface lift — the primary mechanism.** Each level moves one step up the re-spaced ramp: `{colors.canvas}` → `{colors.surface}` → `{colors.surface-raised}` → `{colors.surface-overlay}`, at a consistent OKLCH ΔL of about 0.072 per step. This is what carries ordinary depth. Before the re-spacing the intervals were uneven and the overlay step was the tightest of all, which is why glow was doing work the ladder should have done.

**2. Blue glow — an accent, not a mechanism.** A low-opacity `rgba(41,141,255, …)` halo. It is now reserved for exactly two states: the focused input and the primary action on hover. A zero-offset chromatic halo on every card is the default look of machine-generated dark UI, and it is not this system's depth model.

- `{elevation.flat}` — page-level content, table rows, dividers.
- `{elevation.raised}` — resting cards and panels. An inset 1px `{colors.hairline}` top edge plus a soft, offset dark shadow.
- `{elevation.overlay}` — modals, dropdowns, toasts. Full ring plus a deep shadow to separate from the scrim.
- `{elevation.glow-soft}` — card hover. The card lifts to `{colors.surface-raised}`, which is now a visible step on its own; the 40px halo is a light accent on top of that move, not the move itself.
- `{elevation.glow-brand}` — focused inputs and the primary CTA on hover. A hard 1px brand ring plus a 24px halo.

Borders remain load-bearing at the darkest levels. Contrast ratio compresses near black, so a card sitting on the canvas is separated as much by its `{colors.hairline}` rule — 1.94:1 on canvas, up from 1.51:1 before the re-spacing — as by the fill beneath it. Never ship a dark-theme card with neither a border nor a surface step.

In light mode, revert to conventional shadows: `{elevation.light-raised}` and `{elevation.light-overlay}`. Do not carry the glow into light mode — it reads as a rendering bug on white.

## Components

### Buttons

Every button is a **pill** (`{rounded.full}`). Three tiers:

- `{component.button-primary}` — 48px tall, brand fill, **navy label** (`{colors.on-brand}`), 24px horizontal padding. One per view. Hover brightens to `{colors.brand-hover}` (7.29:1); press moves to `{colors.brand-active}` (5.28:1); disabled drops to `{colors.brand-disabled}` with `{colors.ink-muted}` text (6.31:1).
- `{component.button-primary-solid}` — the alternate lockup: `{colors.brand-solid}` fill with a white label at 5.85:1. Use it only when a project constraint requires white-on-blue; it trades brand voltage for that constraint.
- `{component.button-primary-loading}` — the pending state. The label stays put, a 16px spinner takes the leading icon slot, `aria-busy="true"` is set, and the button width is locked before the swap so nothing reflows. The button is not disabled during load — it is *busy*, and a disabled button drops out of the tab order, which strands keyboard users mid-flow.
- `{component.button-secondary}` — same metrics, transparent fill, 1px `{colors.hairline-interactive}` outline (3.55:1), `{colors.ink}` label. Hover fills to `{colors.surface-raised}` and the border goes to `{colors.brand}`.
- `{component.button-ghost}` — 40px, no fill, no border, `{colors.ink-body}` label. Toolbars and card footers. Hover fills to `{colors.surface-raised}`.
- `{component.button-danger}` — destructive actions. A `{colors.danger-subtle}` tint with a full `{colors.danger}` border and label, not a solid red fill: a solid destructive button competes with the primary CTA for attention on every screen it appears on.

`{component.button-sm}` (36px) is the dense variant for table rows and inline actions. `{component.icon-button}` is a 40px circle on `{colors.surface-raised}` inside a 44px hit area, and always carries an `aria-label` — an icon alone has no accessible name.

Every button in this system is a real `<button>`. None is a styled `<div>`.

### Navigation

`{component.top-nav}` is 72px, translucent, blurred. Links use `{typography.nav-link}` in `{colors.ink-muted}`; the active item goes to `{colors.ink}` — there is no underline or pill on the active nav link at the top level. Sub-navigation uses `{component.tab-active}` / `{component.tab-inactive}`, which *are* pills.

The full logo sits left at 28–32px cap height; the droplet alone replaces it below the `md` breakpoint.

### Cards

- `{component.card}` — `{colors.surface}` fill, `{rounded.lg}` (16px), 24px padding, `{colors.hairline-soft}` border.
- `{component.card-hover}` — lifts to `{colors.surface-raised}`, border to `{colors.hairline}`, plus `{elevation.glow-soft}`. Transition at `{motion.duration-base}` on `{motion.ease-standard}`.
- `{component.card-featured}` — `{rounded.xl}` (24px), 32px padding, `{gradients.surface-veil}` background. Used for the one card per grid that must be the entry point.
- `{component.stat-tile}` — `{rounded.md}`, a `{typography.overline}` caption above a `{typography.numeric-display}` value. The value reserves width for its largest plausible magnitude so the tile does not resize as figures update.

### Forms

`{component.text-input}` is 48px tall, `{rounded.md}` (12px), `{colors.surface}` fill, `{colors.hairline-interactive}` border (3.55:1). Focus swaps the border to `{colors.brand}` and applies `{elevation.glow-brand}` — the focus treatment is a glow, not an offset ring, on filled inputs. Standalone focusable elements (links, checkboxes, tabs) use the 2px `{colors.focus-ring}` outline with a 2px offset instead.

The input font size is 16px (`{typography.body-md}`) and cannot be reduced. iOS Safari force-zooms the viewport on any focused input below 16px, which throws the layout sideways mid-form and does not zoom back out.

**Every field ships four states beyond its resting one:**

- `{component.text-input-focus}` — brand border plus glow.
- `{component.text-input-error}` — `{colors.danger}` border, `aria-invalid="true"`, and a `{component.input-error-message}` beneath. The message is prefixed by a 16px alert icon and announced through `aria-live="polite"`. Error color alone is not a state.
- `{component.text-input-disabled}` — drops to the `{colors.canvas}` fill with `{colors.ink-disabled}` text (3.34:1), signalling inert without making the value unguessable.
- `{component.text-input-readonly}` — same canvas fill but full `{colors.ink-body}` text: the value matters, the field simply is not editable here.

Placeholders use `{colors.ink-placeholder}` at 8.93:1 — a placeholder carries the field's format hint and is held to the same floor as body text. Labels use `{component.input-label}` sitting 8px above the field, and every input has one; placeholder-as-label vanishes the moment the user types. `{component.input-required}` marks required fields with a `{colors.danger}` asterisk *and* the word "required" in the helper line.

**Error copy names the problem and the recovery.** "Invalid input" names neither. "Enter an address starting with 0x, 66 characters long" names both.

### Data display

`{component.table-header}` is 44px, `{colors.surface}`, `{typography.label-sm}` in `{colors.ink-muted}`. `{component.table-row}` is 56px on a transparent fill with a `{colors.hairline-soft}` bottom rule, with `{component.table-row-hover}` and `{component.table-row-selected}` for the two interactive states. Numeric and address columns right-align and use `{typography.address-mono}` / `{typography.numeric-display}` at the appropriate size.

`{component.address-chip}` wraps any on-chain identifier: `{rounded.sm}`, `{colors.surface-raised}` fill, monospace. **The copy affordance is persistent, not hover-revealed** — it appears on `:hover, :focus-within` on fine pointers and is always visible on coarse ones. Copying an object ID is a primary task in this product category, and hiding it behind hover puts it out of reach of every touch and keyboard user.

**Large result sets.** Tables paginate or virtualise past 100 rows — never render 10,000 at once. Sort and filter controls sit above the header, not inside it. Column count reduces before row height does: dropping a column is recoverable through a detail view, while a cramped row is not.

Sorted and filtered states are announced, not merely styled: the active sort column carries `aria-sort` and a direction glyph, so the state survives for screen-reader and monochrome users.

### Code

`{component.code-block}` sits on `{colors.surface-sunken}` — one step *below* the surrounding card, so code recedes rather than pops. `{component.inline-code}` uses the `{colors.brand-subtle}` tint with `{colors.ink-code}` text.

This is a defect the token extraction exposed. The code block previously pointed at the raw ramp step `blue-900`, which is the identical value to `{colors.surface}` — so code blocks rendered exactly level with the cards containing them while the prose claimed they sat lower. Naming the role made the collision visible: `surface-sunken` resolves to `{palette.blue-950}` and the block now genuinely recedes. Reaching past the semantic layer is how that class of drift gets in.

### Feedback

`{component.toast}` and `{component.modal}` both use `{elevation.overlay}`. The modal scrim is `{colors.scrim}` at 72% with a 16px blur. A modal traps focus on open, returns focus to its trigger on close, closes on `Escape`, and is reserved for tasks that genuinely need protected focus — a confirmation that can live inline should live inline.

Badges: `{component.badge-brand}` for brand-relevant states, `{component.badge-neutral}` for everything else, and `{component.badge-success}` / `{component.badge-warning}` / `{component.badge-danger}` for status. Status badges pair the semantic tint fill with a matching 1px border, a 16px icon, and a text label — three cues, so the state survives colour-vision deficiency and monochrome rendering.

`{component.alert-info}` and `{component.alert-danger}` carry longer messages. Both use a tint fill with a full 1px border and a leading icon — **not a thick colored left border**, which reads as a template device rather than as part of this system. Danger alerts announce through `aria-live="assertive"`; informational ones do not announce at all.

`{component.tooltip}` is supplementary only. Any information a user needs to complete a task lives in `{component.input-helper}` or in the visible label — never in a tooltip, which has no touch equivalent.

### The status surface pattern

Six components — the three status badges, both alerts, and `{component.button-danger}` — are the same composition with one variable. Extracting it makes the rule explicit and tells you exactly what a seventh looks like:

```
backgroundColor: {colors.<status>-subtle}   ← 12% tint of the hue
borderColor:     {colors.<status>}          ← 1px, the full hue
textColor:       {colors.<status>}          ← on dark; {colors.ink-body} for long copy
icon:            required                   ← the non-colour channel
```

Long-form surfaces (alerts) move the text to `{colors.ink-body}` because a paragraph set in a saturated status hue is tiring to read; short surfaces (badges, buttons) keep the hue, where it reads as a label rather than as prose. Every instance measures between 5.53:1 and 8.16:1 on its own tint.

Adding a status means adding the three primitives (`<hue>-500`, `<hue>-700`, `<hue>-tint`), the three semantics, and nothing else. Never hand-mix a one-off tint at the component.

## States & Edge Cases

A component is not finished at its resting state. Every interactive element in this system ships **hover, focus, active, disabled, loading, error, and empty** — and the states below are the ones designs most often omit and production most often needs.

### Loading

Three mechanisms, chosen by what is known:

- **Skeleton** (`{component.skeleton}`) — when the shape of the incoming content is known. Mirror the real layout: a table skeleton has rows of the right height, not a grey block. The sheen sweeps over `{motion.duration-ambient}` and holds static under `prefers-reduced-motion`.
- **Inline busy** (`{component.button-primary-loading}`) — when one control triggered the work. The control reports `aria-busy`, keeps its label and its width, and stays in the tab order.
- **Progress with a figure** — when the operation exceeds roughly two seconds or has known steps. A blockchain confirmation is the common case: name the phase ("Submitting", "Awaiting finality"), never an unlabelled spinner.

Content never shifts when loading resolves. Reserve the space first.

### Empty

An empty state has three parts: a heading in `{typography.heading-md}` on `{colors.ink}`, one sentence of cause in `{colors.ink-muted}`, and one primary action. `{component.empty-state}` supplies the frame.

Distinguish the three cases that look identical and are not — **nothing yet** (invite the first action), **nothing found** (offer to clear the filter, and echo the query back), and **nothing permitted** (say who can grant access). Collapsing them into one "No data" is how a filter bug becomes a support ticket.

### Error

Errors name what happened and what to do next, in the product's own language. Reserve `{component.alert-danger}` for failures the user must act on; use inline `{component.input-error-message}` for anything a single field can fix.

Recovery is always offered. A failed network call gets a retry control; a rejected transaction gets the reason and a path back to the form with the input preserved. Never discard what the user typed.

An error in one component never blanks the page. Scope failure to the smallest region that owns it.

### Disabled versus busy

These are different and the distinction matters for keyboard users. **Disabled** means the action is unavailable and stays out of reach; it leaves the tab order, so pair it with a reason the user can find. **Busy** means the action is running; it keeps focus and the tab order and reports `aria-busy`. Never disable a button merely to prevent a second submit — mark it busy and ignore repeat activations.

### Permission and read-only

Read-only surfaces use `{component.text-input-readonly}`, which keeps the value at full contrast. Restricted surfaces say what is restricted and who can lift it. A silently missing control reads as a broken build.

## Content Resilience

The values in this file assume real content, which is longer, shorter, and in more languages than any mock.

### Overflow

- **Single-line labels** (nav links, buttons, table cells) truncate with an ellipsis and expose the full string through `title` or a tooltip. Flex and grid children carry `min-width: 0`, without which they refuse to shrink and push the layout sideways instead.
- **Headings** wrap. They never truncate — a cut headline loses the sentence. Use `text-wrap: balance` at display sizes.
- **Card and list body copy** clamps to a fixed line count so a grid stays even.
- **Addresses and hashes** truncate middle-out (`0x1a2b…9f8e`) and never at the tail; the last characters are what people verify against.
- **Numbers** never truncate. A shortened balance is a wrong balance. Abbreviate deliberately (`1.24M SUI`) with the full figure available on hover and focus.

### Internationalisation

- **Budget 30–40% extra width** on every label. German and Finnish routinely run that much longer than English, and this system's pill buttons size to their content, so the room has to exist in the layout rather than in the component.
- **Use logical properties** — `padding-inline`, `margin-inline-start`, `border-inline-end` — throughout. Sui operates globally and Arabic RTL support costs nothing if the properties are logical from the start, and a full retrofit if they are not. Directional icons mirror under `[dir="rtl"]`; logos, charts, and clock faces do not.
- **CJK needs air.** Chinese, Japanese, and Korean set at a taller line-height — raise `{typography.body-md}` from 1.6 to about 1.8 — and take **no** negative tracking. The display tracking in this file is Latin-only; zero it out for CJK, where tight spacing collapses glyph legibility.
- **Never concatenate translated fragments.** Word order differs; build whole sentences per locale.
- **Format through `Intl`.** Dates, numbers, and currency vary by locale in ways no template string survives. Pair every timestamp with its timezone, and mark relative times ("2 min ago") with the absolute value on hover.
- **Plurals go through the locale's own rules.** Several languages have more than two plural forms; `count === 1` is an English assumption.
- **The font stack must cover the script.** Inter does not include CJK glyphs. Noto Sans is the declared fallback precisely for this — keep it in the stack rather than letting the browser choose.

### Numbers and on-chain values

Balances, gas figures, and token amounts render in `{typography.numeric-display}` or `{typography.address-mono}` with `font-variant-numeric: tabular-nums`, so digits hold their column as values update. Never round a balance without showing the full precision somewhere adjacent. Always pair an amount with its unit and, where the figure is fiat-converted, with the conversion basis.

## Accessibility Contract

These are floors, not goals. Every value here is measured against the tokens in this file.

| Element | Floor | Token pairing | Measured |
|---|---|---|---|
| Body and placeholder text | 4.5:1 | `ink-body` on `canvas` | 15.25:1 |
| Muted and caption text | 4.5:1 | `ink-muted` on `canvas` | 9.50:1 |
| Placeholder | 4.5:1 | `ink-placeholder` on `surface` | 8.93:1 |
| Filled-control label | 4.5:1 | `on-brand` on `brand` | 6.28:1 |
| Control boundary | 3:1 | `hairline-interactive` on `canvas` | 3.55:1 |
| Focus indicator | 3:1 | `focus-ring` offset onto `canvas` | 7.29:1 |
| Status text | 4.5:1 | `danger` on `surface` | 5.97:1 |
| Links | 4.5:1 | `link` on `canvas` | 9.50:1 |

Beyond contrast:

- **Keyboard reaches everything.** Every action has a keyboard path, tab order follows visual order, modals trap and restore focus, and a skip link precedes long content. Focus is never removed without a replacement indicator.
- **Colour is never the only channel.** Status carries an icon and a label. Sort direction carries a glyph. Required fields carry the word, not just the asterisk.
- **Motion is optional.** Under `prefers-reduced-motion`, gradient drift, glow pulsing, and the skeleton sweep stop; colour and opacity transitions remain, because removing them destroys the feedback that a state changed. Never blanket-disable to `0.01ms`.
- **Forced colours are respected.** Under `forced-colors: active`, drop the glow elevation and the gradient surfaces, and let system colours through. Do not paint over them — the user chose them.
- **Text scales.** The layout survives 200% zoom and a 200% text-only increase without clipping or horizontal scroll. This is why no text container in this system carries a fixed height.
- **Icons have names.** Any icon-only control carries an `aria-label`; decorative marks carry `aria-hidden`.

## Motion

- `{motion.duration-fast}` (120ms) — hover and press feedback on buttons, chips, rows.
- `{motion.duration-base}` (200ms) — card lifts, tab switches, input focus, dropdown open.
- `{motion.duration-slow}` (400ms) — modal and drawer entry, page-section reveals.
- `{motion.duration-ambient}` (1200ms+) — gradient drift and glow pulsing. Ambient only; never gates an interaction.

Easing is `{motion.ease-standard}` for state changes and `{motion.ease-out}` for entrances. Motion carries meaning through **luminance and glow**, not through translation — elements brighten and halo rather than sliding. Respect `prefers-reduced-motion` by disabling gradient drift and glow animation entirely; keep the color transitions.

## Responsive Behavior

Breakpoints: `sm` 640px, `md` 768px, `lg` 1024px, `xl` 1280px, `2xl` 1536px.

- **Display type** steps down one full tier per breakpoint below `lg`: `{typography.display-2xl}` (72px) → 56px at `lg` → 44px at `md` → 36px at `sm`. Negative tracking scales with it.
- **Header** collapses to 64px below `md`, the full logo swaps to the droplet, and nav links move into a full-screen sheet on `{colors.canvas}`.
- **Grid** goes 12 → 8 columns at `md`, → 4 at `sm`. Card grids go 3-up → 2-up → 1-up.
- **Section spacing** drops from `{spacing.section}` (96px) to 64px at `md` and 48px at `sm`.
- **Gradient heroes** keep the ellipse anchored at 50% but tighten to `ellipse 180% 90%` below `md`, so the bright band still resolves inside a tall viewport.
- **Tables** become stacked cards below `md`; the address column stays monospace and truncates harder (`0x1a2b…8e`).
- **Touch targets** are never below 44px — but that floor applies to the *hit area*, not the painted control. `{component.icon-button}` paints at 40px and `{component.address-chip}` at 26px; both centre inside a 44px target. `{component.button-sm}` (36px) is the one exception with no padded target, and is therefore desktop-only. State which mechanism a component uses; never leave it implied.

## Logo & Asset Usage

The kit ships two marks, each in Black, White, and Sui Blue, as SVG / PNG / EPS:

- **Full logo** — `01_Sui_Logo/Sui_Full_Logo/`, 1914×1001 (≈1.912:1). Droplet plus the "Sui" wordmark. The default lockup for headers, footers, and documents.
- **Droplet** — `01_Sui_Logo/Sui_Droplet/`, 783×1000 (≈0.783:1). The standalone mark for favicons, app icons, avatars, mobile headers, and any square container.

Variant selection: **White** (`{colors.logo-white}`) on `{colors.canvas}`, on the dark half of any gradient, and on photography. **Black** (`{colors.logo-black}`) on `{colors.canvas-light}` and `{colors.paper}` — this is the one place pure #000000 appears in the system, because it is the shipped asset rather than a chosen value. **Sui Blue** only on white or near-white surfaces where the mark itself must carry the brand voltage — never on the blue gradient, where it disappears.

Prefer SVG everywhere on the web. EPS is for print. The PNGs are RGBA at their native sizes; downscale, never upscale.

Clear space and minimum sizes are **not specified in the media kit**. The values below are a working convention derived from the mark geometry — see **Known Gaps**:

- Clear space: on all sides, equal to the width of the droplet's stem (roughly 25% of the droplet's width; ≈0.2× the full logo's height).
- Minimum size: full logo 96px wide on screen, droplet 24px. Below that, use the droplet only.
- Do not: recolor outside the three shipped variants, apply effects or outlines, place the Black variant on a dark field, stretch away from the native aspect ratios, or rebuild the wordmark in Inter — the wordmark is custom-drawn outlines, not set type.

## Known Gaps

This document is reverse-engineered from the media kit files alone. No brand guidelines PDF, website, or design-token export was available. The following are honest gaps:

1. **No numeric palette specification.** The kit contains exactly one literal color (`#298DFF`) plus black and white. The entire `blue-950`→`blue-050` ramp, all surface tokens, and all text tokens were **sampled from the gradient PNGs**, not read from a spec. They are accurate to the rendered assets but are not published Sui token values.
2. **The primary typeface is missing.** The folder is named `Sui_Typography_Alternates` and contains only OFL substitutes. A proprietary Sui brand face almost certainly exists and is not in the kit. The Inter Tight / Inter / DM Mono / Noto Sans mapping in this document — including which family gets display versus body — is a judgment call, not a documented rule.
3. **No status colors.** `success`, `warning`, `danger`, their 12% tints, and their darkened light-theme counterparts are extensions chosen to coexist with the blue. Every one is contrast-verified against this system's surfaces, but none is a published Sui value. Verify against official Sui product surfaces before shipping.
4. **No spacing, radius, elevation, or motion spec.** The kit is logos, fonts, and gradients only. The 8px rhythm, radius scale, glow-based elevation model, and motion durations are all derived from the mark's soft geometry and the dark-canvas constraint.
5. **No component library.** Every entry under `components:` is inferred. They are internally consistent, contrast-verified, and follow the palette and shape logic, but no component in this document was measured from a real Sui interface.
6. **No logo clear-space or minimum-size rules.** The values in **Logo & Asset Usage** are derived from the mark's proportions.
7. **The light theme is derived, not documented.** Only two light values exist in the kit (`#F8F9FA` and `#EFF7FF`, both from gradient renders). Everything else in light mode — interactive borders, links, focus, status — was constructed here and contrast-verified. It is complete enough to build against; it is not a documented Sui counterpart to the dark theme.
8. **No iconography.** The kit ships no icon set. The 24px / 1.5px-stroke convention is a recommendation matched to the type sizes, not a brand asset. Several rules in **States & Edge Cases** and **Accessibility Contract** assume an icon set exists — supply one before building.
9. **The data-visualisation palette is computed, not brand-issued.** The media kit contains no chart colours at all. Slot 1 is `{colors.brand}` unmodified; the other seven hue families, all three scales, and both midpoint greys were generated inside the OKLCH bands and optimised against simulated protanopia and deuteranopia. Every number in **Data Visualisation** is measured and reproducible, but the seven non-brand hues are this document's invention, not Sui's. Treat them as a working default to be confirmed, and note that they introduce hues — and two true greys — that exist nowhere else in the system.

### Outstanding fixes, deliberately not made here

10. ~~**The dark ramp is unevenly spaced.**~~ **Resolved.** Five steps between `blue-950` and `blue-600` were re-solved at even OKLCH lightness targets along the same hue and chroma curve; every interval is now ΔL 0.068–0.076, against 0.042–0.076 before. The ramp is renumbered on a conventional 50–950 scale with the brand on step 500. One correction to the original finding: it was stated in contrast ratios (1.04–1.11:1), which overstates the problem — the WCAG flare constant compresses all near-black pairs, and the steps were irregular rather than collapsed. `canvas` → `surface` still reports 1.06:1 and always will; borders stay load-bearing at that level by design.
11. ~~**Semantic tokens state values rather than referencing them.**~~ **Resolved.** Colour is now a two-layer system: 30 primitives holding every literal hex, and 62 semantics that only reference them. See **Token architecture**. Three invariants are mechanically checkable and currently hold — no semantic contains a hex, no primitive contains a reference, and no component addresses a primitive.
