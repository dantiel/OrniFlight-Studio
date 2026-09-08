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
      flapPhase:       0
      pairCount:       2
      servoMounts:     []
      amplitude:       0
      servos:          (Array 16).fill 0
      waveformHistory: []
      batteryVoltage:  0
      flapFrequency:   0
      rssi:            0
      linkQuality:     0
      rcChannels:      []
      acceleration:    { x: 0, y: 0, z: 0 }
      magnetometer:    { x: 0, y: 0, z: 0 }
      source:           'offline'
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
          flapPhase = 0, pairCount = 2, servoMounts = []
          servos = [], waveformHistory = []
          batteryVoltage = 0, flapFrequency = 0
          rssi = 0, linkQuality = 0
          rcChannels = []
          accelX = 0, accelY = 0, accelZ = 0
          magnetometer = [0, 0, 0]
          source = 'offline'
        } = frame

        { ringIndex, ringBuffer } = get()
        ringBuffer[ringIndex] = frame
        sample = {
          t, wingL: wingAngleL, wingR: wingAngleR
          gyroRoll, gyroPitch, gyroYaw
          servo1: servos[0], servo2: servos[1], servo3: servos[2], servo4: servos[3]
          rcRoll: frame.rcRoll, rcPitch: frame.rcPitch
          rcYaw: frame.rcYaw, rcThrottle: frame.rcThrottle
          batteryVoltage, rssi, linkQuality
          accelX, accelY, accelZ
        }
        history = if waveformHistory?.length
          waveformHistory
        else
          [get().waveformHistory..., sample].slice -RING_SIZE
        set {
          t
          gyro: { roll: gyroRoll, pitch: gyroPitch, yaw: gyroYaw }
          attitude
          wingAngleL
          wingAngleR
          flapPhase
          pairCount
          servoMounts
          amplitude
          servos
          waveformHistory: history
          batteryVoltage
          flapFrequency
          rssi
          linkQuality
          rcChannels
          acceleration: { x: accelX, y: accelY, z: accelZ }
          magnetometer: { x: magnetometer[0] or 0, y: magnetometer[1] or 0, z: magnetometer[2] or 0 }
          source
          ringIndex: (ringIndex + 1) % RING_SIZE
          ringBuffer
        }

      getRing: -> get().ringBuffer
      getGyro: -> get().gyro
      setConnected: (connected) -> set { connected }
    ,
    name: '📡 TelemetryStore'
  )
)

export default useTelemetryStore