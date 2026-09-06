import { describe, it, expect } from 'vitest'
import {
  decodeApiVersion, decodeVariant, decodeVersion, decodeBuildInfo
  decodeBoardInfo, decodeUid, decodeName, decodeStatus, decodeRawImu
  decodeAttitude, decodeChannels, decodeRxMap, decodeServos
  decodeAnalog, decodeBatteryState, encodeName
} from '../protocol/mspDecoders.coffee'

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