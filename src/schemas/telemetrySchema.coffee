###
# ORNIFLIGHT STUDIO — Runtime Type Schemas (zod)
# Zero-trust validation layer between firmware/simulation and UI.
# Every byte that crosses the boundary is parsed and validated.
#
# Architecture: Parse, Don't Validate
#   zod schemas return typed data or throw — no "if valid then" sprawl.
#   Components receive guaranteed-shape data, never raw bytes.
###
import { z } from 'zod'

# ═══════════════════════════════════════════════════════════════
# Telemetry frame — what the bird sends 100×/second
# ═══════════════════════════════════════════════════════════════
TelemetryFrame = z.object
  t:            z.number()                           # micros since boot
  gyroRoll:     z.number().min(-2000).max(2000)     # deg/s
  gyroPitch:    z.number().min(-2000).max(2000)
  gyroYaw:      z.number().min(-2000).max(2000)
  batteryVoltage: z.number().min(0).max(30)         # volts
  flapFrequency:  z.number().min(0).max(100)        # Hz
  servos:       z.array(z.number().min(0).max(1))   # 0–1 normalized
  rssi:         z.number().min(0).max(100).optional() # signal strength
  linkQuality:  z.number().min(0).max(100).optional()

# ═══════════════════════════════════════════════════════════════
# Servo configuration frame — sent to bird
# ═══════════════════════════════════════════════════════════════
ServoConfig = z.object
  index:    z.number().int().min(0).max(15)
  minPulse: z.number().int().min(500).max(2500)
  maxPulse: z.number().int().min(500).max(2500)
  center:   z.number().int().min(500).max(2500)
  rate:     z.number().min(0).max(100)
  inverted: z.boolean().default(false)

# ═══════════════════════════════════════════════════════════════
# PID tuning frame
# ═══════════════════════════════════════════════════════════════
PIDConfig = z.object
  axis: z.enum(['roll', 'pitch', 'yaw'])
  p:    z.number().min(0).max(100)
  i:    z.number().min(0).max(100)
  d:    z.number().min(0).max(100)
  maxI: z.number().min(0).max(1000).default(400)

# ═══════════════════════════════════════════════════════════════
# Profile (stored on bird EEPROM)
# ═══════════════════════════════════════════════════════════════
Profile = z.object
  id:        z.number().int().min(1).max(4)
  name:      z.string().min(1).max(24)
  servos:    z.array(ServoConfig).max(16)
  pidRoll:   PIDConfig
  pidPitch:  PIDConfig
  pidYaw:    PIDConfig

# ═══════════════════════════════════════════════════════════════
# Connection event (state machine transitions)
# ═══════════════════════════════════════════════════════════════
ConnectionEvent = z.enum([
  'CONNECT'
  'DISCONNECT'
  'CONNECTED'
  'DISCONNECTED'
  'DATA_TIMEOUT'
  'RECONNECT'
  'FIRMWARE_READY'
  'PROTOCOL_MISMATCH'
])

# ═══════════════════════════════════════════════════════════════
# Parse helpers — throws on invalid data, returns typed result
# ═══════════════════════════════════════════════════════════════
parseTelemetry = (data) -> TelemetryFrame.parse data
safeParseTelemetry = (data) -> TelemetryFrame.safeParse data
parseServoConfig = (data) -> ServoConfig.parse data
parsePIDConfig = (data) -> PIDConfig.parse data
parseProfile = (data) -> Profile.parse data

export {
  TelemetryFrame, ServoConfig, PIDConfig, Profile, ConnectionEvent
  parseTelemetry, safeParseTelemetry, parseServoConfig
  parsePIDConfig, parseProfile
  TelemetryFrame as default
}