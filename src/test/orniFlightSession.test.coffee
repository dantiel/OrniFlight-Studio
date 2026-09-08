import { describe, it, expect, vi } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient, { MspTimeoutError } from '../protocol/mspClient.coffee'
import OrniFlightSession, {
  FirmwareCompatibilityError
} from '../protocol/orniFlightSession.coffee'
import { MockMspTransport, scriptedResponder } from './mockMspTransport.coffee'
import {
  encodeServoConfiguration, ONDAS_DEFAULTS
  decodePidAdvanced, encodePidAdvanced, RX_CONFIG_BYTES
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

  it 'writes the glide degree through the MSP 212 short form', ->
    glideWrites = []
    storedGlide = 0
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      length = bytes[6] | bytes[7] << 8
      payload = Array.from bytes.subarray 8, 8 + length
      if command == MSP_CODES.SET_SERVO_CONFIGURATION
        glideWrites.push payload
        storedGlide = payload[0]
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SERVO_CONFIGURATIONS
        trailer = [
          (0 for _ in [0...96])...
          storedGlide, 0, 0, 0
        ]
        return { command, direction: '>', payload: trailer }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    result = await session.writeGlideDegree 20
    expect(result).toBe 20
    expect(glideWrites).toEqual [[148]]
    expect(await session.readGlideDegree()).toBe 20

  it 'throws when the glide read-back diverges', ->
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.SET_SERVO_CONFIGURATION
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SERVO_CONFIGURATIONS
        trailer = [
          (0 for _ in [0...96])...
          5 + 128, 0, 0, 0
        ]
        return { command, direction: '>', payload: trailer }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeGlideDegree 20).rejects.toThrow(
      'Glide read-back failed'
    )

  it 'writes a servo mix rule with eeprom and read-back', ->
    rulePayloads = { 3: null }
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      length = bytes[6] | bytes[7] << 8
      payload = Array.from bytes.subarray 8, 8 + length
      if command == MSP_CODES.SET_SERVO_MIX_RULE
        rulePayloads[payload[0]] = payload[1...]
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SERVO_MIX_RULES
        stored = (0 for _ in [0...112])
        for index, data of rulePayloads when data
          stored.splice index * 7, data.length, data...
        return { command, direction: '>', payload: stored }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    result = await session.writeServoMixRule 3, {
      targetChannel: 1, inputSource: 2, rate: -25
      speed: 10, min: 0, max: 100, box: 0
    }
    expect(result.index).toBe 3
    expect(result.rule).toMatchObject {
      targetChannel: 1, inputSource: 2, rate: -25
    }
    commands = transport.writes.map((bytes) -> bytes[4] | bytes[5] << 8)
    expect(commands.slice(-3)).toEqual [
      MSP_CODES.SET_SERVO_MIX_RULE
      MSP_CODES.EEPROM_WRITE
      MSP_CODES.SERVO_MIX_RULES
    ]

  it 'writes the wing-mapping appendix read-modify-write', ->
    current = {
      flapBaseAmplitude: 45, itermRelaxCutoff: 0
      cadence: 30, ferocityD: 40, balance: 10
      ferocityP: 20, ferocityRoll: 30, ferocityYaw: 25
      warpGain: 20, warpYawGain: 15
      anchorGain: 50, resonanceGain: 10
      servoMountAngle: [0, 0, 0, 0]
      flappingPhaseShift: [0, 0, 0, 0]
      prescience: 5, espelho: 0, saudade: 0, ssff: 20
      servoTravelTimeMs: 300
      servoMaxAmplitude: 45, flapMagnitude: 45
      wingOriginOffset: [0, 0, 0, 0]
      freqChannel: 0, freqMin: 3, freqMax: 8
      profileIndex: 0
    }
    stored = current
    writes = []
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      length = bytes[6] | bytes[7] << 8
      payload = Array.from bytes.subarray 8, 8 + length
      if command == MSP_CODES.PID_ADVANCED
        envelope = encodePidAdvanced { appendix: stored }
        return { command, direction: '>', payload: Array.from envelope }
      if command == MSP_CODES.SET_PID_ADVANCED
        writes.push payload
        stored = decodePidAdvanced(payload).appendix
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    result = await session.writeWingMapping { anchorGain: 70 }
    expect(result.anchorGain).toBe 70
    expect(result.cadence).toBe 30
    expect(writes).toHaveLength 1

  it 'skips inherited keys during wing-mapping read-back', ->
    current = { anchorGain: 50, cadence: 30 }
    stored = current
    writes = []
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      length = bytes[6] | bytes[7] << 8
      payload = Array.from bytes.subarray 8, 8 + length
      if command == MSP_CODES.PID_ADVANCED
        envelope = encodePidAdvanced { appendix: stored }
        return { command, direction: '>', payload: Array.from envelope }
      if command == MSP_CODES.SET_PID_ADVANCED
        writes.push payload
        stored = decodePidAdvanced(payload).appendix
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    hostile = Object.assign Object.create({ constructor: 42 }), {
      anchorGain: 70
    }
    result = await session.writeWingMapping hostile
    expect(result.anchorGain).toBe 70
    expect(result.cadence).toBe 30
    expect(writes).toHaveLength 1

  it 'refuses the wing mapping when the firmware lacks the appendix', ->
    fallback = scriptedResponder handshakeScript
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.PID_ADVANCED
        return { command, direction: '>', payload: (0 for _ in [0...46]) }
      fallback bytes
    transport = new MockMspTransport { autoRespond: true, responder }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeWingMapping { anchorGain: 70 }).rejects.toThrow(
      'wing-mapping appendix'
    )

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

  it 'clamps an oversized layout to 52 slots on write', ->
    stored = (itemPos(10, 7) for _ in [0...52])
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
    oversized = (itemPos(1, 1) for _ in [0...80])
    result = await session.writeOsdConfig { items: oversized }
    expect(result.items).toHaveLength 52
    writes = transport.writes.filter (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.SET_OSD_CONFIG
    expect(writes).toHaveLength 52

  it 'rejects an empty layout on write', ->
    fallback = scriptedResponder handshakeScript
    transport = new MockMspTransport { autoRespond: true, responder: fallback }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeOsdConfig { items: [] }).rejects.toThrow(
      'OSD configuration items missing'
    )
    await expect(session.writeOsdConfig null).rejects.toThrow(
      'OSD configuration items missing'
    )

describe 'receiver and modes session', ->
  rxConfigPayload = ->
    [
      9
      u16(1900)...
      u16(1500)...
      u16(1050)...
      0
      u16(885)...
      u16(2115)...
      0, 0
      u16(1000)...
    ]

  modeRangesPayload = (slots) ->
    payload = []
    for slot in slots
      payload.push slot[0], slot[1], slot[2], slot[3]
    payload

  modeRangesExtraPayload = (slots) ->
    payload = [slots.length]
    for slot in slots
      payload.push slot[0], slot[4], slot[5]
    payload

  receiverState = ->
    rxConfig: rxConfigPayload()
    rxMap: [0, 1, 3, 2, 4, 5, 6, 7]
    rxFail: ([0, u16(1500)...] for _ in [0...6])
    modeRanges: ([0, 0, 0, 0, 0, 0] for _ in [0...20])

  # Stateful device double: stores SET payloads, answers reads from
  # the stored state, falls back to the handshake script.
  receiverResponder = (state) ->
    fallback = scriptedResponder handshakeScript
    (bytes) ->
      command = bytes[4] | bytes[5] << 8
      if command == MSP_CODES.SET_RX_CONFIG
        state.rxConfig = Array.from bytes.subarray 8, 8 + RX_CONFIG_BYTES
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SET_RX_MAP
        state.rxMap = Array.from bytes.subarray 8, 16
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SET_RXFAIL_CONFIG
        index = bytes[8]
        # The firmware only stores slots inside its runtime channelCount.
        state.rxFail[index] = Array.from bytes.subarray 9, 12 if (
          index < state.rxFail.length
        )
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.SET_MODE_RANGE
        state.modeRanges[bytes[8]] = Array.from bytes.subarray 9, 15
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.EEPROM_WRITE
        return { command, direction: '>', payload: [] }
      if command == MSP_CODES.RX_CONFIG
        return { command, direction: '>', payload: state.rxConfig }
      if command == MSP_CODES.RX_MAP
        return { command, direction: '>', payload: state.rxMap }
      if command == MSP_CODES.RXFAIL_CONFIG
        payload = []
        payload.push slot... for slot in state.rxFail
        return { command, direction: '>', payload }
      if command == MSP_CODES.MODE_RANGES
        return {
          command, direction: '>', payload: modeRangesPayload state.modeRanges
        }
      if command == MSP_CODES.MODE_RANGES_EXTRA
        return {
          command, direction: '>'
          payload: modeRangesExtraPayload state.modeRanges
        }
      fallback bytes

  openResponderSession = (state) ->
    transport = new MockMspTransport {
      autoRespond: true
      responder: receiverResponder state
    }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    { transport, session }

  it 'reads the receiver document', ->
    state = receiverState()
    { session } = await openSession {
      handshakeScript...
      [MSP_CODES.RX_CONFIG]: state.rxConfig
      [MSP_CODES.RX_MAP]: state.rxMap
      [MSP_CODES.RXFAIL_CONFIG]: state.rxFail.flat()
    }
    await session.handshake()
    config = await session.readRxConfig()
    expect(config.provider).toBe 9
    expect(config.maxcheck).toBe 1900
    expect(config.airModeActivateThreshold).toBe 0
    expect(await session.readRxMap()).toEqual state.rxMap
    channels = await session.readRxFailConfig()
    expect(channels).toHaveLength 6
    expect(channels[0]).toEqual { index: 0, mode: 0, value: 1500 }

  it 'writes receiver configuration and verifies only supplied fields', ->
    state = receiverState()
    { transport, session } = await openResponderSession state
    result = await session.writeRxConfig { provider: 7 }
    expect(result.provider).toBe 7
    writes = transport.writes.filter (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.SET_RX_CONFIG
    expect(writes).toHaveLength 1
    expect(writes[0][8]).toBe 7
    expect(transport.writes.some (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.EEPROM_WRITE
    ).toBe true

  it 'throws when the receiver read-back diverges', ->
    state = receiverState()
    transport = new MockMspTransport {
      autoRespond: true
      responder: (bytes) ->
        command = bytes[4] | bytes[5] << 8
        if command == MSP_CODES.SET_RX_CONFIG
          state.rxConfig = Array.from bytes.subarray 8, 8 + RX_CONFIG_BYTES
          state.rxConfig[0] += 1
          return { command, direction: '>', payload: [] }
        receiverResponder(state)(bytes)
    }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeRxConfig { provider: 7 }).rejects.toThrow(
      'RX configuration read-back failed: provider'
    )

  it 'writes the channel map and refreshes the telemetry mapping', ->
    state = receiverState()
    { transport, session } = await openResponderSession state
    newMap = [0, 1, 2, 3, 4, 5, 6, 7]
    await session.writeRxMap newMap
    expect(session.rxMap).toEqual newMap
    expect(session.identity.rxMap).toEqual newMap
    writes = transport.writes.filter (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.SET_RX_MAP
    expect(writes).toHaveLength 1
    await expect(session.writeRxMap [0, 1]).rejects.toThrow(
      '8 channel positions'
    )

  it 'writes failsafe slots and tolerates a shorter read-back', ->
    state = receiverState()
    { session } = await openResponderSession state
    result = await session.writeRxFailChannel 2, { mode: 2, value: 1200 }
    expect(result.channel).toEqual { index: 2, mode: 2, value: 1200 }
    # Index beyond the firmware's channelCount passes silently.
    beyond = await session.writeRxFailChannel 10, { mode: 2, value: 1200 }
    expect(beyond.channel).toBeUndefined()
    await expect(session.writeRxFailChannel 18, {}).rejects.toThrow(
      'RX fail channel index out of range'
    )

  it 'reads mode ranges with optional extras', ->
    state = receiverState()
    state.modeRanges[1] = [28, 5, 10, 20, 1, 36]
    script = {
      handshakeScript...
      [MSP_CODES.MODE_RANGES]: modeRangesPayload state.modeRanges
      [MSP_CODES.MODE_RANGES_EXTRA]: modeRangesExtraPayload state.modeRanges
    }
    { session } = await openSession script
    await session.handshake()
    { ranges, extras } = await session.readModeRanges()
    expect(ranges).toHaveLength 20
    expect(ranges[1]).toEqual {
      index: 1, permanentId: 28, auxChannelIndex: 5, startStep: 10, endStep: 20
    }
    expect(extras[1]).toEqual {
      index: 1, permanentId: 28, modeLogic: 1, linkedToPermId: 36
    }

  it 'degrades when extras are unsupported', ->
    state = receiverState()
    script = {
      handshakeScript...
      [MSP_CODES.MODE_RANGES]: modeRangesPayload state.modeRanges
      [MSP_CODES.MODE_RANGES_EXTRA]: 'unsupported'
    }
    { session } = await openSession script
    await session.handshake()
    { ranges, extras } = await session.readModeRanges()
    expect(ranges).toHaveLength 20
    expect(extras).toBe null

  it 'writes a mode range and clamps linkedTo 255 to neutral', ->
    state = receiverState()
    { transport, session } = await openResponderSession state
    await session.writeModeRange 1, {
      permanentId: 28, auxChannelIndex: 5
      startStep: 10, endStep: 20
      modeLogic: 1, linkedToPermId: 255
    }
    writes = transport.writes.filter (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.SET_MODE_RANGE
    expect(writes).toHaveLength 1
    expect(writes[0].slice 8, 15).toEqual [1, 28, 5, 10, 20, 1, 0]
    expect(state.modeRanges[1]).toEqual [28, 5, 10, 20, 1, 0]

  it 'rejects invalid mode-range writes', ->
    state = receiverState()
    { session } = await openResponderSession state
    await expect(session.writeModeRange 20, {}).rejects.toThrow(
      'Mode range index out of range'
    )
    await expect(session.writeModeRange 0, {
      permanentId: 255
    }).rejects.toThrow 'Mode range permanentId missing or invalid'

  it 'throws when a mode-range read-back diverges', ->
    state = receiverState()
    transport = new MockMspTransport {
      autoRespond: true
      responder: (bytes) ->
        command = bytes[4] | bytes[5] << 8
        if command == MSP_CODES.SET_MODE_RANGE
          state.modeRanges[bytes[8]] = Array.from bytes.subarray 8, 15
          state.modeRanges[bytes[8]][3] = 99
          return { command, direction: '>', payload: [] }
        receiverResponder(state)(bytes)
    }
    client = new MspClient transport, { timeoutMs: 500 }
    await client.open()
    session = new OrniFlightSession client
    await session.handshake()
    await expect(session.writeModeRange 1, {
      permanentId: 28, auxChannelIndex: 5, startStep: 10, endStep: 20
    }).rejects.toThrow 'Mode range read-back failed at index 1'

  it 'reads box ids and names', ->
    script = {
      handshakeScript...
      [MSP_CODES.BOXIDS]: [0, 27, 28]
      [MSP_CODES.BOXNAMES]: [3, asciiBytes('ARM;ANGLE;HORIZON')...]
    }
    { session } = await openSession script
    await session.handshake()
    expect(await session.readBoxIds()).toEqual [0, 27, 28]
    expect(await session.readBoxIds(1)).toEqual [0, 27, 28]
    expect(await session.readBoxNames()).toEqual ['ARM', 'ANGLE', 'HORIZON']

  it 'refuses receiver and modes writes while armed', ->
    state = receiverState()
    { session } = await openResponderSession state
    session.lastStatus.armed = true
    await expect(session.writeRxConfig { provider: 7 }).rejects.toThrow(
      'Cannot write configuration while armed'
    )
    await expect(session.writeRxMap [0, 1, 3, 2, 4, 5, 6, 7]).rejects.toThrow(
      'Cannot write configuration while armed'
    )
    await expect(session.writeRxFailChannel 0, {}).rejects.toThrow(
      'Cannot write configuration while armed'
    )
    await expect(session.writeModeRange 0, {
      permanentId: 28
    }).rejects.toThrow 'Cannot write configuration while armed'