import { describe, it, expect, vi } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient, { MspTimeoutError } from '../protocol/mspClient.coffee'
import OrniFlightSession, {
  FirmwareCompatibilityError
} from '../protocol/orniFlightSession.coffee'
import { MockMspTransport, scriptedResponder } from './mockMspTransport.coffee'
import { encodeServoConfiguration } from '../protocol/mspDecoders.coffee'

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