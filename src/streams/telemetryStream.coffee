###
# ORNIFLIGHT STUDIO — Telemetry Stream (RxJS)
#
# Architectural role: reactive data pipeline between
# simulation/firmware and the UI layer.
#
# Why RxJS and not a simple event emitter:
#   - Operators: throttleTime, bufferTime, pairwise — waveform
#     rendering, FFT analysis, derivative computation become
#     declarative one-liners.
#   - Multicast: one data source, many subscribers (gyro viz,
#     waveform canvas, servo inspector) without duplication.
#   - Backpressure: when UI lags behind 1000Hz telemetry,
#     sampleTime or auditTime prevent queue buildup.
#   - Testable: marble testing for exact timing verification.
#
# Pattern: Subject as bridge, derived Observables for consumers
#   ┌──────────────┐     .next(frame)     ┌──────────────┐
#   │ Simulation   │ ───────────────────→ │ BehaviorSubj  │
#   │ / Firmware   │                      │ (latest)      │
#   └──────────────┘                      └──┬───┬───┬───┘
#                                            │   │   │
#                               ┌────────────┘   │   └──────────┐
#                               ▼                ▼              ▼
#                          gyroStream      servoStream    batteryStream
#                          .pairwise()     .distinctUntil  .throttleTime
#                          .map(diff)      Changed()       (1000)
###
import { BehaviorSubject, Subject } from 'rxjs'
import {
  map, pairwise, distinctUntilChanged, throttleTime, bufferTime, share
} from 'rxjs/operators'

# ═══════════════════════════════════════════════════════════════
# Primary stream — one frame pushed per simulation tick
# ═══════════════════════════════════════════════════════════════
telemetrySubject = new BehaviorSubject
  t: 0
  gyroRoll: 0; gyroPitch: 0; gyroYaw: 0
  servos: (Array 16).fill 0
  batteryVoltage: 0
  flapFrequency: 0
  rssi: 0
  linkQuality: 0

# Command subject — UI → simulation/firmware
commandSubject = new Subject()

# ═══════════════════════════════════════════════════════════════
# Derived streams (lazy — only active when subscribed)
# ═══════════════════════════════════════════════════════════════

# Emits only when gyro values change (skip duplicate frames)
gyroStream = telemetrySubject.pipe(
  map (f) -> { roll: f.gyroRoll, pitch: f.gyroPitch, yaw: f.gyroYaw }
  distinctUntilChanged (a, b) ->
    a.roll == b.roll and a.pitch == b.pitch and a.yaw == b.yaw
  share()
)

# Gyro angular velocity (derivative of gyro angle)
gyroDeltaStream = gyroStream.pipe(
  pairwise()
  map ([prev, curr]) ->
    roll:  curr.roll  - prev.roll
    pitch: curr.pitch - prev.pitch
    yaw:   curr.yaw   - prev.yaw
  share()
)

# Servo positions — emit only on change
servoStream = telemetrySubject.pipe(
  map (f) -> f.servos
  distinctUntilChanged (a, b) ->
    a.length == b.length and a.every (v, i) -> v == b[i]
  share()
)

# Battery — throttled to 1Hz (no need for 60Hz battery updates)
batteryStream = telemetrySubject.pipe(
  map (f) -> { voltage: f.batteryVoltage, frequency: f.flapFrequency }
  throttleTime 1000
  share()
)

# Ring buffer for waveform rendering — last 256 frames
waveformStream = telemetrySubject.pipe(
  bufferTime 50, null, 256   # emit every 50ms with up to 256 frames
  share()
)

# ═══════════════════════════════════════════════════════════════
# Push helpers — called by simulation engine or serial parser
# ═══════════════════════════════════════════════════════════════
pushTelemetry = (frame) -> telemetrySubject.next frame
pushCommand   = (cmd)    -> commandSubject.next cmd
getLatest     = -> telemetrySubject.getValue()

export {
  telemetrySubject, commandSubject
  gyroStream, gyroDeltaStream, servoStream, batteryStream, waveformStream
  pushTelemetry, pushCommand, getLatest
}