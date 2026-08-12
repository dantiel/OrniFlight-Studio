# Migration Notes — orniflight-configurator → OrniFlight Studio

## Assessment Summary

The existing `orniflight-configurator` is a Betaflight Configurator fork substantially
rebuilt for ornithopter control. It contains valuable domain logic alongside
considerable legacy infrastructure.

## Reusable Assets

### Directly Portable (with extraction)

| Source                          | Destination                  | Notes                                  |
|---------------------------------|------------------------------|----------------------------------------|
| `src/js/msp/MSPCodes.coffee`    | `src/protocol/MSPCodes.coffee` | Clean enum, no dependencies           |
| `src/js/msp/MSPHelper.coffee`   | `src/protocol/`              | Needs jQuery/DOM decoupling            |
| `src/js/model.coffee`           | Already ported               | `formaDoBaterDasAsas` + 3D model       |
| `src/js/tabs/simulator.coffee`  | Already ported               | ONDAS algorithm → `OrnithopterModel`   |
| `src/css/main.sass`             | Reference only               | Dark theme tokens, control sizing      |
| `src/css/main-dark.sass`        | Reference only               | Dark variant patterns                  |

### Behavioral Reference

- Servo configuration workflow (`src/tabs/servos.haml`, `src/js/tabs/servos.coffee`)
- PID tuning UI logic (`src/tabs/pid_tuning.haml`)
- Serial connection lifecycle (`src/js/serial_backend.coffee`)
- MSP message parsing (`src/js/msp.coffee`)
- Firmware version detection (`src/js/fc.coffee`)
- Port handler abstraction (`src/js/port_handler.coffee`)

### NOT to Migrate

- jQuery DOM manipulation (`$('#content').load(...)`)
- Global mutable state (`FC`, `CONFIG`, `SERVO_CONFIG`, etc.)
- NW.js window management and build tooling
- Gulp build pipeline
- Legacy Betaflight structures (`BF_CONFIG`, `FEATURE_CONFIG`)
- Tab-switching architecture
- Inline HTML templates loaded via AJAX

## Architecture Differences

| Aspect               | Configurator (old)        | Studio (new)                    |
|----------------------|---------------------------|---------------------------------|
| Rendering            | jQuery + Haml → HTML      | React + CoffeeScript            |
| State                | Global mutable objects    | Component-local + hooks         |
| Transport            | Direct serial in GUI      | Abstracted Transport interface  |
| Build                | Gulp + concat             | Vite + ES modules               |
| Desktop              | NW.js                     | Future: Tauri                   |
| Styling              | Sass (single file)        | Sass modules + tokens           |
| Telemetry            | Polling timers            | rAF-driven snapshots            |

## CoffeeHaml Status

CoffeeHaml v0.1.0 is included as a dependency but **not yet used for primary
components**. The compiler correctly transforms Haml syntax to React JSX, but
the current version does not produce valid ES module exports — it emits bare
JSX expressions without wrapping them in an `export` statement. This makes
`.chaml` files non-importable as React components in the Vite/Rollup pipeline.

Additionally, CoffeeHaml does not support top-level `import`/`export`
statements within `.chaml` files — the entire file is parsed as Haml markup,
and any JavaScript at the root level is treated as text content.

### Path Forward

1. **Short-term**: Components are authored in CoffeeScript using a thin
   `h()` hyperscript helper (`src/app/h.coffee`). This preserves the
   CoffeeScript aesthetic while remaining fully functional.

2. **Medium-term**: Either:
   - Contribute `export` wrapping to CoffeeHaml upstream
   - Write a Vite plugin that wraps CoffeeHaml output in component exports
   - Add a `:script` filter or front-matter section to CoffeeHaml

3. **Long-term**: Once CoffeeHaml supports proper module exports, migrate
   components from `h()` calls to `.chaml` templates. The hyperscript
   approach produces identical React element trees, so the migration is
   mechanical.

## Simulation Engine

The `OrnithopterModel` class in `src/simulation/` is a direct port of the
ONDAS algorithm from the configurator's simulator tab, cleaned up and
modernized:

- No DOM dependencies
- Configurable timestep
- Clean parameter interface
- Telemetry snapshot system for React binding
- Preset system (Gentle / Acro / Race)

## Next Steps

1. **MSP Protocol Layer**: Extract MSP message definitions and parser from
   configurator into `src/protocol/`.
2. **WebSerial Transport**: Implement `WebSerialTransport` implementing the
   `Transport` interface.
3. **Firmware Management**: Workspace for flashing and firmware info.
4. **Full Servo Configuration**: Complete parameter set from firmware.
5. **i18n**: Port localization infrastructure.
6. **Tauri Shell**: Desktop wrapper with native serial and file system.
