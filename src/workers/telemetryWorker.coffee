###
# ORNIFLIGHT STUDIO — Telemetry Worker
#
# Architectural role: offload CPU-intensive serial parsing
# and telemetry processing from the UI thread.
#
# Why a Worker:
#   - Serial port data arrives at 1–3 Mbit/s in bursts
#   - Binary protocol parsing (CRSF, SBUS, MSP) is CPU-bound
#   - UI thread must stay at 60fps for smooth waveform rendering
#   - Worker → main thread via SharedArrayBuffer or postMessage
#
# Pattern: Message-passing with typed commands
#   Main thread posts: { type: 'PARSE', buffer: ArrayBuffer }
#   Worker responds:   { type: 'FRAME', frame: TelemetryFrame }
#
# This skeleton mirrors the real firmware integration point.
# In simulation mode, it's bypassed — simulation pushes directly
# to the RxJS telemetrySubject.
#
# Activation: uncomment in vite.config.js worker settings,
# or import as: new Worker(new URL('./telemetryWorker.coffee', import.meta.url))
###
import { parseTelemetry } from '../schemas/telemetrySchema.coffee'

# ═══════════════════════════════════════════════════════════════
# Message handler — the worker's event loop
# ═══════════════════════════════════════════════════════════════
self.onmessage = (e) ->
  { type, buffer, timestamp } = e.data

  switch type
    # ── Parse raw serial buffer into structured frame ──
    when 'PARSE'
      try
        # In production: binary protocol parsing here
        # For now: assume JSON-encoded frame
        decoder = new TextDecoder()
        json = decoder.decode new Uint8Array buffer
        frame = JSON.parse json
        validated = parseTelemetry frame
        self.postMessage
          type: 'FRAME'
          frame: validated
          timestamp: timestamp || performance.now()
      catch err
        self.postMessage
          type: 'ERROR'
          error: err.message
          timestamp: performance.now()

    # ── Compute FFT on servo waveform ──
    when 'FFT'
      # Placeholder for DSP operations
      self.postMessage
        type: 'FFT_RESULT'
        frequencies: []
        magnitudes: []

    # ── Heartbeat / watchdog ──
    when 'PING'
      self.postMessage { type: 'PONG', timestamp: performance.now() }

    else
      self.postMessage
        type: 'ERROR'
        error: "Unknown command: #{type}"
