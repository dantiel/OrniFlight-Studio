# OrniFlight Studio — Architecture & Technical Reference

## Project Overview

OrniFlight Studio is a React 18 single-page application for ornithopter flight
control engineering. It runs entirely in the browser with a built-in simulation
engine — no flight controller hardware required for development.

**Version:** 0.1.0 (Prototype)
**Build:** 39 modules → 659KB JS + 11KB CSS (gzipped: ~200KB + 3KB)
**Tests:** 71 passing across 6 test files

---

## Technology Stack

### Core

| Layer              | Technology              | Version    |
|--------------------|------------------------|------------|
| UI Runtime         | React                  | 18.3.1     |
| DOM Rendering      | react-dom              | 18.3.1     |
| Application Logic  | CoffeeScript           | 2.7.0      |
| Markup Components  | CoffeeHaml             | 0.4.1 (local) |
| Hyperscript        | Custom `h()` wrapper   | `src/app/h.coffee` |
| Styling            | Sass (indented syntax) | 1.83.0     |
| 3D Graphics        | Three.js               | 0.170.0    |
| 2D Graphics        | Canvas 2D API          | Native     |

### Build & Dev

| Tool         | Technology     | Version  |
|-------------|---------------|----------|
| Bundler     | Vite          | 6.0.0    |
| React Plugin| @vitejs/plugin-react | 4.3.4 |
| Sass API    | modern-compiler | —      |
| Dev Server  | Vite          | :3030    |

### Testing

| Tool              | Technology              | Version  |
|-------------------|------------------------|----------|
| Test Runner       | Vitest                 | 4.1.10   |
| DOM Environment   | jsdom                  | 30.0.1   |
| React Testing     | @testing-library/react | 16.3.2   |
| Assertions        | @testing-library/jest-dom | 7.0.0 |

---

## Build Pipeline

```
.chaml ──→ coffeehaml() ──→ JSX ──→ react() ──→ ESM
.coffee ─→ coffeePlugin() ─→ JS ───→ react() ──→ ESM
.sass ───→ sass (modern) ──→ CSS
```

### Vite Plugins (in order)

1. **coffeehaml()** — Compiles `.chaml` → JSX. CoffeeHaml v0.4.1 with
   children-in-props fix, IIFE-wrapped compileStatement, `?.` support in
   compileExpression, scoping fix, and for-loop iterable parens fix.

2. **coffeePlugin()** — Compiles `.coffee` → JavaScript (ESM, bare mode).
   Custom inline plugin in `vite.config.js` using the CoffeeScript compiler
   directly. Produces source maps.

3. **react()** — Standard Vite React plugin. Transforms JSX → `createElement`
   calls using the automatic JSX runtime.

### Alias

```js
'@' → 'src/'  // Allows import '@/components/Foo.chaml'
```

---

## Architecture Patterns

### Singleton Simulation Engine

The `OrnithopterModel` is a plain class — no React, no DOM. It's instantiated
once at module scope in `useSimulation.coffee`:

```coffee
engine = new OrnithopterModel()
engine.connected = true  # Start in simulation mode
```

All components use the same engine via the `useSimulation()` hook. This ensures
a single source of truth for simulation state.

### rAF-Driven Snapshots

The simulation runs at 500Hz internally (5 sub-steps per frame). React only
receives state updates at ~60fps via `requestAnimationFrame`:

```coffee
tick = (now) ->
  dt = Math.min((now - lastTimeRef.current) / 1000, 0.05)
  engine.step(dt)
  setSnapshot({ attitude: {...}, gyro: {...}, ... })  # Shallow clone
  rafRef.current = requestAnimationFrame(tick)
```

This pattern isolates high-frequency computation from React's reconciliation,
preventing render bottlenecks.

### Prop-Driven Architecture

All data flows unidirectionally through React props:

```
useSimulation() → App.chaml → Child Components
```

Child components never access the simulation engine directly. They receive
snapshot data via props and communicate upward via callback props
(`onStickChange`, `onParamChange`, etc.).

### Telemetry Ring Buffer

The waveform history is a capped array of 200 samples:

```coffee
tel.waveformHistory.push({ t, wingL, wingR, gyroRoll, gyroPitch, gyroYaw })
if tel.waveformHistory.length > 200
  tel.waveformHistory.shift()
```

At 60fps, this provides ~3.3 seconds of history. The `WaveformCanvas` renders
the last 3.0 seconds by default.

---

## Component Communication

```
┌─────────────────────────────────────────────────────┐
│ App.chaml (useState: activeTab, viewMode, curves)   │
│                                                     │
│  ┌─ ConnectionBar ─────────────────────────────┐    │
│  │  ← viewMode, connected, V, Hz               │    │
│  │  → onViewModeChange                         │    │
│  │  ├─ ViewModeToggle ← mode, → onModeChange   │    │
│  │  └─ ThemeToggle (self-contained)            │    │
│  └──────────────────────────────────────────────┘    │
│                                                     │
│  ┌─ Sidebar ───────────────────────────────────┐    │
│  │  ← servos[], selectedServoIndex, sticks{}   │    │
│  │  → onSelectServo, onStickChange,            │    │
│  │    onApplyPreset                            │    │
│  └──────────────────────────────────────────────┘    │
│                                                     │
│  ┌─ AircraftViewport ──────────────────────────┐    │
│  │  ← attitude{}, wingAngleL/R, flapFreq       │    │
│  │  → onBump (click-to-disturb)                │    │
│  └──────────────────────────────────────────────┘    │
│                                                     │
│  ┌─ TabBar ────────────────────────────────────┐    │
│  │  ← activeTab                                │    │
│  │  → onTabChange                              │    │
│  └──────────────────────────────────────────────┘    │
│                                                     │
│  ┌─ ServoInspector ───────────────────────────┐     │
│  │  ← servo, index, pidGains, ondasParams     │     │
│  │  → onParamChange, onPidChange,             │     │
│  │    onOndasChange                            │     │
│  └──────────────────────────────────────────────┘    │
│                                                     │
│  ┌─ TelemetryLab ─────────────────────────────┐     │
│  │  ← waveformHistory[], gyro{}, servoPWM[],  │     │
│  │     waveCurves[], gyroCurves[]             │     │
│  │  → onWaveCurveChange, onGyroCurveChange    │     │
│  │  ├─ WaveformCanvas ← history, curves       │     │
│  │  └─ GyroReadout ← gyro                     │     │
│  └──────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

---

## CSS Architecture

### Token Layer (`_tokens.sass`)

All design tokens are CSS custom properties in `:root` and `[data-theme="light"]`.
No Sass variables — everything is a runtime CSS custom property for theme switching.

### Global Styles (`main.sass`)

506 lines of indented Sass organized as:

1. **Reset** — Box-sizing, margin/padding zero
2. **Document** — html/body/#root full-height, font, antialiasing
3. **Scrollbar** — Custom thin scrollbar (6px)
4. **Selection** — Orange-tinted text selection
5. **Focus** — Amber outline on `:focus-visible`
6. **Monospace** — Font-family overrides for code/data elements
7. **Shell** — `.studio-shell` flex column + feather overlay
8. **Toolbar** — `.studio-toolbar` with drag region, brand, indicators
9. **Workspace** — `.studio-workspace` flex row + view-mode grid variants
10. **Sidebar** — `.studio-sidebar` with sections, items, active states
11. **Viewport** — `.studio-viewport` with feather overlay, canvas, badges
12. **Inspector** — `.studio-inspector` with sections, param rows, sliders
13. **Tab Bar** — `.tab-bar` horizontal button row
14. **View Mode Toggle** — `.viewmode-toggle` button group
15. **Theme Toggle** — `.theme-toggle-btn` icon button
16. **Telemetry Lab** — `.studio-telemetry-lab` with panels
17. **Canvas** — `.waveform-canvas`, `.gyro-canvas` sizing
18. **View Mode Variants** — `.view-full`, `.view-split`, `.view-compact` grid layouts

### View Mode Grids

```sass
// view-full: sidebar + viewport (no inspector)
.view-full
  grid-template-columns: var(--of-sidebar-width) 1fr
  grid-template-rows: 1fr
  grid-template-areas: "sidebar viewport"

// view-split: sidebar + viewport + inspector
.view-split
  grid-template-columns: var(--of-sidebar-width) 1fr var(--of-inspector-width)
  grid-template-rows: 1fr
  grid-template-areas: "sidebar viewport inspector"

// view-compact: sidebar | small viewport + full-width telemetry
.view-compact
  grid-template-columns: var(--of-sidebar-width) 1fr
  grid-template-rows: 1fr auto
  grid-template-areas: "sidebar viewport" "telemetry telemetry"
```

---

## 3D Model Architecture

### Coordinate System

After the T1 fix, the model uses a **Z-forward** convention:

- **+Z** = forward (nose direction)
- **+Y** = up
- **+X** = right (starboard wing)

The `fuseGroup` is rotated `+PI/2` around the X-axis to align the cylinder
body (originally Y-aligned) with the Z-axis.

### Model Hierarchy

```
model (Group, scale 1.4)
├── fuseGroup (rotation.x = PI/2)
│   ├── body: Cylinder(0.1, 0.14, 0.65, 12, 4)
│   ├── nose: Cylinder(0.01, 0.1, 0.16, 12, 4) @ (0, 0.4, 0)
│   └── tailCone: Cylinder(0.14, 0.04, 0.22, 12, 4) @ (0, -0.43, 0)
├── wingPivotL @ (0.15, 0.03, 0.05)
│   └── wingMeshL: ExtrudeGeometry(bezier shape, depth=0.2)
├── wingPivotR @ (-0.15, 0.03, 0.05)
│   └── wingMeshR: ExtrudeGeometry(bezier shape, rotated PI on Y)
├── hstab: Box(0.45, 0.012, 0.1) @ (0, 0.02, -0.58)
├── vfin: Box(0.012, 0.12, 0.09) @ (0, 0.07, -0.58)
├── 2× servo mounts: Cylinder(0.03, 0.03, 0.04, 6) @ (±0.15, -0.02, 0.05)
└── center dot: Sphere(0.04, 8, 8)
```

### Materials

| Part        | Material            | Color    | Roughness | Metalness |
|------------|--------------------|---------|-----------|-----------|
| Fuselage   | MeshStandard        | 0xff8830 | 0.35      | 0.15      |
| Wings      | MeshStandard (DoubleSide) | 0xff9930 | 0.50      | 0.05      |
| Tail dark  | MeshStandard        | 0xcc6620 | 0.45      | 0.10      |
| Accents    | MeshStandard        | 0x445566 | 0.30      | 0.60      |

### Animation

- **Attitude update:** `model.rotation.set(roll, yaw, -pitch)` — note the sign
  inversion on pitch because the model faces +Z but Three.js default forward is -Z.
- **Wing flapping:** `wingPivotL.rotation.z = wingAngleL`, `wingPivotR.rotation.z = -wingAngleR`
  (mirrored for right wing).
- **Wing geometry:** Extruded bezier curve shape, `.castShadow = true`.

---

## Simulation Engine

### OrnithopterModel Class

A 372-line pure domain model implementing:

#### Flapping Physics
```coffee
sinPhi = Math.sin(@flapPhase)
amp = @baseAmplitude * (PI / 180)

# Left wing
ampL = amp * (1.0 + pitchMod + resonanceMod) * anchorMod
ampL += rollDiff + yawDiff + balanceMod
@wingAngleL = sinPhi * ampL

# Right wing (mirrored roll, partial yaw)
ampR = amp * (1.0 + pitchMod + resonanceMod) * anchorMod
ampR -= rollDiff + yawDiff * 0.3 - balanceMod
@wingAngleR = sinPhi * ampR
```

#### Gyro Integration
```coffee
wingRoll  = (@wingAngleL - @wingAngleR) * 0.02 * rollAuth
wingPitch = (@wingAngleL + @wingAngleR) * 0.01 * pitchAuth * 0.5
wingYaw   = (@wingAngleL - @wingAngleR) * 0.005 * yawAuth * sinPhi

@gyro.roll  = (@gyro.roll  + wingRoll  * thrustFactor) * 0.95
@gyro.pitch = (@gyro.pitch + wingPitch * thrustFactor) * 0.95
@gyro.yaw   = (@gyro.yaw   + wingYaw   * thrustFactor) * 0.98
```

#### PID Controller
3-axis PID with anti-windup (I term clamped to ±1.0):
```coffee
correction = (pOut + iOut + dOut) * 0.3
@gyro[axis] += correction * @dt
```

#### ONDAS Waveform Mixer
14 parameters controlling wing amplitude modulation:
- **Cadence:** Frequency modulation from pitch error
- **Ferocity P/D:** Derivative and proportional rate response
- **Ferocity Roll/Yaw:** Asymmetric rate mixing
- **Balance:** I-term based pitch bias
- **Warp/Warp Yaw:** Direct rate-to-amplitude coupling
- **Anchor:** Amplitude reduction at high total rates
- **Resonance:** Sinusoidal coupling of roll error
- **Prescience, Espelho, Saudade, SSFF:** Reserved for future expansion

#### Servo PWM Mapping
Wing angles (±45°) → 4-channel PWM (1000-2000µs centered at 1500):
```coffee
angleToPwm = (angleDeg) =>
  pwm = 1500 + (angleDeg / 45.0) * 500
  Math.max(1000, Math.min(2000, Math.round(pwm)))
```

#### Presets
| Preset  | Frequency | Amplitude | Roll P | Pitch P | Yaw P |
|---------|-----------|-----------|--------|---------|-------|
| Gentle  | 4.0 Hz    | 30°       | 2.0    | 3.0     | 1.5   |
| Acro    | 6.0 Hz    | 45°       | 4.0    | 6.0     | 3.0   |
| Race    | 8.0 Hz    | 55°       | 7.0    | 9.0     | 5.0   |

---

## File Reference

| File                                   | Lines | Type      | Purpose                              |
|---------------------------------------|-------|-----------|--------------------------------------|
| `index.html`                          | 34    | HTML      | Vite entry, Orbitron font, boot loader |
| `src/main.coffee`                     | 8     | CoffeeScript | React root mount                  |
| `src/app/h.coffee`                    | 20    | CoffeeScript | Hyperscript helper                 |
| `src/app/App.chaml`                   | 50    | CoffeeHaml | Root component                     |
| `src/components/ConnectionBar.chaml`  | 29    | CoffeeHaml | Toolbar                            |
| `src/components/Sidebar.chaml`        | 54    | CoffeeHaml | Left sidebar                       |
| `src/components/AircraftViewport.coffee` | 195 | CoffeeScript | 3D viewport (Three.js)           |
| `src/components/TabBar.coffee`        | 32    | CoffeeScript | Inspector tab navigation           |
| `src/components/ServoInspector.chaml` | 29    | CoffeeHaml | Servo/PID/ONDAS config             |
| `src/components/TelemetryLab.chaml`   | 45    | CoffeeHaml | Waveform panel, gyro, PWM          |
| `src/components/WaveformCanvas.coffee`| 119   | CoffeeScript | 2D time-series plot               |
| `src/components/GyroReadout.coffee`   | 74    | CoffeeScript | Gyro bar display                   |
| `src/components/ViewModeToggle.coffee`| 27    | CoffeeScript | Layout mode switcher               |
| `src/components/ThemeToggle.coffee`   | 30    | CoffeeScript | Dark/light toggle                  |
| `src/simulation/OrnithopterModel.coffee`| 372 | CoffeeScript | Physics + ONDAS engine            |
| `src/simulation/useSimulation.coffee` | 78    | CoffeeScript | React hook for simulation          |
| `src/styles/_tokens.sass`            | 108   | Sass       | CSS custom properties               |
| `src/styles/main.sass`               | 506   | Sass       | Global styles + component classes  |
| `src/test/setup.js`                  | 48    | JavaScript | Test mocks + rAF polyfill          |
| `src/test/App.test.coffee`           | 69    | CoffeeScript | App shell tests (13 cases)        |
| `src/test/ConnectionBar.test.coffee` | ~20   | CoffeeScript | ConnectionBar tests                |
| `src/test/ServoInspector.test.coffee`| ~20   | CoffeeScript | ServoInspector tests               |
| `src/test/Sidebar.test.coffee`       | ~20   | CoffeeScript | Sidebar tests                      |
| `src/test/TelemetryLab.test.coffee`  | ~20   | CoffeeScript | TelemetryLab tests                 |
| `src/test/OrnithopterModel.test.coffee`| ~80 | CoffeeScript | Pure domain logic tests            |
| `vite.config.js`                     | 47    | JavaScript | Vite + CoffeeScript + CoffeeHaml  |
| `vitest.config.js`                   | 37    | JavaScript | Vitest + jsdom                     |
| `package.json`                       | 32    | JSON       | Dependencies + scripts             |

---

## Performance Characteristics

| Metric                | Value          | Notes                                     |
|----------------------|---------------|-------------------------------------------|
| Simulation rate      | 500 Hz (sub-steps) | 5 sub-steps per frame at 60fps        |
| React render rate    | ~60 fps       | rAF-driven, shallow-cloned snapshots      |
| Waveform buffer      | 200 samples   | ~3.3s history, FIFO ring buffer           |
| dt cap               | 50ms          | Prevents spiral-of-death on tab switch    |
| pixelRatio cap       | 2x            | Three.js renderer, prevents GPU overload  |
| Build JS (uncompressed)| 659KB       | 39 modules via Vite/Rollup                |
| Build CSS            | 11KB          | Sass → CSS, no framework overhead         |
| Theme transition     | `--of-dur-fast` (120ms) | Compositor-only properties only    |
| Canvas scaling       | devicePixelRatio | HiDPI-aware with manual scaling         |

---

## Security Posture

| Vector              | Status | Detail                                          |
|--------------------|--------|------------------------------------------------|
| XSS (render)       | ✅ Clean | All rendering via `React.createElement`       |
| XSS (innerHTML)    | ✅ None  | No `dangerouslySetInnerHTML`, no `innerHTML`   |
| User input         | ✅ Safe  | Only `<input type="range">` and `<select>`     |
| Free text input    | ✅ None  | No text inputs in the application              |
| localStorage       | ✅ Validated | `orniflight-theme` whitelist-validated     |
| Network            | ✅ None  | No fetch, no WebSocket, no XHR                 |
| Authentication     | ✅ N/A   | No auth system                                 |
| Data exposure      | ✅ None  | All data is simulated, local-only              |

---

## Development Guide

### Adding a New Component

1. Choose format:
   - **`.chaml`** for markup-heavy components (use Haml syntax)
   - **`.coffee`** for logic-heavy or Canvas components (use `h()` helper)
2. Import in `App.chaml`
3. Wire props from `useSimulation()` or parent state
4. Add styles in `main.sass` using `--of-` tokens
5. Add tests in `src/test/`

### Adding a New Theme Token

1. Add to `:root` block (dark theme) in `_tokens.sass`
2. Add corresponding value to `[data-theme="light"]` block
3. For colors needing `rgba()`, also add `-rgb` variant
4. Reference via `var(--of-token-name)` in `main.sass`
5. Never hardcode colors — always use tokens

### Running Tests

```bash
npx vitest          # Watch mode
npx vitest run      # Single run
npx vitest --ui     # Web UI
```

### Building for Production

```bash
npm run build       # Outputs to dist/
npm run preview     # Preview production build
```

### Test Architecture

Tests use Vitest with jsdom environment. Canvas components (WaveformCanvas,
GyroReadout, AircraftViewport) are mocked in `src/test/setup.js` since jsdom
lacks Canvas API support. The simulation hook is also mocked for component
tests, while `OrnithopterModel.test.coffee` tests the pure domain logic
directly without mocking.
