import ByteReader from './byteReader.coffee'
import {
  OSD_DEFAULTS, OSD_ITEM_COUNT, OSD_PROFILE_COUNT, sanitizePos
} from '../lib/osdCatalog.coffee'
import {
  vtxValueFor, VTX_DEFAULT_POWER
} from '../lib/vtxCatalog.coffee'
import { SERIAL_CONFIG_BYTES } from '../lib/serialCatalog.coffee'
import {
  DEFAULT_FAILSAFE_CONFIG, DEFAULT_ARMING_CONFIG
  DEFAULT_FEATURE_MASK, DEFAULT_BEEPER_CONFIG
} from '../lib/safetyCatalog.coffee'
import {
  DEFAULT_SENSOR_CONFIG, DEFAULT_SENSOR_ALIGNMENT
} from '../lib/sensorsCatalog.coffee'
import {
  DEFAULT_BATTERY_CONFIG, DEFAULT_VOLTAGE_METER_CONFIG
  DEFAULT_CURRENT_METER_CONFIG
} from '../lib/powerCatalog.coffee'
import {
  MAX_ADJUSTMENT_RANGE_COUNT
} from '../lib/adjustmentsCatalog.coffee'

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
  if Number.isNaN(number) then fallback else number

clampU16 = (value) ->
  Math.max 0, Math.min 65535, Math.round finiteOr 0, value

clampU8 = (value) ->
  Math.max 0, Math.min 255, Math.round finiteOr 0, value

clampU32 = (value) ->
  value = Math.trunc finiteOr 0, value
  value >>> 0

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

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

# ── VTX configuration (MSP 88 / 89) ─────────────────────────
# Wire layout of MSP_VTX_CONFIG (OrniFlight msp.c): u8 vtxType,
# u8 band, u8 channel, u8 power, u8 pitmode, u16 freq,
# u8 deviceIsReady, u8 lowPowerDisarm — 8 fixed bytes.
# SET_VTX_CONFIG carries [u16 value, u8 power, u8 pitmode,
# u8 lowPowerDisarm]: value ≤ 63 is (band-1)×8+(channel-1),
# 64..5999 is a custom frequency with band 0. The firmware only
# consumes pitmode and lowPowerDisarm when a VTX device answers.

decodeVtxConfig = (payload) ->
  reader = new ByteReader payload
  vtxType: if reader.remaining() then reader.u8() else 255
  band: if reader.remaining() then reader.u8() else 0
  channel: if reader.remaining() then reader.u8() else 0
  power: if reader.remaining() then reader.u8() else 1
  pitmode: if reader.remaining() then reader.u8() else 0
  freq: if reader.remaining() >= 2 then reader.u16() else 0
  deviceIsReady: if reader.remaining() then reader.u8() else 0
  lowPowerDisarm: if reader.remaining() then reader.u8() else 0

encodeVtxConfig = (config = {}) ->
  out = new Uint8Array 5
  view = new DataView out.buffer
  view.setUint16 0, vtxValueFor(config), true
  view.setUint8 2, clampU8 config.power ? VTX_DEFAULT_POWER
  view.setUint8 3, clampU8 config.pitmode ? 0
  view.setUint8 4, clampU8 config.lowPowerDisarm ? 0
  out

# ── Serial port configuration (MSP 54 / 55) ─────────────────
# Wire record (OrniFlight msp.c): u8 identifier, u16 functionMask,
# u8 msp_baudrateIndex, u8 gps_baudrateIndex,
# u8 telemetry_baudrateIndex, u8 blackbox_baudrateIndex — 7 bytes
# per port. MSP 54 streams one record per available port; 55
# accepts any payload whose length is a multiple of 7.

decodeSerialConfig = (payload) ->
  reader = new ByteReader payload
  ports = []
  while reader.remaining() >= SERIAL_CONFIG_BYTES
    ports.push {
      identifier: reader.u8()
      functionMask: reader.u16()
      mspBaud: reader.u8()
      gpsBaud: reader.u8()
      telemetryBaud: reader.u8()
      blackboxBaud: reader.u8()
    }
  ports

encodeSerialConfig = (port = {}) ->
  out = new Uint8Array SERIAL_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8(port.identifier ? 0)
  view.setUint16 1, clampU16(port.functionMask ? 0), true
  view.setUint8 3, clampU8(port.mspBaud ? 0)
  view.setUint8 4, clampU8(port.gpsBaud ? 0)
  view.setUint8 5, clampU8(port.telemetryBaud ? 0)
  view.setUint8 6, clampU8(port.blackboxBaud ? 0)
  out

# ── Safety configuration (MSP 61/62, 75/76, 36/37, 184/185) ──
# Four independent flat wire records; the firmware arbitrates none
# of them, so each codec stays a standalone document.

# MSP 75: u8 delay, u8 offDelay, u16 throttle, u8 switchMode,
# u16 throttleLowDelay, u8 procedure — 8 fixed bytes
# (failsafe.c failsafeConfig_t, all units × 0.1 s except the u16s).
FAILSAFE_CONFIG_BYTES = 8

decodeFailsafeConfig = (payload) ->
  reader = new ByteReader payload
  {
    delay: if reader.remaining() then reader.u8() else DEFAULT_FAILSAFE_CONFIG.delay
    offDelay: if reader.remaining() then reader.u8() else DEFAULT_FAILSAFE_CONFIG.offDelay
    throttle: if reader.remaining() >= 2 then reader.u16() else DEFAULT_FAILSAFE_CONFIG.throttle
    switchMode: if reader.remaining() then reader.u8() else DEFAULT_FAILSAFE_CONFIG.switchMode
    throttleLowDelay: if reader.remaining() >= 2 then reader.u16() else DEFAULT_FAILSAFE_CONFIG.throttleLowDelay
    procedure: if reader.remaining() then reader.u8() else DEFAULT_FAILSAFE_CONFIG.procedure
  }

encodeFailsafeConfig = (config = {}) ->
  out = new Uint8Array FAILSAFE_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8 config.delay ? DEFAULT_FAILSAFE_CONFIG.delay
  view.setUint8 1, clampU8 config.offDelay ? DEFAULT_FAILSAFE_CONFIG.offDelay
  view.setUint16 2, clampU16(config.throttle ? DEFAULT_FAILSAFE_CONFIG.throttle), true
  view.setUint8 4, clampU8 config.switchMode ? DEFAULT_FAILSAFE_CONFIG.switchMode
  view.setUint16 5, clampU16(config.throttleLowDelay ? DEFAULT_FAILSAFE_CONFIG.throttleLowDelay), true
  view.setUint8 7, clampU8 config.procedure ? DEFAULT_FAILSAFE_CONFIG.procedure
  out

# MSP 61: u8 autoDisarmDelay, u8 reserved (0), u8 smallAngle —
# 3 fixed bytes. MSP_SET_ARMING_CONFIG consumes smallAngle only
# when a third byte arrives, so writes always emit all three.
ARMING_CONFIG_BYTES = 3

decodeArmingConfig = (payload) ->
  reader = new ByteReader payload
  autoDisarmDelay = if reader.remaining() then reader.u8() else DEFAULT_ARMING_CONFIG.autoDisarmDelay
  # Byte 2 is reserved; smallAngle rides byte 3.
  reader.skip 1 if reader.remaining()
  smallAngle = if reader.remaining() then reader.u8() else DEFAULT_ARMING_CONFIG.smallAngle
  { autoDisarmDelay, smallAngle }

encodeArmingConfig = (config = {}) ->
  out = new Uint8Array ARMING_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8 config.autoDisarmDelay ? DEFAULT_ARMING_CONFIG.autoDisarmDelay
  view.setUint8 1, 0
  view.setUint8 2, clampU8 config.smallAngle ? DEFAULT_ARMING_CONFIG.smallAngle
  out

# MSP 36: u32 absolute feature mask (getFeatureMask). SET stages the
# value; EEPROM_WRITE materializes it (writeEEPROMWithFeatures).
FEATURE_CONFIG_BYTES = 4

decodeFeatureConfig = (payload) ->
  reader = new ByteReader payload
  if reader.remaining() >= FEATURE_CONFIG_BYTES then reader.u32() else DEFAULT_FEATURE_MASK

encodeFeatureConfig = (mask = DEFAULT_FEATURE_MASK) ->
  out = new Uint8Array FEATURE_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint32 0, clampU32(mask), true
  out

# MSP 184: u32 beeperOffFlags, u8 dshotBeaconTone,
# u32 dshotBeaconOffFlags — 9 fixed bytes. SET accepts 4/5/9-byte
# payloads (trailing fields optional); writes emit the full 9.
BEEPER_CONFIG_BYTES = 9

decodeBeeperConfig = (payload) ->
  reader = new ByteReader payload
  {
    offFlags: if reader.remaining() >= 4 then reader.u32() else DEFAULT_BEEPER_CONFIG.offFlags
    dshotBeaconTone: if reader.remaining() then reader.u8() else DEFAULT_BEEPER_CONFIG.dshotBeaconTone
    dshotBeaconOffFlags: if reader.remaining() >= 4 then reader.u32() else DEFAULT_BEEPER_CONFIG.dshotBeaconOffFlags
  }

encodeBeeperConfig = (config = {}) ->
  out = new Uint8Array BEEPER_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint32 0, clampU32(config.offFlags ? DEFAULT_BEEPER_CONFIG.offFlags), true
  view.setUint8 4, clampU8 config.dshotBeaconTone ? DEFAULT_BEEPER_CONFIG.dshotBeaconTone
  view.setUint32 5, clampU32(config.dshotBeaconOffFlags ? DEFAULT_BEEPER_CONFIG.dshotBeaconOffFlags), true
  out

# ── Receiver & modes (MSP 44/45, 64/65, 77/78, 34/35, 116/119, 238) ─
# Wire layouts follow the OrniFlight/Betaflight msp.c serialisation.
MAX_SUPPORTED_RC_CHANNEL_COUNT = 18
RX_MAPPABLE_CHANNEL_COUNT = 8
MAX_MODE_ACTIVATION_CONDITION_COUNT = 20
RXFAIL_MODE = Object.freeze { AUTO: 0, HOLD: 1, SET: 2, INVALID: 3 }
RXFAIL_VALUE_MIN = 750
RXFAIL_STEP = 25
RXFAIL_STEP_MAX = 60
MODE_RANGE_USEC_MIN = 900
MODE_RANGE_USEC_MAX = 2100
MODE_RANGE_STEP_MAX = 48
# rcmap[logicalInput] = letter index of the assigned physical channel;
# the letter table doubles as the physical index (A=0 … h=17).
RC_CHANNEL_LETTERS = 'AERT12345678abcdefgh'
SERIALRX_PROVIDERS = Object.freeze [
  Object.freeze { id: 9, name: 'CRSF', label: 'CRSF — ELRS / TBS Crossfire' }
  Object.freeze { id: 2, name: 'SBUS', label: 'SBUS (FrSky / Futaba)' }
  Object.freeze { id: 7, name: 'IBUS', label: 'iBUS (FlySky)' }
  Object.freeze { id: 12, name: 'FPORT', label: 'F.Port (FrSky)' }
  Object.freeze { id: 3, name: 'SUMD', label: 'SUMD (Graupner)' }
  Object.freeze { id: 4, name: 'SUMH', label: 'SUMH (Graupner)' }
  Object.freeze { id: 8, name: 'JETIEXBUS', label: 'JETI EXBus' }
  Object.freeze { id: 10, name: 'SRXL2', label: 'SRXL2 (Spektrum)' }
  Object.freeze { id: 0, name: 'SPEKTRUM1024', label: 'Spektrum 1024' }
  Object.freeze { id: 1, name: 'SPEKTRUM2048', label: 'Spektrum 2048' }
  Object.freeze { id: 5, name: 'XBUS_MODE_B', label: 'XBUS Mode B' }
  Object.freeze { id: 6, name: 'XBUS_MODE_B_RJ01', label: 'XBUS Mode B (RJ01)' }
  Object.freeze { id: 11, name: 'CUSTOM', label: 'Custom provider' }
]

# MSP 44: u8 provider, u16 maxcheck/midrc/mincheck, u8 bind, u16
# rx_min_usec/rx_max_usec, u8 rcInterpolation + interval, u16
# airModeActivateThreshold (wire = value × 10 + 1000). Remaining
# guards tolerate a trailing SPI tail.
RX_CONFIG_BYTES = 16

decodeRxConfig = (payload) ->
  reader = new ByteReader payload
  provider = reader.u8()
  maxcheck = reader.u16()
  midrc = reader.u16()
  mincheck = reader.u16()
  spektrumSatBind = reader.u8()
  rxMinUsec = if reader.remaining() >= 2 then reader.u16() else 885
  rxMaxUsec = if reader.remaining() >= 2 then reader.u16() else 2115
  rcInterpolation = if reader.remaining() >= 1 then reader.u8() else 0
  rcInterpolationInterval = if reader.remaining() >= 1 then reader.u8() else 0
  airModeRaw = if reader.remaining() >= 2 then reader.u16() else 1000
  {
    provider, maxcheck, midrc, mincheck, spektrumSatBind
    rxMinUsec, rxMaxUsec, rcInterpolation, rcInterpolationInterval
    airModeActivateThreshold: (airModeRaw - 1000) / 10
  }

encodeRxConfig = (config = {}) ->
  out = new Uint8Array RX_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8 config.provider ? 9
  view.setUint16 1, config.maxcheck ? 1900, true
  view.setUint16 3, config.midrc ? 1500, true
  view.setUint16 5, config.mincheck ? 1050, true
  view.setUint8 7, clampU8 config.spektrumSatBind ? 0
  view.setUint16 8, config.rxMinUsec ? 885, true
  view.setUint16 10, config.rxMaxUsec ? 2115, true
  view.setUint8 12, clampU8 config.rcInterpolation ? 0
  view.setUint8 13, clampU8 config.rcInterpolationInterval ? 0
  threshold = Math.round((config.airModeActivateThreshold ? 0) * 10) + 1000
  view.setUint16 14, clampU16(threshold), true
  out

# MSP 64: rcmap carries the letter index per logical input; the display
# map is its inversion as letters — default wire [0,1,3,2,4,5,6,7]
# reads back as 'AETR1234'.
channelMapFromRxMap = (rxMap) ->
  letters = []
  for position in [0...RX_MAPPABLE_CHANNEL_COUNT]
    index = rxMap[position]
    index = position unless Number.isInteger(index) and index >= 0
    letters.push RC_CHANNEL_LETTERS[index] ? RC_CHANNEL_LETTERS[position]
  letters.join ''

rxMapFromChannelMap = (letters) ->
  text = String(letters ? '')
  out = new Uint8Array RX_MAPPABLE_CHANNEL_COUNT
  for position in [0...RX_MAPPABLE_CHANNEL_COUNT]
    index = RC_CHANNEL_LETTERS.indexOf text[position]
    index = position unless index >= 0
    out[position] = index
  out

# MSP 77: dynamic-length channel stream — {mode u8, value u16} per
# channel; the firmware emits only its runtime channelCount slots.
decodeRxFailConfig = (payload) ->
  reader = new ByteReader payload
  channels = []
  while reader.remaining() >= 3
    channels.push {
      index: channels.length
      mode: reader.u8()
      value: reader.u16()
    }
  channels

encodeRxFailChannel = (index, channel = {}) ->
  out = new Uint8Array 4
  view = new DataView out.buffer
  view.setUint8 0, clampU8 index
  view.setUint8 1, clampU8 channel.mode ? RXFAIL_MODE.AUTO
  view.setUint16 2, clampU16(channel.value ? 1500), true
  out

# Failsafe pulse domain: 750 µs + step × 25 µs (step 0..60).
rxFailStepToValue = (step) ->
  RXFAIL_VALUE_MIN + RXFAIL_STEP * clampInt 0, RXFAIL_STEP_MAX, step

rxFailValueToStep = (value) ->
  step = Math.round (value - RXFAIL_VALUE_MIN) / RXFAIL_STEP
  clampInt 0, RXFAIL_STEP_MAX, step

# MSP 34: 20 fixed 4-byte slots {permId, aux, startStep, endStep}.
decodeModeRanges = (payload) ->
  reader = new ByteReader payload
  ranges = []
  while ranges.length < MAX_MODE_ACTIVATION_CONDITION_COUNT and
      reader.remaining() >= 4
    ranges.push {
      index: ranges.length
      permanentId: reader.u8()
      auxChannelIndex: reader.u8()
      startStep: reader.u8()
      endStep: reader.u8()
    }
  ranges

# MSP 238: u8 count then count×3 bytes {permId, modeLogic, linkedTo}
# aligned to the slot index they describe.
decodeModeRangesExtra = (payload) ->
  reader = new ByteReader payload
  return null unless reader.remaining() >= 1
  count = reader.u8()
  extras = []
  while extras.length < count and reader.remaining() >= 3
    extras.push {
      index: extras.length
      permanentId: reader.u8()
      modeLogic: reader.u8()
      linkedToPermId: reader.u8()
    }
  extras

encodeModeRange = (index, range = {}) ->
  out = new Uint8Array 7
  out[0] = clampU8 index
  out[1] = clampU8 range.permanentId ? 0
  out[2] = clampU8 range.auxChannelIndex ? 0
  out[3] = clampU8 range.startStep ? 0
  out[4] = clampU8 range.endStep ? 0
  out[5] = clampU8 range.modeLogic ? 0
  out[6] = clampU8 range.linkedToPermId ? 0
  out

decodeBoxIds = (payload) -> Array.from payload

# MSP 116: u8 count then ';'-separated box names.
decodeBoxNames = (payload) ->
  reader = new ByteReader payload
  count = if reader.remaining() then reader.u8() else 0
  names = reader.ascii(reader.remaining()).split(';')
    .map((name) -> name.trim())
    .filter((name) -> name.length > 0)
  names = names[0...count] if count > 0 and count < names.length
  names

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

# ── Sensors, power & adjustments (MSP 32/33, 40/41, 52/53, 56/57,
#    96/97, 126/220, 205/206) ─
# Wire layouts follow the OrniFlight/Betaflight msp.c serialisation.

# MSP 96: u8 acc_hardware, u8 baro_hardware, u8 mag_hardware — 3 bytes.
SENSOR_CONFIG_BYTES = 3

decodeSensorConfig = (payload) ->
  reader = new ByteReader payload
  {
    accHardware: if reader.remaining()
      reader.u8()
    else
      DEFAULT_SENSOR_CONFIG.accHardware
    baroHardware: if reader.remaining()
      reader.u8()
    else
      DEFAULT_SENSOR_CONFIG.baroHardware
    magHardware: if reader.remaining()
      reader.u8()
    else
      DEFAULT_SENSOR_CONFIG.magHardware
  }

encodeSensorConfig = (config = {}) ->
  out = new Uint8Array SENSOR_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0,
    clampU8 config.accHardware ? DEFAULT_SENSOR_CONFIG.accHardware
  view.setUint8 1,
    clampU8 config.baroHardware ? DEFAULT_SENSOR_CONFIG.baroHardware
  view.setUint8 2,
    clampU8 config.magHardware ? DEFAULT_SENSOR_CONFIG.magHardware
  out

# MSP 126: 7-byte read {gyroAlign, accAlign, magAlign,
# gyroDetectionFlags, gyroToUse, gyro1Align, gyro2Align}. The SET
# counterpart accepts 6 bytes — the deprecated acc byte is discarded
# and the read-only detection flags never travel back.
SENSOR_ALIGNMENT_BYTES = 6

decodeSensorAlignment = (payload) ->
  reader = new ByteReader payload
  # The 7-byte read record carries the full set; the 6-byte SET record
  # skips the deprecated acc byte and the read-only detection flags.
  seven = reader.remaining() >= 7
  gyroAlign = if reader.remaining()
    reader.u8()
  else
    DEFAULT_SENSOR_ALIGNMENT.gyroAlign
  accAlign = if reader.remaining() and seven
    reader.u8()
  else if reader.remaining()
    reader.u8() # deprecated acc byte — discarded on the wire
    DEFAULT_SENSOR_ALIGNMENT.accAlign
  else
    DEFAULT_SENSOR_ALIGNMENT.accAlign
  magAlign = if reader.remaining()
    reader.u8()
  else
    DEFAULT_SENSOR_ALIGNMENT.magAlign
  gyroDetectionFlags = if seven
    reader.u8()
  else
    DEFAULT_SENSOR_ALIGNMENT.gyroDetectionFlags
  gyroToUse = if reader.remaining()
    reader.u8()
  else
    DEFAULT_SENSOR_ALIGNMENT.gyroToUse
  gyro1Align = if reader.remaining()
    reader.u8()
  else
    DEFAULT_SENSOR_ALIGNMENT.gyro1Align
  gyro2Align = if reader.remaining()
    reader.u8()
  else
    DEFAULT_SENSOR_ALIGNMENT.gyro2Align
  { gyroAlign, accAlign, magAlign, gyroDetectionFlags, gyroToUse, gyro1Align, gyro2Align }

encodeSensorAlignment = (alignment = {}) ->
  out = new Uint8Array SENSOR_ALIGNMENT_BYTES
  view = new DataView out.buffer
  view.setUint8 0,
    clampU8 alignment.gyroAlign ? DEFAULT_SENSOR_ALIGNMENT.gyroAlign
  view.setUint8 1, 0
  view.setUint8 2,
    clampU8 alignment.magAlign ? DEFAULT_SENSOR_ALIGNMENT.magAlign
  view.setUint8 3,
    clampU8 alignment.gyroToUse ? DEFAULT_SENSOR_ALIGNMENT.gyroToUse
  view.setUint8 4,
    clampU8 alignment.gyro1Align ? DEFAULT_SENSOR_ALIGNMENT.gyro1Align
  view.setUint8 5,
    clampU8 alignment.gyro2Align ? DEFAULT_SENSOR_ALIGNMENT.gyro2Align
  out

# MSP 32: legacy u8 trio ((value + 5) / 10), u16 capacity, u8 voltSrc,
# u8 currSrc, then three full-precision u16 cell voltages — 13 bytes.
BATTERY_CONFIG_BYTES = 13

decodeBatteryConfig = (payload) ->
  reader = new ByteReader payload
  legacyMin = if reader.remaining() then reader.u8() else null
  legacyMax = if reader.remaining() then reader.u8() else null
  legacyWarning = if reader.remaining() then reader.u8() else null
  capacityMah = if reader.remaining() >= 2
    reader.u16()
  else
    DEFAULT_BATTERY_CONFIG.capacityMah
  voltageMeterSource = if reader.remaining()
    reader.u8()
  else
    DEFAULT_BATTERY_CONFIG.voltageMeterSource
  currentMeterSource = if reader.remaining()
    reader.u8()
  else
    DEFAULT_BATTERY_CONFIG.currentMeterSource
  minCellVoltage = if reader.remaining() >= 2 then reader.u16() else legacyMin * 10
  maxCellVoltage = if reader.remaining() >= 2 then reader.u16() else legacyMax * 10
  warningCellVoltage = if reader.remaining() >= 2
    reader.u16()
  else
    legacyWarning * 10
  {
    minCellVoltage, maxCellVoltage, warningCellVoltage, capacityMah
    voltageMeterSource, currentMeterSource
  }

encodeBatteryConfig = (config = {}) ->
  out = new Uint8Array BATTERY_CONFIG_BYTES
  view = new DataView out.buffer
  minCell = clampU16 config.minCellVoltage ? DEFAULT_BATTERY_CONFIG.minCellVoltage
  maxCell = clampU16 config.maxCellVoltage ? DEFAULT_BATTERY_CONFIG.maxCellVoltage
  warnCell = clampU16 config.warningCellVoltage ?
    DEFAULT_BATTERY_CONFIG.warningCellVoltage
  view.setUint8 0, Math.floor((minCell + 5) / 10)
  view.setUint8 1, Math.floor((maxCell + 5) / 10)
  view.setUint8 2, Math.floor((warnCell + 5) / 10)
  view.setUint16 3,
    clampU16(config.capacityMah ? DEFAULT_BATTERY_CONFIG.capacityMah), true
  view.setUint8 5,
    clampU8 config.voltageMeterSource ? DEFAULT_BATTERY_CONFIG.voltageMeterSource
  view.setUint8 6,
    clampU8 config.currentMeterSource ? DEFAULT_BATTERY_CONFIG.currentMeterSource
  view.setUint16 7, minCell, true
  view.setUint16 9, maxCell, true
  view.setUint16 11, warnCell, true
  out

# MSP 56: variable frame — u8 count, then per meter {u8 subLen, u8 id,
# u8 type, u8 scale, u8 divVal, u8 divMultiplier}. OrniFlight emits one
# VBAT ADC frame (7 bytes). SET accepts the bare 4-byte record.
VOLTAGE_METER_CONFIG_BYTES = 4

decodeVoltageMeterConfig = (payload) ->
  reader = new ByteReader payload
  count = if reader.remaining() then reader.u8() else 0
  meters = []
  while meters.length < count and reader.remaining() >= 5
    reader.u8() if reader.remaining() >= 6
    meters.push {
      id: reader.u8()
      type: reader.u8()
      scale: reader.u8()
      dividerValue: reader.u8()
      dividerMultiplier: reader.u8()
    }
  meters[0] ? DEFAULT_VOLTAGE_METER_CONFIG

encodeVoltageMeterConfig = (config = {}) ->
  out = new Uint8Array VOLTAGE_METER_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8 config.id ? DEFAULT_VOLTAGE_METER_CONFIG.id
  view.setUint8 1, clampU8 config.scale ? DEFAULT_VOLTAGE_METER_CONFIG.scale
  view.setUint8 2,
    clampU8 config.dividerValue ? DEFAULT_VOLTAGE_METER_CONFIG.dividerValue
  view.setUint8 3,
    clampU8 config.dividerMultiplier ?
      DEFAULT_VOLTAGE_METER_CONFIG.dividerMultiplier
  out

# MSP 40: variable frame — u8 count, then per meter {u8 subLen, u8 id,
# u8 type, u16 scale, u16 offset}. OrniFlight emits one onboard ADC
# frame (7 bytes). SET accepts the bare 5-byte record.
CURRENT_METER_CONFIG_BYTES = 5

decodeCurrentMeterConfig = (payload) ->
  reader = new ByteReader payload
  count = if reader.remaining() then reader.u8() else 0
  meters = []
  while meters.length < count and reader.remaining() >= 5
    reader.u8() if reader.remaining() >= 6
    meters.push {
      id: reader.u8()
      type: reader.u8()
      scale: reader.u16()
      offset: reader.u16()
    }
  meters[0] ? DEFAULT_CURRENT_METER_CONFIG

encodeCurrentMeterConfig = (config = {}) ->
  out = new Uint8Array CURRENT_METER_CONFIG_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8 config.id ? DEFAULT_CURRENT_METER_CONFIG.id
  view.setUint16 1,
    clampU16(config.scale ? DEFAULT_CURRENT_METER_CONFIG.scale), true
  view.setUint16 3,
    clampU16(config.offset ? DEFAULT_CURRENT_METER_CONFIG.offset), true
  out

# MSP 52: 30 fixed 6-byte slots {slot, aux, startStep, endStep,
# adjustmentConfig, auxSwitch}; SET_ADJUSTMENT_RANGE consumes a 7-byte
# record {slotIndex, …same fields}. The function lives in
# adjustmentConfig (table index + 1, 0 = none).
ADJUSTMENT_RANGE_BYTES = 6
ADJUSTMENT_RANGE_WRITE_BYTES = 7

decodeAdjustmentRanges = (payload) ->
  reader = new ByteReader payload
  ranges = []
  while ranges.length < MAX_ADJUSTMENT_RANGE_COUNT and
      reader.remaining() >= ADJUSTMENT_RANGE_BYTES
    ranges.push {
      index: ranges.length
      adjustmentIndex: reader.u8()
      auxChannelIndex: reader.u8()
      startStep: reader.u8()
      endStep: reader.u8()
      adjustmentConfig: reader.u8()
      auxSwitchChannelIndex: reader.u8()
    }
  ranges

encodeAdjustmentRange = (index, range = {}) ->
  out = new Uint8Array ADJUSTMENT_RANGE_WRITE_BYTES
  view = new DataView out.buffer
  view.setUint8 0, clampU8 index
  view.setUint8 1, clampU8 range.adjustmentIndex ? 0
  view.setUint8 2, clampU8 range.auxChannelIndex ? 0
  view.setUint8 3, clampU8 range.startStep ? 0
  view.setUint8 4, clampU8 range.endStep ? 0
  view.setUint8 5, clampU8 range.adjustmentConfig ? 0
  view.setUint8 6, clampU8 range.auxSwitchChannelIndex ? 0
  out

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
  decodeVtxConfig, encodeVtxConfig
  decodeSerialConfig, encodeSerialConfig
  decodeFailsafeConfig, encodeFailsafeConfig, FAILSAFE_CONFIG_BYTES
  decodeArmingConfig, encodeArmingConfig, ARMING_CONFIG_BYTES
  decodeFeatureConfig, encodeFeatureConfig, FEATURE_CONFIG_BYTES
  decodeBeeperConfig, encodeBeeperConfig, BEEPER_CONFIG_BYTES
  decodeRxConfig, encodeRxConfig, RX_CONFIG_BYTES
  channelMapFromRxMap, rxMapFromChannelMap
  MAX_SUPPORTED_RC_CHANNEL_COUNT, RX_MAPPABLE_CHANNEL_COUNT
  RC_CHANNEL_LETTERS, SERIALRX_PROVIDERS
  decodeRxFailConfig, encodeRxFailChannel
  RXFAIL_MODE, RXFAIL_VALUE_MIN, RXFAIL_STEP, RXFAIL_STEP_MAX
  rxFailStepToValue, rxFailValueToStep
  decodeModeRanges, decodeModeRangesExtra, encodeModeRange
  MAX_MODE_ACTIVATION_CONDITION_COUNT
  MODE_RANGE_USEC_MIN, MODE_RANGE_USEC_MAX, MODE_RANGE_STEP_MAX
  decodeBoxIds, decodeBoxNames
  TUNING_FALLBACKS
  decodeSensorConfig, encodeSensorConfig, SENSOR_CONFIG_BYTES
  decodeSensorAlignment, encodeSensorAlignment, SENSOR_ALIGNMENT_BYTES
  decodeBatteryConfig, encodeBatteryConfig, BATTERY_CONFIG_BYTES
  decodeVoltageMeterConfig, encodeVoltageMeterConfig
  VOLTAGE_METER_CONFIG_BYTES
  decodeCurrentMeterConfig, encodeCurrentMeterConfig
  CURRENT_METER_CONFIG_BYTES
  decodeAdjustmentRanges, encodeAdjustmentRange
  ADJUSTMENT_RANGE_BYTES, ADJUSTMENT_RANGE_WRITE_BYTES
  MAX_ADJUSTMENT_RANGE_COUNT
}