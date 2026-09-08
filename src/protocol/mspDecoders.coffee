import ByteReader from './byteReader.coffee'
import {
  OSD_DEFAULTS, OSD_ITEM_COUNT, OSD_PROFILE_COUNT, sanitizePos
} from '../lib/osdCatalog.coffee'

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
# Wire layout per servoParam_t (OrniFlight msp.c): u16 min,
# u16 max, u16 middle, i8 rate, u8 forwardFromChannel, u32
# reversedSources (little-endian). MSP 120 streams 8 records and
# appends a 4-byte ornithopter trailer (glide + ONDAS v1 triplet,
# signed on the wire as value + 128); 212 prefixes the servo
# index and accepts either the 12-byte record or a ≤4-byte glide
# payload — the firmware's MSP 244 stub writes nothing.
SERVO_CONFIG_BYTES = 12
MAX_SERVO_CONFIGS = 8

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
      forwardFromChannel: reader.u8()
      reversedSources: reader.u32()
    }
  configs

# MSP 120 trailer (after the 8×12-byte records): glide_angle plus
# the ONDAS v1 triplet — signed bytes with a +128 wire offset.
decodeServoTuning = (payload) ->
  reader = new ByteReader payload
  reader.skip MAX_SERVO_CONFIGS * SERVO_CONFIG_BYTES
  glide: if reader.remaining() then reader.u8() - 128 else 0
  cadence: if reader.remaining() then reader.u8() - 128 else 0
  ferocityD: if reader.remaining() then reader.u8() - 128 else 0
  balance: if reader.remaining() then reader.u8() - 128 else 0

encodeServoConfiguration = (index, config = {}) ->
  index = Math.max 0, Math.min(MAX_SERVO_CONFIGS - 1, Number(index) or 0)
  out = new Uint8Array SERVO_CONFIG_BYTES + 1
  view = new DataView out.buffer
  view.setUint8 0, index
  view.setUint16 1, config.min ? 1000, true
  view.setUint16 3, config.max ? 2000, true
  view.setUint16 5, config.middle ? 1500, true
  view.setInt8 7, config.rate ? 100
  view.setUint8 8, config.forwardFromChannel ? index
  view.setUint32 9, config.reversedSources ? 0, true
  out

# Glide payload for MSP 212: 1 byte = glide-only, 4 bytes = glide
# + ONDAS v1 triplet (cadence, ferocity_d, balance).
encodeServoGlide = (glide = 0, triplet = null) ->
  bytes = [clampU8(glide + 128)]
  if triplet?
    bytes.push clampU8(triplet.cadence + 128)
    bytes.push clampU8(triplet.ferocityD + 128)
    bytes.push clampU8(triplet.balance + 128)
  Uint8Array.from bytes

# ── Servo mix rules (MSP 241 / 242) ──────────────────────────
# Wire layout per servoMixer_t: u8 targetChannel, u8 inputSource,
# i8 rate, u8 speed, i8 min, i8 max, u8 box. MSP 241 streams 16
# records; 242 prefixes the rule index.
SERVO_MIX_RULE_BYTES = 7
MAX_SERVO_MIX_RULES = 16

decodeServoMixRules = (payload) ->
  reader = new ByteReader payload
  rules = []
  while reader.remaining() >= SERVO_MIX_RULE_BYTES and
      rules.length < MAX_SERVO_MIX_RULES
    rules.push {
      index: rules.length
      targetChannel: reader.u8()
      inputSource: reader.u8()
      rate: reader.i8()
      speed: reader.u8()
      min: reader.i8()
      max: reader.i8()
      box: reader.u8()
    }
  rules

encodeServoMixRule = (index, rule = {}) ->
  index = Math.max 0, Math.min(MAX_SERVO_MIX_RULES - 1, Number(index) or 0)
  out = new Uint8Array SERVO_MIX_RULE_BYTES + 1
  view = new DataView out.buffer
  view.setUint8 0, index
  view.setUint8 1, rule.targetChannel ? 0
  view.setUint8 2, rule.inputSource ? 0
  view.setInt8 3, rule.rate ? 0
  view.setUint8 4, rule.speed ? 0
  view.setInt8 5, rule.min ? 0
  view.setInt8 6, rule.max ? 100
  view.setUint8 7, rule.box ? 0
  out

# ── PID advanced envelope (MSP 94 / 95) ──────────────────────
# OrniFlight appends wing-mapping fields after the standard
# Betaflight prefix of 46 bytes. The prefix is opaque here — it is
# carried raw so read-modify-write round-trips are byte-exact.
# Appendix offsets (0-based within the envelope):
# 46 flap_base_frequency (removed — always 0)
# 47 flap_base_amplitude (s8, wire = value + 128)
# 48 iterm_relax_cutoff (u8)
# 49–51 cadence / ferocity_d / balance (s8, wire = value + 128)
# 52–54 ferocity_p / roll / yaw (u8, 0–100)
# 55 warp_gain, 56 warp_yaw_gain (s8, wire = value + 128)
# 57 anchor_gain, 58 resonance_gain (u8)
# 59–62 servo_mount_angle ×4 (s8, wire = value + 128)
# 63–66 flapping_phase_shift ×4 (s8, wire = value + 128)
# 67–70 prescience / espelho / saudade / ssff (u8)
# 71–72 servo_travel_time_ms (u16)
# 73 servo_max_amplitude, 74 flap_magnitude (u8)
# 75–78 wing_origin_offset ×4 (s8, wire = value + 128)
# 79–81 ornithopter_freq channel/min/max (u8)
# 82 ornithopter profile index (u8)
# 83+ per-profile aeroelastic tail — carried raw.
PID_ADVANCED_APPENDIX_OFFSET = 46
ORNITHOPTER_PAIR_COUNT = 4

readS8Array = (reader, count) ->
  [0...count].map (->
    if reader.remaining() then reader.u8() - 128 else 0)

decodePidAdvanced = (payload) ->
  reader = new ByteReader payload
  prefix = Array.from reader.take(
    Math.min PID_ADVANCED_APPENDIX_OFFSET, payload.length
  )
  return { prefix, appendix: null, tail: [] } unless reader.remaining()
  reader.u8() # 46 — flap_base_frequency (removed)
  appendix =
    flapBaseAmplitude: if reader.remaining() then reader.u8() - 128 else 0
    itermRelaxCutoff: if reader.remaining() then reader.u8() else 0
    cadence: if reader.remaining() then reader.u8() - 128 else 0
    ferocityD: if reader.remaining() then reader.u8() - 128 else 0
    balance: if reader.remaining() then reader.u8() - 128 else 0
    ferocityP: if reader.remaining() then reader.u8() else 0
    ferocityRoll: if reader.remaining() then reader.u8() else 0
    ferocityYaw: if reader.remaining() then reader.u8() else 0
    warpGain: if reader.remaining() then reader.u8() - 128 else 0
    warpYawGain: if reader.remaining() then reader.u8() - 128 else 0
    anchorGain: if reader.remaining() then reader.u8() else 0
    resonanceGain: if reader.remaining() then reader.u8() else 0
    servoMountAngle: readS8Array reader, ORNITHOPTER_PAIR_COUNT
    flappingPhaseShift: readS8Array reader, ORNITHOPTER_PAIR_COUNT
    prescience: if reader.remaining() then reader.u8() else 0
    espelho: if reader.remaining() then reader.u8() else 0
    saudade: if reader.remaining() then reader.u8() else 0
    ssff: if reader.remaining() then reader.u8() else 0
    servoTravelTimeMs: if reader.remaining() >= 2 then reader.u16() else 0
    servoMaxAmplitude: if reader.remaining() then reader.u8() else 0
    flapMagnitude: if reader.remaining() then reader.u8() else 0
    wingOriginOffset: readS8Array reader, ORNITHOPTER_PAIR_COUNT
    freqChannel: if reader.remaining() then reader.u8() else 0
    freqMin: if reader.remaining() then reader.u8() else 0
    freqMax: if reader.remaining() then reader.u8() else 0
    profileIndex: if reader.remaining() then reader.u8() else 0
  tail = Array.from reader.take(reader.remaining())
  { prefix, appendix, tail }

encodePidAdvancedAppendix = (appendix = {}) ->
  signed = (value) -> clampU8(value + 128)
  bytes = [
    0 # 46 — flap_base_frequency (removed)
    signed appendix.flapBaseAmplitude
    clampU8 appendix.itermRelaxCutoff
    signed appendix.cadence
    signed appendix.ferocityD
    signed appendix.balance
    clampU8 appendix.ferocityP
    clampU8 appendix.ferocityRoll
    clampU8 appendix.ferocityYaw
    signed appendix.warpGain
    signed appendix.warpYawGain
    clampU8 appendix.anchorGain
    clampU8 appendix.resonanceGain
  ]
  for i in [0...ORNITHOPTER_PAIR_COUNT]
    bytes.push signed (appendix.servoMountAngle?[i] ? 0)
  for i in [0...ORNITHOPTER_PAIR_COUNT]
    bytes.push signed (appendix.flappingPhaseShift?[i] ? 0)
  bytes.push clampU8(appendix.prescience), clampU8(appendix.espelho)
  bytes.push clampU8(appendix.saudade), clampU8(appendix.ssff)
  travel = clampU16 appendix.servoTravelTimeMs
  bytes.push travel & 0xff, (travel >> 8) & 0xff
  bytes.push clampU8(appendix.servoMaxAmplitude)
  bytes.push clampU8(appendix.flapMagnitude)
  for i in [0...ORNITHOPTER_PAIR_COUNT]
    bytes.push signed (appendix.wingOriginOffset?[i] ? 0)
  bytes.push clampU8(appendix.freqChannel), clampU8(appendix.freqMin)
  bytes.push clampU8(appendix.freqMax), clampU8(appendix.profileIndex)
  Uint8Array.from bytes

encodePidAdvanced = (envelope = {}) ->
  prefix = Array.from envelope.prefix ? []
  while prefix.length < PID_ADVANCED_APPENDIX_OFFSET
    prefix.push 0
  prefix = prefix[0...PID_ADVANCED_APPENDIX_OFFSET]
  tail = Array.from envelope.tail ? []
  body = if envelope.appendix?
    encodePidAdvancedAppendix envelope.appendix
  else
    new Uint8Array 0
  out = new Uint8Array prefix.length + body.length + tail.length
  out.set prefix, 0
  out.set body, prefix.length
  out.set tail, prefix.length + body.length
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
# ── OSD configuration (MSP 84 / 85) ─────────────────────────────────
# Wire layout of MSP_OSD_CONFIG (OrniFlight msp.c): u8 osdFlags,
# u8 videoSystem, u8 units, u8 rssiAlarm, u16 capAlarm, u8 reserved,
# u8 itemCount, u16 altAlarm, then itemCount × u16 item positions,
# then an adaptive trailer: stats, timers, warnings, profileCount,
# profileIndex (1-based), overlayRadioMode.
# MSP_SET_OSD_CONFIG carries one element per request as
# [u8 index, u16 position, u8 screen] with screen 1 = in-flight screen.

# Full document of firmware defaults for a truncated/empty frame — the
# codec degrades instead of throwing so a short MSP payload can never
# crash the editor's read path.
osdConfigDefaults = ->
  {
    osdFlags: 0, videoSystem: 0, units: 0, rssiAlarm: 0
    capAlarm: 0, altAlarm: 0
    profileCount: OSD_PROFILE_COUNT, profileIndex: 1, overlayRadioMode: 0
    items: (OSD_DEFAULTS[i] for i in [0...OSD_ITEM_COUNT])
  }

decodeOsdConfig = (payload) ->
  reader = new ByteReader payload
  return osdConfigDefaults() unless reader.remaining() >= 10
  osdFlags = reader.u8()
  videoSystem = reader.u8()
  units = reader.u8()
  rssiAlarm = reader.u8()
  capAlarm = reader.u16()
  reader.u8() # reserved (legacy timer alarm low byte)
  itemCount = reader.u8()
  altAlarm = reader.u16()
  itemCount = Math.min itemCount, OSD_ITEM_COUNT
  items = []
  while items.length < itemCount and reader.remaining() >= 2
    items.push sanitizePos reader.u16()
  statCount = if reader.remaining() >= 1 then reader.u8() else 0
  reader.take Math.min(statCount, reader.remaining())
  timerCount = if reader.remaining() >= 1 then reader.u8() else 0
  reader.take Math.min(timerCount * 2, reader.remaining())
  warningsLow = if reader.remaining() >= 2 then reader.u16() else 0
  warningCount = if reader.remaining() >= 1 then reader.u8() else 0
  warningsFull = if reader.remaining() >= 4 then reader.u32() else warningsLow
  profileCount = if reader.remaining() >= 1 then reader.u8() else OSD_PROFILE_COUNT
  profileIndex = if reader.remaining() >= 1 then reader.u8() else 1
  overlayRadioMode = if reader.remaining() >= 1 then reader.u8() else 0
  for i in [items.length...OSD_ITEM_COUNT]
    items.push OSD_DEFAULTS[i]
  {
    osdFlags, videoSystem, units, rssiAlarm, capAlarm, altAlarm
    profileCount, profileIndex, overlayRadioMode, items
  }

encodeOsdItem = (index, position) ->
  payload = new Uint8Array 4
  payload[0] = index & 0xFF
  payload[1] = position & 0xFF
  payload[2] = (position >> 8) & 0xFF
  payload[3] = 1 # screen 1 = in-flight OSD screen
  payload

# ⚙️ Tuning fallbacks — OrniFlight firmware standards for sections the
# flight controller does not expose. Shared by session reads and the
# tuning store so defaults can never drift between the two.
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
  SERVO_CONFIG_BYTES, MAX_SERVO_CONFIGS
  decodeServoTuning, encodeServoGlide
  decodeServoMixRules, encodeServoMixRule
  SERVO_MIX_RULE_BYTES, MAX_SERVO_MIX_RULES
  decodePidAdvanced, encodePidAdvanced
  PID_ADVANCED_APPENDIX_OFFSET, ORNITHOPTER_PAIR_COUNT
  encodePidTuning, decodePidTuning, PID_AXES, PID_TERMS
  encodeRcTuning, decodeRcTuning
  encodeFilterConfig, decodeFilterConfig
  encodeOndas, decodeOndas, ONDAS_DEFAULTS, ONDAS_KEYS
  decodeOsdConfig, encodeOsdItem
  TUNING_FALLBACKS
}