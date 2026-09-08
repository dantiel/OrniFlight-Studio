import { describe, it, expect } from 'vitest'
import {
  decodeApiVersion, decodeVariant, decodeVersion, decodeBuildInfo
  decodeBoardInfo, decodeUid, decodeName, decodeStatus, decodeRawImu
  decodeAttitude, decodeChannels, decodeRxMap, decodeServos
  decodeAnalog, decodeBatteryState, encodeName
  decodeServoConfigurations, encodeServoConfiguration, MAX_SERVO_CONFIGS
  decodeServoTuning, encodeServoGlide
  decodeServoMixRules, encodeServoMixRule
  decodePidAdvanced, encodePidAdvanced
  encodePidTuning, decodePidTuning
  encodeRcTuning, decodeRcTuning
  encodeFilterConfig, decodeFilterConfig
  encodeOndas, decodeOndas, ONDAS_DEFAULTS, ONDAS_KEYS
  decodeOsdConfig, encodeOsdItem
} from '../protocol/mspDecoders.coffee'
import { itemPos } from '../lib/osdCatalog.coffee'

asciiBytes = (text) ->
  Array.from(text).map (character) -> character.charCodeAt 0
u16 = (value) -> [value & 0xff, value >>> 8 & 0xff]
u32 = (value) ->
  [value & 0xff, value >>> 8 & 0xff, value >>> 16 & 0xff, value >>> 24 & 0xff]
i16 = (value) -> u16 value & 0xffff

describe 'mspDecoders', ->
  it 'decodes API version and version strings', ->
    api = decodeApiVersion [0, 1, 49]
    expect(api).toMatchObject { protocol: 0, major: 1, minor: 49 }
    expect(api.version).toBe '1.49.0'
    version = decodeVersion [1, 49, 0]
    expect(version).toMatchObject { major: 1, minor: 49, patch: 0 }
    expect(version.version).toBe '1.49.0'

  it 'decodes variant, name and UID', ->
    expect(decodeVariant asciiBytes('ORNI')).toBe 'ORNI'
    expect(decodeName asciiBytes('ORNICOPTER-1')).toBe 'ORNICOPTER-1'
    uid = decodeUid [
      0x12, 0x34, 0x56, 0x78
      0x9A, 0xBC, 0xDE, 0xF0
      0x11, 0x22, 0x33, 0x44
    ]
    expect(uid.words).toEqual [0x78563412, 0xF0DEBC9A, 0x44332211]
    expect(uid.value).toBe '78563412f0debc9a44332211'

  it 'decodes build info with revision and label', ->
    payload = [
      asciiBytes('Jan  1 2026')...
      asciiBytes('00:00:00')...
      asciiBytes('abc1234')...
    ]
    build = decodeBuildInfo payload
    expect(build.date).toBe 'Jan  1 2026'
    expect(build.time).toBe '00:00:00'
    expect(build.revision).toBe 'abc1234'
    expect(build.label).toBe 'Jan  1 2026 00:00:00'

  it 'decodes board info including capabilities and names', ->
    payload = [
      asciiBytes('ORNI')...
      u16(2)...
      0x03
      0x07
      7, asciiBytes('ORNI-F7')...
      7, asciiBytes('ORNIPAD')...
      4, asciiBytes('ORNL')...
      (0xAA for _ in [0...32])...
      0x01
      0x00
    ]
    board = decodeBoardInfo payload
    expect(board.identifier).toBe 'ORNI'
    expect(board.hardwareRevision).toBe 2
    expect(board.targetName).toBe 'ORNI-F7'
    expect(board.boardName).toBe 'ORNIPAD'
    expect(board.manufacturerId).toBe 'ORNL'
    expect(board.signature.length).toBe 32
    expect(board.mcuTypeId).toBe 1
    expect(board.configurationState).toBe 0
    expect(board.targetCapabilities & 1).toBeTruthy()
    expect(board.targetCapabilities & 2).toBeTruthy()
    expect(board.targetCapabilities & 4).toBeTruthy()

  it 'decodes STATUS_EX with arming flags and sensors', ->
    payload = [
      u16(1000)...
      u16(0)...
      u16(0x21)...
      u32(1)...
      0x00
      u16(35)...
      0x03, 0x01
      0x00
      0x00
      u32(0)...
    ]
    status = decodeStatus payload
    expect(status.cycleTime).toBe 1000
    expect(status.armed).toBe true
    expect(status.sensors.accelerometer).toBe true
    expect(status.sensors.gyroscope).toBe true
    expect(status.sensors.barometer).toBe false
    expect(status.profileCount).toBe 3
    expect(status.rateProfile).toBe 1

  it 'decodes RAW_IMU with direct gyro dps (OrniFlight wire format)', ->
    payload = [
      i16(512)...
      i16(0)...
      i16(-512)...
      i16(360)...
      i16(-180)...
      i16(90)...
      i16(1090)...
      i16(0)...
      i16(-1090)...
    ]
    imu = decodeRawImu payload
    expect(imu.acceleration).toEqual [1, 0, -1]
    expect(imu.gyroscope).toEqual [360, -180, 90]
    expect(imu.magnetometer[0]).toBeCloseTo 1
    expect(imu.magnetometer[2]).toBeCloseTo -1

  it 'decodes attitude, channels and rx map', ->
    attitude = decodeAttitude [i16(123)..., i16(-45)..., i16(90)...]
    expect(attitude.roll).toBeCloseTo 12.3
    expect(attitude.pitch).toBeCloseTo -4.5
    expect(attitude.yaw).toBe 90
    channels = decodeChannels [u16(1000)..., u16(1500)..., u16(2000)...]
    expect(channels).toEqual [1000, 1500, 2000]
    expect(decodeRxMap [2, 0, 1, 3]).toEqual [2, 0, 1, 3]
    expect(decodeServos [u16(0)...]).toEqual [0]

  it 'decodes ANALOG in legacy and extended form', ->
    legacy = decodeAnalog [126, u16(500)..., u16(1023)..., i16(250)...]
    expect(legacy.voltage).toBeCloseTo 12.6
    expect(legacy.consumedMah).toBe 500
    expect(legacy.rssiRaw).toBe 1023
    expect(legacy.amperage).toBeCloseTo 2.5
    extended = decodeAnalog [
      126, u16(500)..., u16(1023)..., i16(250)..., u16(1175)...
    ]
    expect(extended.voltage).toBeCloseTo 11.75

  it 'decodes BATTERY_STATE with extended voltage', ->
    battery = decodeBatteryState [
      3, u16(1500)..., 126, u16(500)..., i16(250)..., 0x01, u16(1175)...
    ]
    expect(battery.cellCount).toBe 3
    expect(battery.capacityMah).toBe 1500
    expect(battery.consumedMah).toBe 500
    expect(battery.amperage).toBeCloseTo 2.5
    expect(battery.state).toBe 1
    expect(battery.voltage).toBeCloseTo 11.75

  it 'encodes craft names without padding and truncates at 24 bytes', ->
    bytes = encodeName 'ORNICOPTER'
    expect(Array.from bytes).toEqual asciiBytes('ORNICOPTER')
    expect(encodeName('A'.repeat 40).length).toBe 24
    expect(encodeName('')).toHaveLength 0

  it 'round-trips servo configurations through the wire format', ->
    source = {
      min: 1100, max: 1900, middle: 1520, rate: 90
      forwardFromChannel: 3, reversedSources: 5
    }
    bytes = Array.from encodeServoConfiguration(2, source)
    expect(bytes).toHaveLength 13
    expect(bytes[0]).toBe 2
    configs = decodeServoConfigurations bytes[1...]
    expect(configs).toHaveLength 1
    expect(configs[0]).toMatchObject { source..., index: 0 }

  it 'encodes negative servo rates as signed bytes', ->
    configs = decodeServoConfigurations(
      Array.from(encodeServoConfiguration(0, { rate: -10 }))[1...]
    )
    expect(configs[0].rate).toBe -10

  it 'fills servo configuration defaults for omitted fields', ->
    configs = decodeServoConfigurations(
      Array.from(encodeServoConfiguration(0, {}))[1...]
    )
    expect(configs[0]).toMatchObject {
      min: 1000, max: 2000, middle: 1500, rate: 100
      forwardFromChannel: 0, reversedSources: 0
    }

  it 'stops decoding servo configurations on truncated payloads', ->
    expect(decodeServoConfigurations [1, 2, 3]).toEqual []
    partial = Array.from(encodeServoConfiguration(0, {}))[1...12]
    expect(decodeServoConfigurations partial).toEqual []

  it 'decodes the MSP 120 servo tuning trailer after 8 records', ->
    records = [0...MAX_SERVO_CONFIGS].map (->
      Array.from(encodeServoConfiguration(0, {}))[1...])
    payload = records.flat().concat [90 + 128, 30 + 128, 40 + 128, 10 + 128]
    tuning = decodeServoTuning payload
    expect(tuning).toEqual {
      glide: 90, cadence: 30, ferocityD: 40, balance: 10
    }

  it 'encodes glide payloads for the MSP 212 short form', ->
    expect(Array.from encodeServoGlide(-15)).toEqual [113]
    expect(Array.from(encodeServoGlide(20, {
      cadence: 30, ferocityD: 40, balance: 10
    }))).toEqual [148, 158, 168, 138]

  it 'round-trips servo mix rules through the wire format', ->
    source = {
      targetChannel: 2, inputSource: 3, rate: -50
      speed: 25, min: 10, max: 90, box: 1
    }
    bytes = Array.from encodeServoMixRule(5, source)
    expect(bytes).toHaveLength 8
    expect(bytes[0]).toBe 5
    rules = decodeServoMixRules bytes[1...]
    expect(rules).toHaveLength 1
    expect(rules[0]).toMatchObject { source..., index: 0 }

  it 'round-trips the PID advanced wing-mapping appendix', ->
    appendix = {
      flapBaseAmplitude: 45
      itermRelaxCutoff: 10
      cadence: 30, ferocityD: 40, balance: 10
      ferocityP: 20, ferocityRoll: 30, ferocityYaw: 25
      warpGain: 20, warpYawGain: 15
      anchorGain: 50, resonanceGain: 10
      servoMountAngle: [12, -8, 0, 5]
      flappingPhaseShift: [0, 120, 0, 0]
      prescience: 5, espelho: 0, saudade: 0, ssff: 20
      servoTravelTimeMs: 300
      servoMaxAmplitude: 45, flapMagnitude: 45
      wingOriginOffset: [0, 0, -3, 0]
      freqChannel: 4, freqMin: 3, freqMax: 8
      profileIndex: 0
    }
    payload = encodePidAdvanced { appendix }
    expect(payload).toHaveLength 46 + 37
    decoded = decodePidAdvanced payload
    expect(decoded.prefix).toHaveLength 46
    expect(decoded.appendix).toEqual appendix
    expect(Array.from encodePidAdvanced(decoded)).toEqual(
      Array.from payload
    )

  it 'round-trips PID tuning through the scaled u16 wire format', ->
    source = {
      roll: { P: 4.0, I: 0.03, D: 23.0 }
      pitch: { P: 6.0, I: 0.04, D: 28.0 }
      yaw: { P: 3.0, I: 0.05, D: 0.0 }
      flap: { P: 0.0, I: 0.0, D: 0.0 }
    }
    bytes = Array.from encodePidTuning(source)
    expect(bytes).toHaveLength 24
    expect(decodePidTuning(bytes)).toEqual source

  it 'scales PID gains with three decimal places of precision', ->
    source = {
      roll: { P: 4.25, I: 0.033, D: 23.5 }
      pitch: { P: 0, I: 0, D: 0 }
      yaw: { P: 0, I: 0, D: 0 }
      flap: { P: 0, I: 0, D: 0 }
    }
    decoded = decodePidTuning Array.from(encodePidTuning(source))
    expect(decoded.roll).toEqual { P: 4.25, I: 0.033, D: 23.5 }

  it 'decodes truncated PID payloads with zero fill', ->
    decoded = decodePidTuning [0x10, 0x27]
    expect(decoded.roll.P).toBeCloseTo 10
    expect(decoded.roll.I).toBe 0
    expect(decoded.roll.D).toBe 0
    expect(decoded.flap.D).toBe 0

  it 'round-trips RC tuning rates', ->
    source = { rcRate: 100, superRate: 70, expo: 35 }
    bytes = Array.from encodeRcTuning(source)
    expect(bytes).toHaveLength 3
    expect(decodeRcTuning(bytes)).toEqual source

  it 'clamps RC tuning encode to the u8 range', ->
    bytes = Array.from encodeRcTuning { rcRate: 500, superRate: -5, expo: 100 }
    expect(decodeRcTuning(bytes)).toEqual { rcRate: 255, superRate: 0, expo: 100 }

  it 'decodes truncated RC tuning payloads with zero fill', ->
    expect(decodeRcTuning [90]).toEqual { rcRate: 90, superRate: 0, expo: 0 }
    expect(decodeRcTuning []).toEqual { rcRate: 0, superRate: 0, expo: 0 }

  it 'round-trips filter configuration', ->
    source = {
      gyroDlpfHz: 250, gyroNotchHz: 400, gyroNotchQ: 6, dTermDlpfHz: 50
    }
    bytes = Array.from encodeFilterConfig(source)
    expect(bytes).toHaveLength 7
    expect(decodeFilterConfig(bytes)).toEqual source

  it 'decodes truncated filter payloads with zero fill', ->
    expect(decodeFilterConfig u16(250)).toEqual {
      gyroDlpfHz: 250, gyroNotchHz: 0, gyroNotchQ: 0, dTermDlpfHz: 0
    }

  it 'round-trips ONDAS params in fixed key order', ->
    source = {
      cadence_gain: 30, ferocity_d_gain: 40, ferocity_p_gain: 20
      balance_gain: 10, ferocity_roll_gain: 30, ferocity_yaw_gain: 25
      warp_gain: 20, warp_yaw_gain: 15, anchor_gain: 50, resonance_gain: 10
    }
    bytes = Array.from encodeOndas(source)
    expect(bytes).toHaveLength 10
    expect(decodeOndas(bytes)).toEqual source

  it 'fills missing ONDAS bytes with zeros on truncation', ->
    partial = decodeOndas [90, 80]
    expect(partial.cadence_gain).toBe 90
    expect(partial.ferocity_d_gain).toBe 80
    expect(partial.resonance_gain).toBe 0

  it 'freezes ONDAS defaults with ten keys', ->
    expect(Object.isFrozen ONDAS_DEFAULTS).toBe true
    expect(ONDAS_KEYS).toHaveLength 10
    expect(ONDAS_DEFAULTS.anchor_gain).toBe 50

  it 'clamps negative and oversized PID gains on encode', ->
    source = {
      roll: { P: -1, I: 0.03, D: 200 }
      pitch: { P: 0, I: 0, D: 0 }
      yaw: { P: 0, I: 0, D: 0 }
      flap: { P: 0, I: 0, D: 0 }
    }
    decoded = decodePidTuning Array.from(encodePidTuning(source))
    expect(decoded.roll.P).toBe 0
    expect(decoded.roll.D).toBe 65.535
    expect(decoded.roll.I).toBeCloseTo 0.03

  it 'encodes a fully omitted PID document as zero-filled bytes', ->
    bytes = Array.from encodePidTuning({})
    expect(bytes).toHaveLength 24
    expect(bytes.every (byte) -> byte == 0).toBe true