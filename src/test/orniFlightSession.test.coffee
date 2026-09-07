import { describe, it, expect, vi } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient, { MspTimeoutError } from '../protocol/mspClient.coffee'
import OrniFlightSession, {
  FirmwareCompatibilityError
} from '../protocol/orniFlightSession.coffee'
import { MockMspTransport, scriptedResponder } from './mockMspTransport.coffee'
import {
  encodeServoConfiguration, ONDAS_DEFAULTS
} from '../protocol/mspDecoders.coffee'
import { itemPos } from '../lib/osdCatalog.coffee'

asciiBytes = (text) ->
  Array.from(text).map (character) -> character.charCodeAt 0
u16 = (value) -> [value & 0xff, value >>> 8 & 0xff]
u32 = (value) ->
  [value & 0xff, value >>> 8 & 0xff, value >>> 16 & 0xff, value >>> 24 & 0xff]
i16 = (value) -> u16 value & 0xffff

statusPayload = [
  u16(1000)...
  u16(0)...
  u16(0x20)...
  u32(0)...
  0x00
  u16(30)...
  0x01, 0x01
  0x00
  0x00
  u32(0)...
]

boardPayload = [
  asciiBytes('ORNI')...
  u16(2)...
  0x03
  0x07
  7, asciiBytes('ORNI-F7')...
  7, asciiBytes('ORNIPAD')...
  4, asciiBytes('ORNL')...
  (0 for _ in [0...32])...
  0x01
  0x00
]

handshakeScript = {
  [MSP_CODES.API_VERSION]: [0, 1, 49]
  [MSP_CODES.FC_VARIANT]: asciiBytes 'ORNI'
  [MSP_CODES.FC_VERSION]: [1, 49, 0]
  [MSP_CODES.BUILD_INFO]: [
    asciiBytes('Jan  1 2026')...
    asciiBytes('00:00:00')...
    asciiBytes('abc1234')...
  ]
  [MSP_CODES.BOARD_INFO]: boardPayload
  [MSP_CODES.UID]: 'unsupported'
  [MSP_CODES.NAME]: asciiBytes 'ORNICOPTER-1'
  [MSP_CODES.STATUS_EX]: statusPayload
  [MSP_CODES.RX_MAP]: [2, 0, 1, 3]
}

pollScript = {
  [MSP_CODES.RAW_IMU]: [
    i16(0)..., i16(0)..., i16(0)...
    i16(360)..., i16(-180)..., i16(90)...
    i16(0)..., i16(0)..., i16(0)...
  ]
  [MSP_CODES.ATTITUDE]: [i16(123)..., i16(-45)..., i16(90)...]
  [MSP_CODES.RC]: [u16(988)..., u16(1500)..., u16(2012)..., u16(1100)...]
  [MSP_CODES.SERVO]: [u16(100)..., u16(200)...]
  [MSP_CODES.ANALOG]: [
    126, u16(0)..., u16(1023)..., i16(250)..., u16(1175)...
  ]
  [MSP_CODES.BATTERY_STATE]: [
    3, u16(1500)..., 126, u16(0)..., i16(250)..., 0x01, u16(1175)...
  ]
}

tuningDoc = {
  pid: {
    roll: { P: 4.0, I: 0.03, D: 23.0 }
    pitch: { P: 6.0, I: 0.04, D: 28.0 }
    yaw: { P: 3.0, I: 0.05, D: 0.0 }
    flap: { P: 0.0, I: 0.0, D: 0.0 }
  }
  rate: { rcRate: 100, superRate: 70, expo: 35 }
  ondas: ONDAS_DEFAULTS
  filter: { gyroDlpfHz: 250, gyroNotchHz: 400, gyroNotchQ: 6, dTermDlpfHz: 50 }
}

tuningPayloads = {
  [MSP_CODES.PID]: [
    u16(4000)..., u16(30)..., u16(23000)...
    u16(6000)..., u16(40)..., u16(28000)...
    u16(3000)..., u16(50)..., u16(0)...
    u16(0)..., u16(0)..., u16(0)...
  ]
  [MSP_CODES.RC_TUNING]: [100, 70, 35]
  [MSP_CODES.FILTER_CONFIG]: [u16(250)..., u16(400)..., 6, u16(50)...]
  [MSP_CODES.ONDAS]: [30, 40, 20, 10, 30, 25, 20, 15, 50, 10]
}

# Echoes written tuning sections on read-back so writeTuning's
# verification loop sees the stored values. Writes arrive under the
# SET_* codes while the verification reads use the GET codes, so the
# payloads are stored under their read codes.
tuningStoreResponder = (script) ->
  stored = {}
  fallback = scriptedResponder script
  writeToRead = {
    [MSP_CODES.SET_PID]: MSP_CODES.PID
    [MSP_CODES.SET_RC_TUNING]: MSP_CODES.RC_TUNING
    [MSP_CODES.SET_FILTER_CONFIG]: MSP_CODES.FILTER_CONFIG
    [MSP_CODES.SET_ONDAS]: MSP_CODES.ONDAS
  }
  (bytes) ->
    command = bytes[4] | bytes[5] << 8
    length = bytes[6] | bytes[7] << 8
    payload = Array.from bytes.subarray 8, 8 + length
    if writeToRead[command]?
      stored[writeToRead[command]] = payload
      return { command, direction: '>', payload: [] }
    if command == MSP_CODES.EEPROM_WRITE
      return { command, direction: '>', payload: [] }
    if command in Object.values writeToRead
      return { command, direction: '>', payload: stored[command] or [] }
    fallback bytes

openSession = (script, callbacks = {}) ->
  transport = new MockMspTransport {
    autoRespond: true
    responder: scriptedResponder script
  }
  client = new MspClient transport, { timeoutMs: 500 }
  await client.open()
  session = new OrniFlightSession client, callbacks
  { transport, client, session }

describe 'orniFlightSession', ->
  it 'completes a handshake and builds the craft identity', ->
    { session } = await openSession handshakeScript
    identity = await session.handshake()
    expect(identity.api.major).toBe 1
    expect(identity.variant).toBe 'ORNI'
    expect(identity.firmware.version).toBe '1.49.0'
    expect(identity.board.targetName).toBe 'ORNI-F7'
    expect(identity.capabilities.vcp).toBe true
    expect(identity.capabilities.unifiedTarget).toBe true
    expect(identity.capabilities.sensors.gyroscope).toBe true
    expect(identity.name).toBe 'ORNICOPTER-1'
    expect(identity.uid).toBe null
    expect(identity.rxMap).toEqual [2, 0, 1, 3]
    expect(identity.status.armed).toBe false

  it 'rejects a handshake when the API major differs', ->
    script = { [MSP_CODES.API_VERSION]: [0, 2, 0] }
    { session } = await openSession script
    error = await session.handshake().catch (error) -> error
    expect(error).toBeInstanceOf FirmwareCompatibilityError
    expect(error.api.major).toBe 2

  it 'rejects a handshake from a non-OrniFlight target', ->
    script = {
      [MSP_CODES.API_VERSION]: [0, 1, 49]
      [MSP_CODES.FC_VARIANT]: asciiBytes 'BETA'
    }
    { session } = await openSession script
    error = await session.handshake().catch (error) -> error
    expect(error).toBeInstanceOf FirmwareCompatibilityError
    expect(error.variant).toBe 'BETA'

  it 'refuses to start polling before handshake', ->
    { session } = await openSession handshakeScript
    expect((-> session.start())).toThrow(
      'Handshake must complete before telemetry starts'
    )

  it 'polls telemetry and emits device-sourced frames with rxMap mapping', ->
    vi.useFakeTimers()
    try
      script = { handshakeScript..., pollScript... }
      frames = []
      { session } = await openSession script, {
        onTelemetry: (frame) -> frames.push frame
      }
      await session.handshake()
      session.start()
      await vi.advanceTimersByTimeAsync 1
      expect(frames.length).toBe 1
      frame = frames[0]
      expect(frame.source).toBe 'device'
      expect(frame.rcChannels).toEqual [988, 1500, 2012, 1100]
      expect(frame.rcRoll).toBe 2012
      expect(frame.rcPitch).toBe 988
      expect(frame.rcYaw).toBe 1500
      expect(frame.rcThrottle).toBe 1100
      expect(frame.gyroRoll).toBe 360
      expect(frame.gyroPitch).toBe -180
      expect(frame.batteryVoltage).toBeCloseTo 11.75
      expect(frame.rssi).toBe 100
      expect(frame.servos).toEqual [100, 200]
      expect(frame.attitude.roll).toBeCloseTo 12.3
      session.stop()
      await session.close()
    finally
      vi.useRealTimers()

  it 'emits status only every five poll rounds', ->
    vi.useFakeTimers()
    try
      script = { handshakeScript..., pollScript... }
      statuses = []
      { session } = await openSession script, {
        onStatus: (status) -> statuses.push status
      }
      await session.handshake()
      expect(statuses.length).toBe 1
      session.start()
      await vi.advanceTimersByTimeAsync 1
      expect(statuses.length).toBe 2
      for round in [1..4]
        await vi.advanceTimersByTimeAsync 100
      expect(statuses.length).toBe 2
      await vi.advanceTimersByTimeAsync 100
      expect(statuses.length).toBe 3
      session.stop()
      await session.close()
    finally
      vi.useRealTimers()

  it 'renames the craft with write-back verification', ->
    currentName = 'ORNICOPTER-1'
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      length = bytes[6] | bytes[7] << 8
      payload = Array.from bytes.subarray 8, 8 + length
      if command == MSP_CODES.SET_NAME
        currentName = String.fromCharCode(payload...)
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.NAME
        return { command, direction: '>', payload: asciiBytes currentName }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    identity = await session.setCraftName 'SKYFISH-2'
    expect(identity.name).toBe 'SKYFISH-2'
    expect(currentName).toBe 'SKYFISH-2'
    commands = transport.writes.map((bytes) -> bytes[4] | bytes[5] << 8)
    expect(commands.slice(-3)).toEqual [
      MSP_CODES.SET_NAME, MSP_CODES.EEPROM_WRITE, MSP_CODES.NAME
    ]

  it 'refuses to rename while armed', ->
    armedStatus = [
      statusPayload[0...6]...
      u32(1)...
      statusPayload[10...]...
    ]
    script = { handshakeScript..., [MSP_CODES.STATUS_EX]: armedStatus }
    { session } = await openSession script
    await session.handshake()
    error = await session.setCraftName('X').catch (error) -> error
    expect(error.message).toContain 'armed'

  it 'stops polling and reports the failure when a round throws', ->
    vi.useFakeTimers()
    try
      script = handshakeScript # no pollScript: RAW_IMU request times out
      failures = []
      { session } = await openSession script, {
        onFailure: (error) -> failures.push error
      }
      await session.handshake()
      session.start()
      await vi.advanceTimersByTimeAsync 600
      expect(failures.length).toBe 1
      expect(failures[0]).toBeInstanceOf MspTimeoutError
      expect(session.running).toBe false
      await session.close()
    finally
      vi.useRealTimers()

  it 'rejects craft names at the boundary (empty and over 24)', ->
    { session } = await openSession handshakeScript
    await session.handshake()
    await expect(session.setCraftName '').rejects.toThrow 'Craft name must contain'
    await expect(session.setCraftName('A'.repeat 25)).rejects.toThrow(
      'Craft name must contain'
    )

  it 'throws when the craft name read-back diverges', ->
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      return { command, direction: '>', payload: [] } if command == MSP_CODES.SET_NAME
      return { command, direction: '>', payload: [] } if command == MSP_CODES.EEPROM_WRITE
      if command == MSP_CODES.NAME
        return { command, direction: '>', payload: asciiBytes 'STALE-NAME' }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.setCraftName 'SKYFISH-2').rejects.toThrow 'read-back failed'

  it 'writes a servo configuration with eeprom and read-back', ->
    servoPayloads = { 0: null, 1: null }
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      length = bytes[6] | bytes[7] << 8
      payload = Array.from bytes.subarray 8, 8 + length
      if command == MSP_CODES.SET_SERVO_CONFIGURATION
        servoPayloads[payload[0]] = payload[1...]
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SERVO_CONFIGURATIONS
        stored = [
          (servoPayloads[0] ? Array.from(encodeServoConfiguration(0, {}))[1...])...
          (servoPayloads[1] ? Array.from(encodeServoConfiguration(1, {}))[1...])...
        ]
        return { command, direction: '>', payload: stored }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    result = await session.writeServoConfiguration 0, {
      min: 1100, max: 1900, middle: 1520, rate: 90
    }
    expect(result.index).toBe 0
    expect(result.config).toMatchObject {
      min: 1100, max: 1900, middle: 1520, rate: 90
    }
    commands = transport.writes.map((bytes) -> bytes[4] | bytes[5] << 8)
    expect(commands.slice(-3)).toEqual [
      MSP_CODES.SET_SERVO_CONFIGURATION
      MSP_CODES.EEPROM_WRITE
      MSP_CODES.SERVO_CONFIGURATIONS
    ]

  it 'reads tuning parameters from the firmware', ->
    script = { handshakeScript..., tuningPayloads... }
    { session } = await openSession script
    await session.handshake()
    tuning = await session.readTuning()
    expect(tuning.pid.roll).toEqual { P: 4.0, I: 0.03, D: 23.0 }
    expect(tuning.pid.pitch).toEqual { P: 6.0, I: 0.04, D: 28.0 }
    expect(tuning.pid.flap).toEqual { P: 0.0, I: 0.0, D: 0.0 }
    expect(tuning.rate).toEqual { rcRate: 100, superRate: 70, expo: 35 }
    expect(tuning.ondas).toEqual ONDAS_DEFAULTS
    expect(tuning.filter).toEqual {
      gyroDlpfHz: 250, gyroNotchHz: 400, gyroNotchQ: 6, dTermDlpfHz: 50
    }

  it 'falls back to tuning defaults for unsupported sections', ->
    script = {
      handshakeScript...
      [MSP_CODES.PID]: 'unsupported'
      [MSP_CODES.RC_TUNING]: 'unsupported'
      [MSP_CODES.FILTER_CONFIG]: 'unsupported'
      [MSP_CODES.ONDAS]: 'unsupported'
    }
    { session } = await openSession script
    await session.handshake()
    tuning = await session.readTuning()
    expect(tuning.pid.roll).toEqual { P: 4.0, I: 0.03, D: 23.0 }
    expect(tuning.rate).toEqual { rcRate: 100, superRate: 0, expo: 0 }
    expect(tuning.ondas).toEqual ONDAS_DEFAULTS
    expect(tuning.filter).toEqual {
      gyroDlpfHz: 0, gyroNotchHz: 0, gyroNotchQ: 0, dTermDlpfHz: 0
    }

  it 'writes tuning with a single eeprom write and read-back', ->
    transport = new MockMspTransport {
      autoRespond: true
      responder: tuningStoreResponder handshakeScript
    }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    result = await session.writeTuning tuningDoc
    expect(result.pid.roll).toEqual tuningDoc.pid.roll
    expect(result.rate).toEqual tuningDoc.rate
    # The transport log also contains the handshake requests — filter
    # to the tuning conversation before asserting the exact order.
    tuningCodes = [
      MSP_CODES.SET_PID, MSP_CODES.SET_RC_TUNING
      MSP_CODES.SET_FILTER_CONFIG, MSP_CODES.SET_ONDAS
      MSP_CODES.EEPROM_WRITE
      MSP_CODES.PID, MSP_CODES.RC_TUNING
      MSP_CODES.FILTER_CONFIG, MSP_CODES.ONDAS
    ]
    commands = transport.writes
      .map((bytes) -> bytes[4] | bytes[5] << 8)
      .filter((c) -> c in tuningCodes)
    expect(commands.filter((c) -> c == MSP_CODES.EEPROM_WRITE).length).toBe 1
    expect(commands).toEqual tuningCodes

  it 'refuses to write tuning parameters while armed', ->
    armedStatus = [
      statusPayload[0...6]...
      u32(1)...
      statusPayload[10...]...
    ]
    script = { handshakeScript..., [MSP_CODES.STATUS_EX]: armedStatus }
    { session } = await openSession script
    await session.handshake()
    error = await session.writeTuning(tuningDoc).catch (error) -> error
    expect(error.message).toContain 'armed'

  it 'throws when a tuning section read-back diverges', ->
    base = tuningStoreResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.ONDAS
        return { command, direction: '>', payload: (0 for _ in [0...10]) }
      base bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeTuning tuningDoc).rejects.toThrow(
      'Tuning read-back failed: ondas'
    )

  it 'refuses to write servo configuration while armed', ->
    armedStatus = [
      statusPayload[0...6]...
      u32(1)...
      statusPayload[10...]...
    ]
    script = { handshakeScript..., [MSP_CODES.STATUS_EX]: armedStatus }
    { session } = await openSession script
    await session.handshake()
    error = await session.writeServoConfiguration(0, {}).catch (error) -> error
    expect(error.message).toContain 'armed'

  it 'rejects out-of-range servo indices', ->
    { session } = await openSession handshakeScript
    await session.handshake()
    await expect(session.writeServoConfiguration 8, {}).rejects.toThrow(
      'Servo index out of range'
    )

  it 'reports an empty servo table when unsupported by firmware', ->
    script = {
      handshakeScript...
      [MSP_CODES.SERVO_CONFIGURATIONS]: 'unsupported'
    }
    { session } = await openSession script
    await session.handshake()
    configs = await session.readServoConfigurations()
    expect(configs).toEqual []

  it 'throws when the servo configuration read-back diverges', ->
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.SET_SERVO_CONFIGURATION
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SERVO_CONFIGURATIONS
        stale = Array.from(encodeServoConfiguration(0, {})).slice(1)
        return { command, direction: '>', payload: stale }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeServoConfiguration 0, {
      min: 1100, max: 1900, middle: 1520
    }).rejects.toThrow 'read-back failed'

osdConfigPayload = (positions) ->
  bytes = []
  push8 = (value) -> bytes.push value & 0xFF
  push16 = (value) -> bytes.push value & 0xFF, (value >> 8) & 0xFF
  push32 = (value) ->
    push16 value & 0xFFFF
    push16 value >>> 16 & 0xFFFF
  push8 0x01
  push8 0
  push8 0
  push8 20
  push16 2200
  push8 0
  push8 positions.length
  push16 100
  for position in positions
    push16 position
  push8 0
  push8 2
  push16 1000
  push16 2000
  push16 0
  push8 8
  push32 0xFFFFFFFF
  push8 3
  push8 1
  push8 2
  new Uint8Array bytes

describe 'OrniFlightSession OSD layout', ->
  it 'reads the OSD configuration payload', ->
    positions = (itemPos(10, 7) for _ in [0...52])
    positions[2] = itemPos 13, 6
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.OSD_CONFIG
        return { command, direction: '>', payload: osdConfigPayload positions }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    config = await session.readOsdConfig()
    expect(config.items).toHaveLength 52
    expect(config.items[2]).toBe itemPos 13, 6
    expect(config.profileIndex).toBe 1
    expect(config.overlayRadioMode).toBe 2

  it 'writes the layout item-wise and verifies the read-back', ->
    stored = (itemPos(10, 7) for _ in [0...52])
    stored[21] = itemPos(9, 10) | 0x3800
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.SET_OSD_CONFIG
        index = bytes[8]
        position = bytes[9] | bytes[10] << 8
        stored[index] = position if 0 <= index < stored.length
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.OSD_CONFIG
        return { command, direction: '>', payload: osdConfigPayload stored }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    layout = (itemPos(10, 7) for _ in [0...52])
    layout[5] = itemPos 3, 9
    result = await session.writeOsdConfig { items: layout }
    expect(result.items[5]).toBe itemPos 3, 9
    writes = transport.writes.filter (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.SET_OSD_CONFIG
    expect(writes).toHaveLength 52
    expect(writes[5][8]).toBe 5
    expect(writes[5][9] | writes[5][10] << 8).toBe itemPos 3, 9

  it 'refuses to write while armed', ->
    positions = (itemPos(10, 7) for _ in [0...52])
    fallback = scriptedResponder handshakeScript
    transport = new MockMspTransport { autoRespond: true, responder: fallback }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    session.lastStatus.armed = true
    await expect(session.writeOsdConfig {
      items: positions
    }).rejects.toThrow 'Cannot write configuration while armed'