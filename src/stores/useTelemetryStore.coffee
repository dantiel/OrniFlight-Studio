###
# ORNIFLIGHT STUDIO — Telemetry Store (Zustand)
#
# Architectural role: high-frequency telemetry buffer.
# Updated every rAF frame (~60Hz) by simulation engine.
#
# Middleware: devtools only (persist excluded — telemetry
# is ephemeral; ring buffer would waste localStorage).
#
# Ring buffer: 256 frames for waveform rendering.
###
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

RING_SIZE = 256

useTelemetryStore = create(
  devtools(
    (set, get) ->
      # ── Latest snapshot ──
      t: 0
      gyro:       { roll: 0, pitch: 0, yaw: 0 }
      servos:     (Array 16).fill 0
      batteryVoltage: 0
      flapFrequency:  0
      rssi:        0
      linkQuality: 0
      connected:    false

      # ── Ring buffer ──
      ringIndex: 0
      ringBuffer: (new Array RING_SIZE).fill null

      # ── Actions ──
      update: (frame) ->
        { ringIndex, ringBuffer } = get()
        ringBuffer[ringIndex] = frame
        set
          t:              frame.t || 0
          gyro:
            roll:  frame.gyroRoll || 0
            pitch: frame.gyroPitch || 0
            yaw:   frame.gyroYaw || 0
          servos:         frame.servos || []
          batteryVoltage: frame.batteryVoltage || 0
          flapFrequency:  frame.flapFrequency || 0
          rssi:           frame.rssi || 0
          linkQuality:    frame.linkQuality || 0
          ringIndex:      (ringIndex + 1) % RING_SIZE
          ringBuffer

      getRing:  -> get().ringBuffer
      getGyro:  -> get().gyro
    ,
    name: '📡 TelemetryStore'
  )
)

export default useTelemetryStore