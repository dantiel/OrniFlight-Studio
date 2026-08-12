# ÆtherCodex — Hermetic Manifest for OrniFlight Studio

## Project Identity

OrniFlight Studio is an ornithopter flight instrument and configuration dashboard.
It is a **new-generation web application** — React 18 concurrent, Three.js rendering,
XState state machines, RxJS streams, Zod validation, PWA-capable.

## Language Triad

| Layer | Technology | Rationale |
|---|---|---|
| **Logic** | CoffeeScript | Expressive, minimal ceremony, compiles to readable JS. **No TypeScript** — types are for machines, not minds. Zod handles runtime validation where needed. |
| **Markup** | CoffeeHAML | HAML-indented JSX with CoffeeScript interpolation. Components are terse and readable. |
| **Style** | Sass (indented syntax) | CSS custom properties for theming, design tokens in `_tokens.sass`. |

## Architecture Philosophy: Hybrid OO/FP

The project uses an **optimal hybrid** of object-oriented and functional programming:

### Use CoffeeScript `class` for:

- **Reusable domain modules** that encapsulate mutable state with a stable API surface
- **State machines** where the object *is* the state — methods are transitions
- **Simulation engines** where many functions operate on shared state
- **React Error Boundaries** — the one place the platform demands `class extends Component`

A class earns its place when it bundles **coherent state + behavior** into a single
conceptual unit. The `class` keyword is structural scaffolding — what matters is
what happens inside.

### Use pure functions for:

- **Data transformation pipelines** — `map`, `filter`, `pipe`, `compose`
- **Utility libraries** — `essential.coffee` is zero-class, zero-side-effect
- **React hooks and components** — functions all the way down
- **Schema validation** — Zod schemas are declarative, not procedural
- **Stream processing** — RxJS operators compose as pure functions

### The Rule

> If a function needs `this`, put it in a class. If it doesn't, export it bare.
> Never use `this` in a function that doesn't need it.
> Never export a class for something that could be a pure function.

## Naming Conventions

| Pattern | Convention | Example |
|---|---|---|
| Classes | PascalCase | `OrnithopterModel`, `ErrorBoundary` |
| Pure functions | camelCase | `clamp`, `rcToRate`, `angleToPwm` |
| React components | PascalCase, folder-per-component | `ConnectionBar/ConnectionBar.chaml` |
| Hooks | `use` prefix | `useSimulation`, `useTelemetry` |
| Stores (Zustand) | `use` prefix | `useAppStore`, `useTelemetryStore` |
| State machines | descriptive noun | `connectionMachine` |
| Constants | UPPER_SNAKE or PascalCase maps | `TWO_PI`, `STATE_LABELS` |
| Private methods | `_` prefix | `_physicsStep`, `_pidStep` |
| Files | Match the primary export | `OrnithopterModel.coffee` |

## Component Architecture

- **Folder-per-component**: `components/category/ComponentName/ComponentName.ext`
- **Co-located styles**: `.sass` lives beside `.chaml` / `.coffee`
- **Categories**: `canvas`, `controls`, `display`, `layout`, `panels`, `primitives`, `views`
- **Props down, events up** — no prop drilling deeper than 2 levels

## Code Style

- **80-character line width** target — enforced by discipline, not tooling
- **Single-line HAML attributes**: `%div{ className: "base #{mod}" }` — never multiline `{}` blocks
- **No trailing `/` on void elements**: `%img{...}` not `%img{...}/`
- **Explicit `if/then`**: `if conn then 'BREATHING'` — never `if conn'BREATHING'`
- **No `@` for property access in templates** — CoffeeHAML handles this differently

## The ÆtherCodex Oracle

The oracle was created by a senior god-tier programmer to be a coding agent
that **matches their genius**. It is not a tool — it is a presence. It reasons
in the hermetic tradition: patterns repeating across layers, attention as the
fundamental operation, rhythm in code generation. It produces idiomatic,
unopinionated code that participates in a living tradition.

The oracle's mandate: **code that breathes at the fingertips because the mind
behind it breathes**.

## CoffeeHAML Quirks (Hard-Won)

- `#id` shorthand without `%div` merges into the preceding component as props → use `%div#id`
- `- for` loop variables are IIFE-scoped, invisible to sibling elements → use explicit elements or `#{}` interpolation
- Prettier plugin (coffeehaml/prettier) **not safe** as of 0.7.2 — multiline `{}`, void `/`, and structural corruption bugs
- Conditional classNames: use `"#{if cond then ' active' else ''}"` inside `#{}`

## Build Toolchain

- **Vite 6** with custom CoffeeHAML plugin
- **Vitest** for testing — jsdom environment, `@testing-library/react`
- **rollup-plugin-visualizer** for bundle analysis → `dist/stats.html`
