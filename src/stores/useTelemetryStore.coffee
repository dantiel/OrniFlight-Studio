###
# ORNIFLIGHT STUDIO — Telemetry Store (Zustand)
#
# Architectural role: high-frequency telemetry buffer.
# Updated every rAF frame (~60Hz) by the simulation loop.
#
# Frame shape (pushed by useSimulation):
#   t, gyroRoll, gyroPitch, gyroYaw, attitude, wingAngleL,
#   wingAngleR, amplitude, batteryVoltage, flapFrequency,
#   servos, waveformHistory, rssi, linkQuality
#
# Ring buffer: 256 frames for waveform rendering.
###
import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

RING_SIZE = 256

useTelemetryStore = create(
  devtools(
    (set, get) ->
      # ———— Latest snapshot ————
      t:               0
      gyro:            { roll: 0, pitch: 0, yaw: 0 }
      attitude:        { roll: 0, pitch: 0, yaw: 0 }
      wingAngleL:      0
      wingAngleR:      0
      amplitude:       0
      servos:          (Array 16).fill 0
      waveformHistory: []
      batteryVoltage:  0
      flapFrequency:   0
      rssi:            0
      linkQuality:     0
      connected:       false

      # ———— Ring buffer ————
      ringIndex:  0
      ringBuffer: (new Array RING_SIZE).fill null

      # ———— Actions ————
      update: (frame) ->
        {
          t = 0
          gyroRoll = 0, gyroPitch = 0, gyroYaw = 0
          attitude = { roll: 0, pitch: 0, yaw: 0 }
          wingAngleL = 0, wingAngleR = 0, amplitude = 0
          servos = [], waveformHistory = []
          batteryVoltage = 0, flapFrequency = 0
          rssi = 0, linkQuality = 0
        } = frame

        { ringIndex, ringBuffer } = get()
        ringBuffer[ringIndex] = frame
        set {
          t
          gyro: { roll: gyroRoll, pitch: gyroPitch, yaw: gyroYaw }
          attitude
          wingAngleL
          wingAngleR
          amplitude
          servos
          waveformHistory
          batteryVoltage
          flapFrequency
          rssi
          linkQuality
          ringIndex: (ringIndex + 1) % RING_SIZE
          ringBuffer
        }

      getRing: -> get().ringBuffer
      getGyro: -> get().gyro
    ,
    name: '📡 TelemetryStore'
  )
)

export default useTelemetryStore
