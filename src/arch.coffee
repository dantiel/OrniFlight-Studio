# ═══════════════════════════════════════════════════════════════
# OrniFlight Studio — Architecture Index
#
# This file documents the architectural layers and their
# integration points. Import patterns for each concern:
#
# ┌─────────────────────────────────────────────────────────┐
# │  State Management                                       │
# │  import useAppStore from './stores/useAppStore.coffee'   │
# │  configView = useAppStore((s) -> s.configView)          │
# ├─────────────────────────────────────────────────────────┤
# │  Telemetry Data (high-frequency)                        │
# │  import useTelemetry from './hooks/useTelemetry.coffee' │
# │  frame = useTelemetry()                                 │
# ├─────────────────────────────────────────────────────────┤
# │  Connection Lifecycle                                   │
# │  import useConnection from './hooks/useConnection.coffee'│
# │  { state, label, send } = useConnection()               │
# ├─────────────────────────────────────────────────────────┤
# │  Schema Validation                                      │
# │  import { parseTelemetry } from './schemas/...'         │
# │  frame = parseTelemetry(rawData)                        │
# ├─────────────────────────────────────────────────────────┤
# │  Functional Utilities                                   │
# │  import { map, pipe, curry } from './lib/essential.coffee'│
# ├─────────────────────────────────────────────────────────┤
# │  Worker (future)                                        │
# │  worker = new Worker('./workers/telemetryWorker.coffee') │
# └─────────────────────────────────────────────────────────┘
#
# Architecture principles:
#   1. Parse, don't validate — zod schemas at boundaries
#   2. Push, don't poll — RxJS streams, not setInterval
#   3. State machines, not booleans — XState for lifecycle
#   4. Small stores, not monoliths — Zustand slices
#   5. Pure core, imperative shell — functional utilities
#   6. Workers for computation, main thread for rendering
# ═══════════════════════════════════════════════════════════════

# Re-export everything from a single import if desired
import useAppStore from './stores/useAppStore.coffee'
import useTelemetryStore from './stores/useTelemetryStore.coffee'
import useConnection from './hooks/useConnection.coffee'
import useTelemetry from './hooks/useTelemetry.coffee'
import {
  pushTelemetry, gyroStream, batteryStream
} from './streams/telemetryStream.coffee'
import {
  parseTelemetry, TelemetryFrame
} from './schemas/telemetrySchema.coffee'
import * as _ from './lib/essential.coffee'

export {
  useAppStore, useTelemetryStore
  useConnection, useTelemetry
  pushTelemetry, gyroStream, batteryStream
  parseTelemetry, TelemetryFrame
  _
}