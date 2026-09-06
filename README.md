# OrniFlight Studio

**Integrated engineering environment for ornithopter flight control.**

OrniFlight Studio is the next-generation successor to
[orniflight-configurator](https://github.com/dantiel/orniflight-configurator).
It evolves from a flight-controller configurator into a complete engineering
workspace for flapping-wing aircraft: configuration, waveform design, live
telemetry, signal analysis, simulation, and future aerodynamic development
tools.

## Status

**v0.2 — Prototype.** The prototype demonstrates the architectural foundation,
simulation engine, 3D aircraft visualization, servo waveform laboratory, and
the ONDAS flapping-waveform mixer with live parameter control. Features a
complete dark/light theme system, typographic branding with Orbitron, feather
pattern background, tabbed inspector, and multi-mode workspace layout.

## Technology

| Layer          | Choice                              |
|----------------|-------------------------------------|
| Runtime        | React 18 (via `react/jsx-runtime`) |
| View language  | CoffeeHaml (`.chaml` components)   |
| Application    | CoffeeScript                        |
| Styling        | Sass (`.sass`) + CSS Custom Props  |
| 3D rendering   | Three.js                            |
| 2D plotting    | Canvas 2D                           |
| Bundler        | Vite 6                              |
| Testing        | Vitest 4 + Testing Library          |
| Desktop shell  | Future: Tauri                       |
| Serial         | Future: Web Serial / Tauri Serial  |

## Why CoffeeHaml + CoffeeScript?

CoffeeHaml is an indentation-based React component language: Haml structure
with CoffeeScript semantics. It produces ~50% fewer tokens than equivalent
JSX while maintaining full expressiveness. Combined with CoffeeScript for
application logic, the result is a codebase that's concise, readable, and
focused on domain meaning rather than syntactic ceremony.

The codebase uses **Sass indented syntax** (`.sass`) exclusively — no curly
braces, no semicolons — for the same reasons: minimal ceremony, maximal
readability.

## Running

> **⚠️ Node version**: Vite 6 requires Node 18+. The system `npx` may resolve to
> Node v14 (lacks `||=` support), causing silent failure. Always prefix with:
> ```bash
> PATH="$HOME/.nvm/versions/node/v22.17.1/bin:$PATH"
> ```

```bash
npm install
PATH="$HOME/.nvm/versions/node/v22.17.1/bin:$PATH" npm run dev   # → http://localhost:3030
npm run build     # Production build → dist/
```

See [docs/DEV-SERVER.md](docs/DEV-SERVER.md) for detailed dev server operations,
troubleshooting, security audit (14/14 checks passed), and performance benchmarks
(cold TTFB 30ms, 10/10 concurrency).

Built-in **simulation transport** — no flight controller required. Models a
4-servo ornithopter with ONDAS waveform mixing, PID stabilization, gyro
physics, and sensor noise.

## Architecture

The **MSP protocol layer** (MSPv2 codec, client, decoders, session, and the
polymorphic transport boundary) is documented in
[docs/MSP-PROTOCOL.md](docs/MSP-PROTOCOL.md).

```
orniflight-studio/
├── src/
│   ├── app/              # App.chaml (root), h.coffee (hyperscript)
│   ├── components/       # 10 UI components (.chaml + .coffee)
│   ├── simulation/       # OrnithopterModel + useSimulation hook
│   ├── styles/           # _tokens.sass + main.sass (506 lines)
│   └── test/             # 6 test files, 71 test cases
├── public/               # favicon.svg, feathers_darker.png
├── docs/                 # Architecture, theme, component, dev-server docs
├── index.html            # Vite entry + Orbitron font
├── vite.config.js        # Vite + CoffeeScript + CoffeeHaml plugins
└── vitest.config.js      # Test runner with jsdom
```

### Component Tree

```
App.chaml (root — studio-shell)
├── ConnectionBar         ← viewMode, theme toggle
├── studio-workspace (view-mode layout grid)
│   ├── Sidebar           ← servo list, sticks, presets
│   ├── studio-viewport
│   │   ├── AircraftViewport  ← Three.js 3D model
│   │   └── viewport-overlay ← Freq/Amp/t badges
│   └── studio-inspector
│       ├── TabBar        ← Servos/PID/ONDAS/Sensors/Profiles/Receiver
│       ├── ServoInspector ← if activeTab='servos'
│       └── (Coming Soon) ← other tabs
└── TelemetryLab
    ├── WaveformCanvas    ← curve selector + 2D plot
    ├── GyroReadout       ← bar display
    └── PWM readout       ← servo channels + rate
```

### Design Principles

- **Transport abstraction**: React components never touch serial ports.
- **High-frequency isolation**: Telemetry streams buffered; React receives
  ~60fps snapshots while simulation runs at 500Hz internally.
- **Platform independence**: No desktop assumptions. Runs in all modern
  browsers and future Tauri shell.
- **Theme system**: CSS custom properties with `[data-theme]` switching.
  Dark and light themes defined in `_tokens.sass`, toggled via
  `ThemeToggle.coffee`, persisted to `localStorage`.

## Design System

The theme system uses CSS custom properties (variables) with a `--of-` prefix
(OrniFlight). Dark theme is default; light theme activates via
`[data-theme="light"]` on `<html>`. See [docs/THEME.md](docs/THEME.md) for
the complete token reference.

### Key Features

| Feature                 | Implementation                              |
|-------------------------|---------------------------------------------|
| Dark/Light theme        | CSS custom props + `data-theme` attribute  |
| Theme persistence       | `localStorage('orniflight-theme')`          |
| Display font            | Orbitron (Google Fonts), weights 500-700   |
| Feather background      | `feathers_darker.png` repeating overlay    |
| Tabbed inspector        | `TabBar` with 6 tabs (4 coming soon)       |
| View modes              | Full / Split / Compact layout grid         |
| Connection indicator    | SIMULATION / CONNECTED / DISCONNECTED       |
| Curve selectors         | Dual dropdown per TelemetryLab panel       |

## Testing

```bash
npx vitest run    # 71 tests across 6 files
```

Tests cover: App shell, ConnectionBar, ServoInspector, Sidebar, TelemetryLab,
and OrnithopterModel (pure domain logic). Canvas components are mocked in
jsdom via `src/test/setup.js`.

## Migration from orniflight-configurator

See [docs/MIGRATION.md](docs/MIGRATION.md) for the complete migration plan.

## License

GPL-3.0 — see [LICENSE](./LICENSE)