# OrniFlight Studio — Component Reference

## Overview

OrniFlight Studio contains 10 UI components in `src/components/`. Components use
a mix of CoffeeScript (`.coffee`) and CoffeeHaml (`.chaml`) files:

- **`.chaml` files** — Declarative Haml markup with CoffeeScript execution blocks.
  Compiled by CoffeeHaml Vite plugin to JSX.
- **`.coffee` files** — Pure CoffeeScript components using `createElement` directly.
  Compiled by the CoffeeScript Vite plugin.

### Why Both Formats?

- `.chaml` is preferred for markup-heavy components (Sidebar, ServoInspector,
  ConnectionBar). The Haml syntax is more concise and readable for deeply nested
  layouts with conditionals and loops.
- `.coffee` is used for logic-heavy or Canvas-based components (AircraftViewport,
  WaveformCanvas, GyroReadout, TabBar, ViewModeToggle, ThemeToggle). These have
  minimal markup and benefit from CoffeeScript's expression-oriented syntax.

All components receive data via React props and communicate upward via callback
props. No component accesses global state directly.

---

## Component Tree

```
App.chaml
├── ConnectionBar.chaml
│   ├── ViewModeToggle.coffee
│   └── ThemeToggle.coffee
├── Sidebar.chaml
├── AircraftViewport.coffee
├── TabBar.coffee
├── ServoInspector.chaml
├── TelemetryLab.chaml
│   ├── WaveformCanvas.coffee
│   └── GyroReadout.coffee
```

---

## Component Details

### App.chaml
**File:** `src/app/App.chaml`
**Type:** CoffeeHaml
**Role:** Root application component

**State:**
- `activeTab` — Current inspector tab ('servos', 'pid', 'ondas', 'sensors', 'profiles', 'receiver')
- `viewMode` — Workspace layout ('full', 'split', 'compact')
- `waveCurves` — Array of 2 curve IDs for waveform panel
- `gyroCurves` — Array of 1 curve ID for gyro panel

**Props passed down:**
- To `ConnectionBar`: `connected`, `batteryVoltage`, `flapFrequency`, `viewMode`, `onViewModeChange`
- To `Sidebar`: `servos`, `selectedServoIndex`, `onSelectServo`, `sticks`, `onStickChange`, `onApplyPreset`
- To `AircraftViewport`: `attitude`, `wingAngleL`, `wingAngleR`, `flapFrequency`, `onBump`
- To `TabBar`: `activeTab`, `onTabChange`
- To `ServoInspector`: `servo`, `index`, `onParamChange`, `pidGains`, `ondasParams`, `onPidChange`, `onOndasChange`
- To `TelemetryLab`: `waveformHistory`, `gyro`, `servoPositions`, `waveCurves`, `onWaveCurveChange`, `gyroCurves`, `onGyroCurveChange`

**Structure:**
```haml
%div.studio-shell
  %ConnectionBar{ ... }
  %div.studio-workspace{ class: "view-#{viewMode}" }
    %Sidebar{ ... }
    %div.studio-viewport
      %AircraftViewport{ ... }
      %div.viewport-overlay  ← Freq / Amp / t badges
    %div.studio-inspector
      %TabBar{ ... }
      - if activeTab == 'servos'
        %ServoInspector{ ... }
      - else if ...
        (Coming Soon placeholder)
  %TelemetryLab{ ... }
```

---

### ConnectionBar.chaml
**File:** `src/components/ConnectionBar.chaml`
**Type:** CoffeeHaml
**Role:** Top toolbar — brand, connection status, view mode toggle, theme toggle

**Props:**
| Prop              | Type       | Description                              |
|-------------------|-----------|------------------------------------------|
| `connected`       | boolean   | Whether simulation is active             |
| `batteryVoltage`  | number    | Battery voltage (V)                      |
| `flapFrequency`   | number    | Flapping frequency (Hz)                  |
| `viewMode`        | string    | Current view mode ('full'/'split'/'compact') |
| `onViewModeChange`| function  | Callback for view mode switch            |

**Conditional rendering:**
- `connected == true` → "SIMULATION" badge (amber dot + glow)
- `connected == false` → "DISCONNECTED" badge (red)

**Static elements:**
- "OrniFlight Studio" brand (Orbitron font)
- Battery voltage readout (BAT X.XV)
- Flap frequency readout (FLAP X.X Hz)
- "OrniFlight Studio v0.1 · Prototype" version string

**Drag region:** The entire toolbar has `-webkit-app-region: drag` for future
Tauri integration, with interactive elements selectively overridden to `no-drag`.

---

### Sidebar.chaml
**File:** `src/components/Sidebar.chaml`
**Type:** CoffeeHaml
**Role:** Left sidebar — servo list, stick inputs, presets

**Props:**
| Prop                | Type       | Description                        |
|---------------------|-----------|------------------------------------|
| `servos`            | array     | Array of 4 servo config objects    |
| `selectedServoIndex`| number    | Currently selected servo (0-3)     |
| `onSelectServo`     | function  | Callback(index) for selection      |
| `sticks`            | object    | `{throttle, roll, pitch, yaw}` in µs |
| `onStickChange`     | function  | Callback(axis, value) for stick    |
| `onApplyPreset`     | function  | Callback(name) for preset          |

**Sections:**
1. **Aircraft** — Static nav links (Servos, Sensors, Profiles, Receiver) — future use
2. **Servo Selection** — Dynamically renders 4 servo items with active state, CH badge
3. **Stick Input** — Range sliders for Throttle, Roll, Pitch, Yaw (1000-2000µs)
4. **Presets** — Gentle / Acro / Race buttons

---

### AircraftViewport.coffee
**File:** `src/components/AircraftViewport.coffee`
**Type:** CoffeeScript (useEffect-heavy, Three.js imperative)
**Role:** 3D ornithopter visualization using Three.js

**Props:**
| Prop           | Type       | Description                                   |
|---------------|-----------|-----------------------------------------------|
| `attitude`    | object    | `{roll, pitch, yaw}` in radians              |
| `wingAngleL`  | number    | Left wing angle in radians                    |
| `wingAngleR`  | number    | Right wing angle in radians                   |
| `flapFrequency`| number   | Flapping frequency (Hz) — not directly used   |
| `onBump`      | function  | Callback for click-to-disturb                 |

**Three.js scene structure:**
```
Scene
├── AmbientLight (0x334466, 1.8)
├── DirectionalLight key (0xffcc88, 2.0) @ (3,5,4)
├── DirectionalLight rim (0x6688cc, 0.8) @ (-2,1,-3)
├── DirectionalLight fill (0x446688, 0.5) @ (0,-0.5,1)
├── GridHelper (ground reference, 5x10)
└── Model (Group, scale 1.4×)
    ├── fuseGroup (rotated +PI/2 on X-axis)
    │   ├── CylinderGeometry body (r=0.1..0.14, h=0.65)
    │   ├── CylinderGeometry nose (r=0.01..0.1, h=0.16) @ (0, 0.4, 0)
    │   └── CylinderGeometry tailCone (r=0.14..0.04, h=0.22) @ (0, -0.43, 0)
    ├── wingPivotL @ (0.15, 0.03, 0.05)
    │   └── ExtrudeGeometry wing (bezier shape)
    ├── wingPivotR @ (-0.15, 0.03, 0.05)
    │   └── ExtrudeGeometry wing (rotated PI on Y)
    ├── BoxGeometry hstab (0.45×0.012×0.1) @ (0, 0.02, -0.58)
    ├── BoxGeometry vfin (0.012×0.12×0.09) @ (0, 0.07, -0.58)
    ├── 2× CylinderGeometry servo mounts @ (±0.15, -0.02, 0.05)
    └── SphereGeometry center dot (r=0.04)
```

**Lifecycle:**
- **Mount:** Creates renderer, scene, camera, lights, model. Starts rAF loop.
- **Update:** Props change → `useEffect` updates model rotation and wing pivots.
- **Unmount:** Cancels rAF, removes listeners, disposes renderer. Click listener
  cleanup uses stored reference (VALIDATIO fix).

**Model transforms:**
```coffee
model.rotation.set(roll, yaw, -pitch)        # Attitude
wingPivotL.rotation.z = wingAngleL            # Left wing
wingPivotR.rotation.z = -wingAngleR           # Right wing (mirrored)
```

**Camera:** PerspectiveCamera 45°, at (0.5, 0.35, 2.4) looking at origin.

**Performance:** pixelRatio capped at 2x, renderer created once on mount.

---

### TabBar.coffee
**File:** `src/components/TabBar.coffee`
**Type:** CoffeeScript
**Role:** Inspector tab navigation

**Props:**
| Prop         | Type     | Description                    |
|-------------|---------|--------------------------------|
| `activeTab` | string  | Currently selected tab ID      |
| `onTabChange`| function| Callback(tabId) on click       |

**Tabs:**
| ID         | Label    | Icon | Status      |
|-----------|---------|------|-------------|
| `servos`  | Servos  | ◇    | Active      |
| `pid`     | PID     | △    | Coming Soon |
| `ondas`   | ONDAS   | ∿    | Coming Soon |
| `sensors` | Sensors | ◎    | Coming Soon |
| `profiles`| Profiles| ▣    | Coming Soon |
| `receiver`| Receiver| ⇄    | Coming Soon |

**Implementation:** Pure `createElement` with `.map()` over `TABS` array.
Active tab gets `.tab-bar-item.active` class.

---

### ServoInspector.chaml
**File:** `src/components/ServoInspector.chaml`
**Type:** CoffeeHaml
**Role:** Servo configuration panel with PID and ONDAS sections

**Props:**
| Prop           | Type     | Description                             |
|---------------|---------|-----------------------------------------|
| `servo`       | object  | Single servo config (midpoint, min, max, rate, amplitudeScale) |
| `index`       | number  | Servo index (0-3) for callback          |
| `onParamChange`| function| Callback(index, param, value)           |
| `pidGains`    | object  | All 9 PID gain values                   |
| `onPidChange` | function| Callback(gainId, value)                 |
| `ondasParams` | object  | ONDAS mixer parameter values            |
| `onOndasChange`| function| Callback(paramId, value)               |

**Sections:**
1. **Servo X** — Midpoint, Min PWM, Max PWM, Rate, Amplitude sliders
2. **PID Gains** — Roll/Pitch/Yaw P/I/D (9 sliders with context-appropriate ranges)
3. **ONDAS Mixer** — 7 sliders (Cadence, Ferocity P, Ferocity D, Balance, Warp, Anchor, Resonance)

**Slider ranges by parameter:**
| Parameter Type | Min | Max  | Step  |
|---------------|-----|------|-------|
| PWM values    | 500 | 2500 | 1     |
| Rate          | -100| 100  | 1     |
| Amplitude     | 0   | 2    | 0.1   |
| PID_P         | 0   | 15   | 0.1   |
| PID_I         | 0   | 0.2  | 0.01  |
| PID_D         | 0   | 50   | 0.5   |
| ONDAS         | 0   | 100  | 1     |

---

### TelemetryLab.chaml
**File:** `src/components/TelemetryLab.chaml`
**Type:** CoffeeHaml
**Role:** Bottom panel — waveform plot, gyro bars, PWM readout

**Props:**
| Prop                | Type     | Description                              |
|--------------------|---------|------------------------------------------|
| `waveformHistory`  | array   | Ring buffer of `{t, wingL, wingR, gyroRoll, gyroPitch, gyroYaw}` |
| `gyro`             | object  | `{roll, pitch, yaw}` in rad/s            |
| `servoPositions`   | array   | 4 PWM values (1000-2000)                 |
| `waveCurves`       | array   | 2 curve IDs for waveform selectors       |
| `onWaveCurveChange`| function| Callback([curve1, curve2])              |
| `gyroCurves`       | array   | 1 curve ID for gyro selector             |
| `onGyroCurveChange`| function| Callback([curve])                        |

**Panels:**
1. **Servo Waveform** — Dual curve selector dropdowns + `WaveformCanvas`
2. **Gyro Response** — Single curve selector + `GyroReadout`
3. **Servo PWM Output** — CH1-CH4 PWM values + Rate Roll/Pitch/Yaw readouts

**Curve selector options:** Wing L, Wing R, Gyro Roll, Gyro Pitch, Gyro Yaw

---

### WaveformCanvas.coffee
**File:** `src/components/WaveformCanvas.coffee`
**Type:** CoffeeScript (Canvas 2D imperative)
**Role:** 2D time-series plot of selected telemetry curves

**Props:**
| Prop      | Type   | Description                                      |
|----------|--------|--------------------------------------------------|
| `history`| array  | Ring buffer of telemetry samples (max 200)       |
| `curves` | array  | Curve IDs to render (e.g. `['wingL', 'wingR']`) |

**Rendering:**
- **Grid:** 4 horizontal, 8 vertical lines + center zero line
- **Time window:** Last 3.0 seconds (horizontal scale)
- **Amplitude:** ±60° for wing angles, ±720°/s for gyro rates
- **Colors:** Per-curve mapping (orange=wingL, blue=wingR, red=roll, green=pitch, purple=yaw)
- **Legend:** Top-left, one line per curve with color swatch
- **HiDPI:** Uses `devicePixelRatio` scaling

---

### GyroReadout.coffee
**File:** `src/components/GyroReadout.coffee`
**Type:** CoffeeScript (Canvas 2D imperative)
**Role:** Horizontal bar display of gyro rates

**Props:**
| Prop  | Type   | Description                        |
|------|--------|------------------------------------|
| `gyro`| object | `{roll, pitch, yaw}` in rad/s     |

**Rendering:**
- Three horizontal bars (ROLL, PITCH, YAW)
- Center-zero display: positive values extend right, negative left
- Scale: ±720°/s max
- Value labels at bar ends

---

### ViewModeToggle.coffee
**File:** `src/components/ViewModeToggle.coffee`
**Type:** CoffeeScript
**Role:** Three-button layout mode switcher

**Props:**
| Prop           | Type     | Description                         |
|---------------|---------|-------------------------------------|
| `mode`        | string  | Current mode ('full'/'split'/'compact') |
| `onModeChange`| function| Callback(modeId) on click           |

**Modes:**
| ID       | Label   | Icon | Description                        |
|---------|--------|------|------------------------------------|
| `full`  | Full   | ▣    | 3D viewport only                  |
| `split` | Split  | ▧    | 3D + inspector side by side       |
| `compact`| Compact| ▱   | Small 3D + multiple plotter graphs |

Positioned in the toolbar via `ConnectionBar.chaml`.

---

### ThemeToggle.coffee
**File:** `src/components/ThemeToggle.coffee`
**Type:** CoffeeScript (useState + useEffect)
**Role:** Dark/light theme toggle with localStorage persistence

**No props** — self-contained.

**State:** `theme` — 'dark' (default) or 'light'

**Behavior:**
1. **Mount:** Reads `localStorage('orniflight-theme')`, validates against `['dark', 'light']`,
   sets `data-theme` attribute on `<html>`.
2. **Toggle:** Flips state, updates DOM attribute, persists to localStorage.
3. **Icon:** ☼ (dark mode, switch to light) / ☾ (light mode, switch to dark)

**localStorage key:** `orniflight-theme`

---

## Simulation Layer

### OrnithopterModel.coffee
**File:** `src/simulation/OrnithopterModel.coffee`
**Lines:** 372
**Role:** Pure domain model — no React, no DOM, no rendering

**Key systems:**
- **Flapping physics:** Sinusoidal wing motion at `flapFrequency` with `baseAmplitude`
- **Gyro integration:** Wing forces → angular rates via thrust factor
- **PID controller:** 3-axis (roll/pitch/yaw) with full P/I/D
- **ONDAS mixer:** 14-parameter waveform mixer (cadence, ferocity, warp, anchor, resonance, etc.)
- **Servo mapping:** Wing angles → 4-channel PWM (1000-2000µs)
- **Battery simulation:** Voltage sag based on consumption
- **Presets:** Gentle (4Hz/30°), Acro (6Hz/45°), Race (8Hz/55°)

**Internal timestep:** 500Hz (5 sub-steps per frame at 60fps)
**Telemetry ring buffer:** 200 samples max

### useSimulation.coffee
**File:** `src/simulation/useSimulation.coffee`
**Role:** React hook bridging the simulation engine to the component tree

**Pattern:** Singleton engine + rAF-driven snapshot extraction.
- Creates one `OrnithopterModel` instance (module-level singleton).
- `requestAnimationFrame` loop calls `engine.step(dt)` and shallow-clones
  telemetry into React state at ~60fps.
- Exposes all engine actions as memoized callbacks.
- dt capped at 50ms to prevent spiral-of-death.

---

## Hyperscript Helper

### h.coffee
**File:** `src/app/h.coffee`
**Role:** Thin wrapper around `React.createElement` with child flattening.

```coffee
h = (tag, attrs, children...) ->
  # Flatten nested arrays, filter null/undefined/false
  createElement tag, attrs, flat...
```

Used in `.coffee` components for concise element creation:
```coffee
h 'div', { className: 'box' },
  h 'span', null, 'Hello'
```
