# OrniFlight Studio — Design System & Theme Guide

## Overview

The OrniFlight Studio design system is built on **CSS custom properties** (variables)
with a `--of-` prefix (OrniFlight). This enables runtime theme switching via a single
`data-theme` attribute on `<html>`, with preference persisted to `localStorage`.

**File locations:**
- `src/styles/_tokens.sass` — All design tokens (colors, typography, spacing, shadows, timing, layout)
- `src/styles/main.sass` — Global styles, component classes, theme variants
- `src/components/ThemeToggle.coffee` — Toggle component + localStorage persistence
- `index.html` — Font loading (Orbitron from Google Fonts)

## Theme Switching

### Mechanism

```html
<!-- Dark (default) -->
<html> ... </html>

<!-- Light -->
<html data-theme="light"> ... </html>
```

The `ThemeToggle` component reads `localStorage('orniflight-theme')` on mount,
validates against `['dark', 'light']`, and sets the attribute. Clicking toggles
and persists the selection.

```coffee
# ThemeToggle.coffee — condensed
useEffect ->
  stored = localStorage.getItem 'orniflight-theme'
  current = if stored in ['dark', 'light'] then stored else 'dark'
  document.documentElement.setAttribute 'data-theme', current
, []

toggle = ->
  next = if theme is 'dark' then 'light' else 'dark'
  document.documentElement.setAttribute 'data-theme', next
  localStorage.setItem 'orniflight-theme', next
```

### Button Icons
- Dark mode: ☼ (sun, U+263C) — "click for light"
- Light mode: ☾ (moon, U+263E) — "click for dark"

The button is positioned in the toolbar via `ConnectionBar.chaml`:

```haml
%ThemeToggle/
```

## Color Palette

### Semantic Token Map

| Token                    | Dark Value     | Light Value    | Usage                    |
|--------------------------|---------------|---------------|--------------------------|
| `--of-surface-0`         | `#0d1117`     | `#f0f2f5`     | Shell background         |
| `--of-surface-1`         | `#161b22`     | `#ffffff`     | Toolbar, sidebar         |
| `--of-surface-2`         | `#1c2333`     | `#f5f6f8`     | Panel backgrounds        |
| `--of-surface-3`         | `#21283a`     | `#e8eaef`     | Elevated surfaces        |
| `--of-surface-4`         | `#2a3347`     | `#dde0e6`     | Input backgrounds        |
| `--of-border-1`          | `#30363d`     | `#d0d5dd`     | Primary borders          |
| `--of-border-2`          | `#3a4458`     | `#c0c5ce`     | Secondary borders        |
| `--of-border-accent`     | `#4a5568`     | `#a0a8b4`     | Focus/active borders     |
| `--of-text-primary`      | `#e6edf3`     | `#1a1e27`     | Body text                |
| `--of-text-secondary`    | `#8b949e`     | `#5a6070`     | Supplemental text        |
| `--of-text-muted`        | `#5c6670`     | `#8a909c`     | Headings, labels         |
| `--of-text-accent`       | `#f0a040`     | `#c07020`     | Highlighted text         |

### Accent Colors

| Token                    | Dark Value     | Light Value    | Semantic Meaning         |
|--------------------------|---------------|---------------|--------------------------|
| `--of-accent-orange`     | `#f0883e`     | `#d06820`     | Primary brand, Wing L    |
| `--of-accent-amber`      | `#f0a040`     | `#c07020`     | Simulation mode, glow    |
| `--of-accent-gold`       | `#e2b04a`     | `#b89030`     | Accent highlights        |
| `--of-accent-blue`       | `#58a6ff`     | `#3070cc`     | Wing R, pitch            |
| `--of-accent-cyan`       | `#39d2c0`     | `#1a9e8e`     | Info/status              |
| `--of-accent-green`      | `#3fb950`     | `#2a8e3e`     | Connected, yaw           |
| `--of-accent-red`        | `#f85149`     | `#c83030`     | Disconnected, roll       |
| `--of-accent-purple`     | `#bc8cff`     | `#8a5ccc`     | Yaw gyro                 |

### RGB Variants (for `rgba()` usage)

Used in patterns like `background: rgba(var(--of-accent-amber-rgb), 0.12)`:

| Token                       | Dark       | Light       |
|-----------------------------|-----------|------------|
| `--of-accent-orange-rgb`    | 240,136,62 | 208,104,32 |
| `--of-accent-amber-rgb`     | 240,160,64 | 192,112,32 |
| `--of-accent-green-rgb`     | 63,185,80  | 42,142,62  |
| `--of-surface-2-rgb`        | 28,35,51   | 245,246,248 |

### Glow & Status

| Token                     | Dark                        | Light                       |
|---------------------------|-----------------------------|-----------------------------|
| `--of-simulation-glow`    | `rgba(240,160,64,0.25)`     | `rgba(192,112,32,0.2)`     |
| `--of-connected-glow`     | `rgba(63,185,80,0.3)`       | `rgba(42,142,62,0.2)`      |
| `--of-disconnected-bg`    | `rgba(248,81,73,0.15)`      | `rgba(200,48,48,0.1)`      |

## Typography

### Font Stack

| Role         | Variable             | Stack                                                                 |
|-------------|---------------------|-----------------------------------------------------------------------|
| Display     | `--of-font-display` | `'Orbitron', 'SF Pro Display', 'Inter', system-ui, sans-serif`        |
| Sans-serif  | `--of-font-sans`    | `'Inter', 'SF Pro', 'Helvetica Neue', system-ui, sans-serif`         |
| Monospace   | `--of-font-mono`    | `'SF Mono', 'Fira Code', 'JetBrains Mono', 'Menlo', monospace`       |

Orbitron is loaded from Google Fonts in `index.html` at weights 500, 600, 700:

```html
<link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@500;600;700&display=swap"
      rel="stylesheet" />
```

### Size Scale

| Token            | Value      | Usage                           |
|-----------------|-----------|---------------------------------|
| `--of-text-xs`  | `0.6875rem` (11px) | Toolbar status, badges     |
| `--of-text-sm`  | `0.75rem` (12px)   | Sidebar items, param labels |
| `--of-text-base`| `0.8125rem` (13px)  | Body text                    |
| `--of-text-md`  | `0.875rem` (14px)   | Toolbar brand                |
| `--of-text-lg`  | `1rem` (16px)       | Section headings             |

### Usage Rules

- **Orbitron** is used ONLY on `.toolbar-brand` (the "OrniFlight Studio" name).
  It is never used for body text, labels, or data.
- **Monospace** is used on data values (`.telemetry-value`, `.param-value`, `.readout-value`),
  code blocks, and the overlay badges.
- **Sans-serif** is the default for all other text.

## Spacing

| Token           | Value | Usage                       |
|----------------|-------|-----------------------------|
| `--of-space-1` | `2px` | Tight gaps, dot indicators  |
| `--of-space-2` | `4px` | Icon-text gaps              |
| `--of-space-3` | `6px` | Badge padding, item gaps    |
| `--of-space-4` | `8px` | Standard padding            |
| `--of-space-5` | `12px`| Section padding             |
| `--of-space-6` | `16px`| Comfortable separation      |
| `--of-space-7` | `20px`| Large gaps                  |
| `--of-space-8` | `24px`| Section margins             |
| `--of-space-9` | `32px`| Major layout gaps           |
| `--of-space-10`| `48px`| Maximum separation          |

## Radii & Shadows

### Border Radii

| Token            | Value | Usage                   |
|-----------------|-------|-------------------------|
| `--of-radius-sm`| `3px` | Buttons, indicators     |
| `--of-radius-md`| `5px` | Inputs, panels          |
| `--of-radius-lg`| `8px` | Cards, modals           |

### Shadows

| Token                | Dark                                                | Light                                          |
|---------------------|-----------------------------------------------------|------------------------------------------------|
| `--of-shadow-panel` | `0 1px 3px rgba(0,0,0,0.4), 0 0 0 1px rgba(255,255,255,0.03)` | `0 1px 3px rgba(0,0,0,0.08), 0 0 0 1px rgba(0,0,0,0.04)` |
| `--of-shadow-elevated` | `0 4px 12px rgba(0,0,0,0.5), 0 0 0 1px rgba(255,255,255,0.05)` | `0 4px 12px rgba(0,0,0,0.1), 0 0 0 1px rgba(0,0,0,0.05)` |
| `--of-shadow-glow`  | `0 0 8px var(--of-simulation-glow)`                 | Same (uses simulation-glow token)              |

## Timing

| Token              | Value                                   | Usage                 |
|-------------------|-----------------------------------------|-----------------------|
| `--of-ease-out`   | `cubic-bezier(0.16, 1, 0.3, 1)`        | Hover, focus exits    |
| `--of-ease-in-out`| `cubic-bezier(0.65, 0, 0.35, 1)`       | Panel transitions     |
| `--of-dur-fast`   | `120ms`                                 | Hover color changes   |
| `--of-dur-normal` | `200ms`                                 | Standard transitions  |
| `--of-dur-slow`   | `350ms`                                 | Layout mode changes   |

All transitions are **compositor-only** (opacity, transform) where possible to
avoid layout thrashing.

## Layout

| Token                     | Value    | Usage                              |
|--------------------------|----------|------------------------------------|
| `--of-toolbar-height`    | `36px`   | Top toolbar, fixed height          |
| `--of-statusbar-height`  | `26px`   | Reserved for future status bar      |
| `--of-sidebar-width`     | `220px`  | Left sidebar, fixed width           |
| `--of-inspector-width`   | `260px`  | Right inspector (split mode)        |

## View Mode Layout Grids

The `.studio-workspace` adapts its CSS grid based on `view-{mode}` class:

| Mode      | Grid Template                             | Inspector | TelemetryLab |
|-----------|-------------------------------------------|-----------|--------------|
| `full`    | `"sidebar viewport"`                      | Hidden    | Visible      |
| `split`   | `"sidebar viewport inspector"`            | Visible   | Visible      |
| `compact` | `"sidebar viewport-small" / "telemetry telemetry"` | Hidden | Full-width   |

## Feather Background

The `.studio-shell` and `.studio-viewport` both render a subtle feather pattern
via a pseudo-element overlay:

```sass
&::after
  content: ''
  position: absolute
  inset: 0
  pointer-events: none
  z-index: 0
  background-image: url('/feathers_darker.png')
  background-repeat: repeat
  background-size: 200px  # shell: 200px, viewport: 180px
  opacity: 0.04           # shell: 0.04, viewport: 0.05
```

The image (`public/feathers_darker.png`) is carried over from the
orniflight-configurator project. It's a dark feather texture that works on both
themes — the low opacity ensures it never overwhelms the content.

## Color Scheme

```sass
:root
  color-scheme: dark           # Default

[data-theme="light"]
  color-scheme: light          # Light mode
```

This tells the browser to render native form controls (scrollbars, selects,
inputs) in the appropriate scheme.

## Adding New Tokens

1. Add the token to both `:root` (dark) and `[data-theme="light"]` blocks in
   `src/styles/_tokens.sass`.
2. Use the `--of-` prefix for all tokens.
3. For colors that need `rgba()` composition, also add an `-rgb` variant
   (comma-separated R,G,B values).
4. Reference tokens in `main.sass` via `var(--of-token-name)`.
5. Never hardcode colors in component styles — always use tokens.

## Curve Color Mapping

The waveform and gyro canvases use these accent colors for visual consistency:

| Curve ID     | Color Token Equivalent | Hex       |
|-------------|------------------------|-----------|
| `wingL`     | `--of-accent-orange`   | `#f0883e` |
| `wingR`     | `--of-accent-blue`     | `#58a6ff` |
| `gyroRoll`  | `--of-accent-red`      | `#f85149` |
| `gyroPitch` | `--of-accent-green`    | `#3fb950` |
| `gyroYaw`   | `--of-accent-purple`   | `#bc8cff` |

Canvas rendering uses hardcoded hex values (not CSS vars) since Canvas 2D
doesn't support `var()`. These hex values must be kept in sync with the
corresponding tokens.
