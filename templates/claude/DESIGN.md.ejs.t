<%_
  // "my-app" → "My App"
  const title = pkg.name.replace(/[-_]/g, ' ').replace(/\b\w/g, (c) => c.toUpperCase())

  const deps = { ...pkg.dependencies, ...pkg.devDependencies }
-%>
---
version: alpha
name: <%- title %>
description: Design system for the SvelteKit 2 + Svelte 5 app, built on Tailwind CSS v4 defaults with a Svelte-orange brand accent
colors:
  primary: '#FF3E00'
  primary-hover: '#E63600'
  ink: '#0A0A0A'
  muted: '#525252'
  border: '#E5E5E5'
  surface: '#FFFFFF'
  background: '#FAFAFA'
  success: '#16A34A'
  warning: '#D97706'
  danger: '#DC2626'
typography:
  h1:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: 700
    lineHeight: 1.1
    letterSpacing: -0.02em
  h2:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: 600
    lineHeight: 1.2
    letterSpacing: -0.01em
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: 400
    lineHeight: 1.6
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: 500
    lineHeight: 1
    letterSpacing: 0.08em
  mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: 400
    lineHeight: 1.5
rounded:
  sm: 4px
  md: 8px
  lg: 12px
  full: 9999px
spacing:
  base: 16px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 32px
  xl: 64px
  gutter: 24px
  margin: 32px
components:
  button-primary:
    backgroundColor: '{colors.primary}'
    textColor: '{colors.ink}'
    rounded: '{rounded.md}'
    padding: 12px
  button-primary-hover:
    backgroundColor: '{colors.primary-hover}'
  button-secondary:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.ink}'
    rounded: '{rounded.md}'
    padding: 12px
  card:
    backgroundColor: '{colors.surface}'
    rounded: '{rounded.lg}'
    padding: 24px
  input:
    backgroundColor: '{colors.surface}'
    textColor: '{colors.ink}'
    rounded: '{rounded.md}'
    padding: 12px
---

## Overview

A clean, modern SvelteKit application UI. Personality: precise, fast, unfussy — the
interface gets out of the way. Built on Tailwind CSS v4 default scales with a single
bold brand accent (Svelte orange) reserved for the most important action on a screen.
Light mode only for now (`color-scheme: light`).

Audience: developers and product users who value speed and clarity over decoration.

## Colors

Neutral-first palette. Color carries meaning, not decoration.

- **Primary (#FF3E00):** Svelte orange. Primary actions and active states only — one per screen. Pair with ink (#0A0A0A) text, not white — white-on-orange fails WCAG AA.
- **Primary hover (#E63600):** Darker orange for hover/pressed states of brand elements.
- **Ink (#0A0A0A):** Near-black for headlines and primary text.
- **Muted (#525252):** Secondary text, metadata, placeholder.
- **Border (#E5E5E5):** Hairline borders, dividers, input outlines.
- **Surface (#FFFFFF):** Cards, inputs, raised content.
- **Background (#FAFAFA):** Page background behind surfaces.
- **Success / Warning / Danger:** Status only — toasts, validation, badges. Never decorative.

## Typography

Single typeface for UI: **Inter** (system-ui fallback). **JetBrains Mono** for code and
numeric/technical labels. Type scale uses Tailwind v4 defaults.

- **Headings (Inter 600–700):** Tight tracking, establish hierarchy.
- **Body (Inter 400, 16px):** Default reading size, 1.6 line-height.
- **Labels (Inter 500, uppercase + tracking):** Eyebrows, table headers, chips.
- **Mono (JetBrains Mono):** Inline code, tokens, IDs.

## Layout

Fluid below `md`, fixed max-width (1280px / Tailwind `7xl`) centered for desktop.
8px spacing scale with 4px micro-steps. Cards use 24px internal padding. Content
sections separated by 32px (`lg`).

## Elevation & Depth

Depth comes from tonal layering, not heavy shadows. Surfaces (#FFFFFF) sit on the
off-white background (#FAFAFA) and are separated by 1px borders. Reserve soft shadows
for transient overlays only (dropdowns, popovers, toasts).

## Shapes

8px (`md`) default radius on interactive elements. 12px (`lg`) on cards and larger
containers. `full` for pills, avatars, and icon buttons. Consistent — no mixed radii
within one component.

## Components

Standardized primitives live in `src/lib/components/ui/`. Buttons (primary/secondary),
inputs, and cards share the token set above.
<% if (deps['@tailwindcss/forms']) { -%>
`@tailwindcss/forms` normalizes form controls.
<% } -%>
<% if (deps['@tailwindcss/typography']) { -%>
`@tailwindcss/typography` styles long-form prose (`prose` class).
<% } -%>

- **Primary button:** Brand background, surface text, `md` radius. One per screen.
- **Secondary button:** Surface background, ink text, 1px border.
- **Card:** Surface background, 1px border, `lg` radius, 24px padding, no shadow.
- **Input:** Surface background, 1px border, `md` radius; brand ring on focus.

## Do's and Don'ts

- Do limit brand orange to **one** primary action per screen.
- Do maintain WCAG AA contrast (4.5:1 body text minimum).
- Do use Tailwind utility classes from the token scale — never arbitrary one-off hex values.
- Do keep components in `src/lib/components/ui/` and `src/lib/components/layout/`.
- Don't add drop shadows to cards — use the 1px border for separation.
- Don't introduce a second accent color; status colors are for status only.
- Don't use more than two font weights in a single view.
- Don't hardcode pixel values where a spacing/rounded token exists.
- Don't add dark-mode styles yet — the app is light-mode only.
