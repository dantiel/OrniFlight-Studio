import ByteReader from './byteReader.coffee'

SIGNATURE_LENGTH = 32

decodeApiVersion = (payload) ->
  reader = new ByteReader payload
  protocol = reader.u8()
  major = reader.u8()
  minor = reader.u8()
  { protocol, major, minor, version: "#{major}.#{minor}.0" }

decodeVariant = (payload) -> new ByteReader(payload).ascii 4

decodeVersion = (payload) ->
  reader = new ByteReader payload
  major = reader.u8()
  minor = reader.u8()
  patch = reader.u8()
  { major, minor, patch, version: "#{major}.#{minor}.#{patch}" }

decodeBuildInfo = (payload) ->
  reader = new ByteReader payload
  date = reader.ascii 11
  time = reader.ascii 8
  revision = if reader.remaining() >= 7 then reader.ascii(7) else ''
  { date, time, revision, label: "#{date} #{time}" }

decodeBoardInfo = (payload) ->
  reader = new ByteReader payload
  identifier = reader.ascii 4
  hardwareRevision = reader.u16()
  boardType = reader.u8()
  targetCapabilities = reader.u8()
  targetName = reader.lengthPrefixedAscii()
  boardName = reader.lengthPrefixedAscii()
  manufacturerId = reader.lengthPrefixedAscii()
  signature = if reader.remaining() >= SIGNATURE_LENGTH then reader.take(SIGNATURE_LENGTH) else new Uint8Array 0
  mcuTypeId = if reader.remaining() then reader.u8() else 255
  configurationState = if reader.remaining() then reader.u8() else null
  {
    identifier, hardwareRevision, boardType, targetCapabilities
    targetName, boardName, manufacturerId, signature
    mcuTypeId, configurationState
  }

decodeUid = (payload) ->
  reader = new ByteReader payload
  words = [reader.u32(), reader.u32(), reader.u32()]
  value = words.map((word) -> word.toString(16).padStart(8, '0')).join ''
  { words, value }

decodeName = (payload) -> new ByteReader(payload).ascii payload.length

decodeStatus = (payload, extended = true) ->
  reader = new ByteReader payload
  cycleTime = reader.u16()
  i2cErrors = reader.u16()
  sensorMask = reader.u16()
  flightModeFlags = reader.u32()
  profile = reader.u8()
  cpuLoad = reader.u16()
  result = { cycleTime, i2cErrors, sensorMask, flightModeFlags, profile, cpuLoad }
  if extended and reader.remaining() >= 2
    result.profileCount = reader.u8()
    result.rateProfile = reader.u8()
  else if reader.remaining() >= 2
    result.gyroCycleTime = reader.u16()
  if reader.remaining()
    extraModeBytes = reader.u8()
    result.extraFlightModeFlags = Array.from reader.take(Math.min(extraModeBytes, reader.remaining()))
  if reader.remaining()
    result.armingDisableFlagCount = reader.u8()
  if reader.remaining() >= 4
    result.armingDisableFlags = reader.u32()
  result.armed = Boolean(flightModeFlags & 1)
  result.sensors =
    accelerometer: Boolean(sensorMask & 1)
    barometer: Boolean(sensorMask & 2)
    magnetometer: Boolean(sensorMask & 4)
    gps: Boolean(sensorMask & 8)
    rangefinder: Boolean(sensorMask & 16)
    gyroscope: Boolean(sensorMask & 32)
  result

decodeRawImu = (payload) ->
  reader = new ByteReader payload
  acceleration = [reader.i16() / 512, reader.i16() / 512, reader.i16() / 512]
  # OrniFlight API 1.49 writes gyroRateDps() directly on the wire.
  gyroscope = [reader.i16(), reader.i16(), reader.i16()]
  magnetometer = [reader.i16() / 1090, reader.i16() / 1090, reader.i16() / 1090]
  { acceleration, gyroscope, magnetometer }

decodeAttitude = (payload) ->
  reader = new ByteReader payload
  { roll: reader.i16() / 10, pitch: reader.i16() / 10, yaw: reader.i16() }

decodeChannels = (payload) ->
  reader = new ByteReader payload
  values = []
  values.push reader.u16() while reader.remaining() >= 2
  values

decodeRxMap = (payload) -> Array.from payload
decodeServos = decodeChannels

decodeAnalog = (payload) ->
  reader = new ByteReader payload
  legacyVoltage = reader.u8() / 10
  consumedMah = reader.u16()
  rssiRaw = reader.u16()
  amperage = reader.i16() / 100
  voltage = if reader.remaining() >= 2 then reader.u16() / 100 else legacyVoltage
  { voltage, consumedMah, rssiRaw, amperage }

decodeBatteryState = (payload) ->
  reader = new ByteReader payload
  cellCount = reader.u8()
  capacityMah = reader.u16()
  legacyVoltage = reader.u8() / 10
  consumedMah = reader.u16()
  amperage = reader.i16() / 100
  state = if reader.remaining() then reader.u8() else 0
  voltage = if reader.remaining() >= 2 then reader.u16() / 100 else legacyVoltage
  { cellCount, capacityMah, consumedMah, amperage, state, voltage }

# ── Servo configuration (MSP 120 / 212) ──────────────────────
# Wire layout per servoParam_t: u16 min, u16 max, u16 middle,
# i8 rate, u8 angleAtMin, u8 angleAtMax, u8 forwardFromChannel,
# u32 reversedSources. MSP 120 streams records; 212 prefixes index.
SERVO_CONFIG_BYTES = 14
MAX_SERVO_CONFIGS = 8
DEFAULT_SERVO_SWEEP = 45

decodeServoConfigurations = (payload) ->
  reader = new ByteReader payload
  configs = []
  while reader.remaining() >= SERVO_CONFIG_BYTES and
      configs.length < MAX_SERVO_CONFIGS
    configs.push {
      index: configs.length
      min: reader.u16()
      max: reader.u16()
      middle: reader.u16()
      rate: reader.i8()
      angleAtMin: reader.u8()
      angleAtMax: reader.u8()
      forwardFromChannel: reader.u8()
      reversedSources: reader.u32()
    }
  configs

encodeServoConfiguration = (index, config = {}) ->
  index = Math.max 0, Math.min(MAX_SERVO_CONFIGS - 1, Number(index) or 0)
  out = new Uint8Array SERVO_CONFIG_BYTES + 1
  view = new DataView out.buffer
  view.setUint8 0, index
  view.setUint16 1, config.min ? 1000, true
  view.setUint16 3, config.max ? 2000, true
  view.setUint16 5, config.middle ? 1500, true
  view.setInt8 7, config.rate ? 100, true
  view.setUint8 8, config.angleAtMin ? DEFAULT_SERVO_SWEEP
  view.setUint8 9, config.angleAtMax ? DEFAULT_SERVO_SWEEP
  view.setUint8 10, config.forwardFromChannel ? index
  view.setUint32 11, config.reversedSources ? 0, true
  out

encodeName = (name) ->
  value = String(name or '').slice 0, 24
  Uint8Array.from Array.from(value).map((character) -> character.charCodeAt(0) & 0xff)

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

clampU16 = (value) ->
  Math.max 0, Math.min 65535, Math.round finiteOr 0, value

clampU8 = (value) ->
  Math.max 0, Math.min 255, Math.round finiteOr 0, value

# ── PID tuning (MSP 112 / 202) ──────────────────────────────
# Wire layout: 24 bytes — four axes in fixed order roll → pitch →
# yaw → flap, each P u16×1000, I u16×1000, D u16×1000 (little-endian).
# The ×1000 scaling keeps gain steps of 0.001 lossless on the wire.
PID_AXES = Object.freeze ['roll', 'pitch', 'yaw', 'flap']
PID_TERMS = Object.freeze ['P', 'I', 'D']
PID_TUNING_BYTES = 24
PID_SCALE = 1000

encodePidTuning = (pid = {}) ->
  out = new Uint8Array PID_TUNING_BYTES
  view = new DataView out.buffer
  offset = 0
  for axis in PID_AXES
    gains = pid[axis] or {}
    for term in PID_TERMS
      view.setUint16 offset, clampU16(gains[term] * PID_SCALE), true
      offset += 2
  out

decodePidTuning = (payload) ->
  reader = new ByteReader payload
  result = {}
  for axis in PID_AXES
    gains = {}
    for term in PID_TERMS
      gains[term] = if reader.remaining() >= 2
        reader.u16() / PID_SCALE
      else
        0
    result[axis] = gains
  result

# ── RC tuning (MSP 111 / 204) ───────────────────────────────
# Wire layout: 3 bytes — rcRate u8, superRate u8, expo u8.
encodeRcTuning = (rate = {}) ->
  Uint8Array.from [
    clampU8 rate.rcRate
    clampU8 rate.superRate
    clampU8 rate.expo
  ]

decodeRcTuning = (payload) ->
  reader = new ByteReader payload
  rcRate: if reader.remaining() then reader.u8() else 0
  superRate: if reader.remaining() then reader.u8() else 0
  expo: if reader.remaining() then reader.u8() else 0

# ── Filter configuration (MSP 92 / 193) ─────────────────────
# Wire layout: 7 bytes — gyroDlpfHz u16, gyroNotchHz u16,
# gyroNotchQ u8, dTermDlpfHz u16 (little-endian).
encodeFilterConfig = (filter = {}) ->
  out = new Uint8Array 7
  view = new DataView out.buffer
  view.setUint16 0, clampU16(filter.gyroDlpfHz), true
  view.setUint16 2, clampU16(filter.gyroNotchHz), true
  view.setUint8 4, clampU8(filter.gyroNotchQ)
  view.setUint16 5, clampU16(filter.dTermDlpfHz), true
  out

decodeFilterConfig = (payload) ->
  reader = new ByteReader payload
  gyroDlpfHz: if reader.remaining() >= 2 then reader.u16() else 0
  gyroNotchHz: if reader.remaining() >= 2 then reader.u16() else 0
  gyroNotchQ: if reader.remaining() then reader.u8() else 0
  dTermDlpfHz: if reader.remaining() >= 2 then reader.u16() else 0

# ── ONDAS profile (MSP 114 / 206) ───────────────────────────
# Wire layout: 10 bytes — one u8 per key in ONDAS_KEYS order.
ONDAS_DEFAULTS = Object.freeze
  cadence_gain: 30
  ferocity_d_gain: 40
  ferocity_p_gain: 20
  balance_gain: 10
  ferocity_roll_gain: 30
  ferocity_yaw_gain: 25
  warp_gain: 20
  warp_yaw_gain: 15
  anchor_gain: 50
  resonance_gain: 10
ONDAS_KEYS = Object.keys ONDAS_DEFAULTS

encodeOndas = (ondas = {}) ->
  out = new Uint8Array ONDAS_KEYS.length
  for key, i in ONDAS_KEYS
    out[i] = clampU8 ondas[key] ? ONDAS_DEFAULTS[key]
  out

decodeOndas = (payload) ->
  reader = new ByteReader payload
  result = {}
  for key in ONDAS_KEYS
    result[key] = if reader.remaining() then reader.u8() else 0
  result

# ── Tuning fallbacks ────────────────────────────────────────
# OrniFlight firmware standards for sections the flight controller
# does not expose. Shared by session reads and the tuning store so
# defaults can never drift between the two.
TUNING_FALLBACKS = Object.freeze
  pid: Object.freeze
    roll: Object.freeze { P: 4.0, I: 0.03, D: 23.0 }
    pitch: Object.freeze { P: 6.0, I: 0.04, D: 28.0 }
    yaw: Object.freeze { P: 3.0, I: 0.05, D: 0.0 }
    flap: Object.freeze { P: 0.0, I: 0.0, D: 0.0 }
  rate: Object.freeze { rcRate: 100, superRate: 0, expo: 0 }
  filter: Object.freeze
    gyroDlpfHz: 0
    gyroNotchHz: 0
    gyroNotchQ: 0
    dTermDlpfHz: 0

export {
  decodeApiVersion, decodeVariant, decodeVersion, decodeBuildInfo
  decodeBoardInfo, decodeUid, decodeName, decodeStatus, decodeRawImu
  decodeAttitude, decodeChannels, decodeRxMap, decodeServos
  decodeAnalog, decodeBatteryState, encodeName
  decodeServoConfigurations, encodeServoConfiguration
  SERVO_CONFIG_BYTES, MAX_SERVO_CONFIGS, DEFAULT_SERVO_SWEEP
  encodePidTuning, decodePidTuning, PID_AXES, PID_TERMS
  encodeRcTuning, decodeRcTuning
  encodeFilterConfig, decodeFilterConfig
  encodeOndas, decodeOndas, ONDAS_DEFAULTS, ONDAS_KEYS
  TUNING_FALLBACKS
}