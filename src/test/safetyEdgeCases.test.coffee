import { describe, it, expect } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient from '../protocol/mspClient.coffee'
import OrniFlightSession from '../protocol/orniFlightSession.coffee'
import { MockMspTransport, scriptedResponder } from './mockMspTransport.coffee'
import {
  encodeFailsafeConfig, decodeFailsafeConfig, FAILSAFE_CONFIG_BYTES
  encodeArmingConfig, decodeArmingConfig, ARMING_CONFIG_BYTES
  encodeFeatureConfig, decodeFeatureConfig, FEATURE_CONFIG_BYTES
  encodeBeeperConfig, decodeBeeperConfig, BEEPER_CONFIG_BYTES
} from '../protocol/mspDecoders.coffee'
import {
  FAILSAFE_THROTTLE_MIN, FAILSAFE_THROTTLE_MAX
  FAILSAFE_PROCEDURE_COUNT, FAILSAFE_SWITCH_MODE_COUNT
  ARMING_SMALL_ANGLE_MAX
  FEATURE_SUPPORTED_MASK, DEFAULT_FEATURE_MASK
  BEEPER_OFF_FLAGS_MASK, DSHOT_BEACON_ALLOWED_FLAGS
  sanitizeFailsafe, sanitizeArming, sanitizeFeatures, sanitizeBeeper
} from '../lib/safetyCatalog.coffee'
import useSafetyStore from '../stores/useSafetyStore.coffee'

state = -> useSafetyStore.getState()

u16 = (value) -> [value & 0xff, value >>> 8 & 0xff]
u32 = (value) ->
  [value & 0xff, value >>> 8 & 0xff, value >>> 16 & 0xff, value >>> 24 & 0xff]

# ?????????????? Sanitizer boundaries ??????????????????????????????????????????????????????????????????????????????????????
describe 'safety sanitizer boundaries', ->
  it 'clamps failsafe throttle into the 1000..2000 window', ->
    expect(sanitizeFailsafe(throttle: 999).throttle).toBe FAILSAFE_THROTTLE_MIN
    expect(sanitizeFailsafe(throttle: 1000).throttle).toBe FAILSAFE_THROTTLE_MIN
    expect(sanitizeFailsafe(throttle: 2000).throttle).toBe FAILSAFE_THROTTLE_MAX
    expect(sanitizeFailsafe(throttle: 2001).throttle).toBe FAILSAFE_THROTTLE_MAX
    expect(sanitizeFailsafe(throttle: -100).throttle).toBe FAILSAFE_THROTTLE_MIN

  it 'collapses non-finite failsafe fields to their floor', ->
    expect(sanitizeFailsafe(throttle: NaN).throttle).toBe FAILSAFE_THROTTLE_MIN
    expect(sanitizeFailsafe(throttle: Infinity).throttle).toBe FAILSAFE_THROTTLE_MIN
    expect(sanitizeFailsafe(throttle: null).throttle).toBe 1000
    expect(sanitizeFailsafe(delay: NaN).delay).toBe 0
    expect(sanitizeFailsafe(delay: Infinity).delay).toBe 0

  it 'clamps u8 failsafe fields to 0..255', ->
    expect(sanitizeFailsafe(delay: -1).delay).toBe 0
    expect(sanitizeFailsafe(delay: 256).delay).toBe 255
    expect(sanitizeFailsafe(offDelay: 300).offDelay).toBe 255
    expect(sanitizeFailsafe(throttleLowDelay: 65535).throttleLowDelay).toBe 65535
    expect(sanitizeFailsafe(throttleLowDelay: 65536).throttleLowDelay).toBe 65535

  it 'clamps failsafe enums to their valid ids', ->
    expect(sanitizeFailsafe(procedure: -1).procedure).toBe 0
    expect(sanitizeFailsafe(procedure: FAILSAFE_PROCEDURE_COUNT - 1).procedure)
      .toBe FAILSAFE_PROCEDURE_COUNT - 1
    expect(sanitizeFailsafe(procedure: FAILSAFE_PROCEDURE_COUNT).procedure)
      .toBe FAILSAFE_PROCEDURE_COUNT - 1
    expect(sanitizeFailsafe(switchMode: 99).switchMode)
      .toBe FAILSAFE_SWITCH_MODE_COUNT - 1
    expect(sanitizeFailsafe(switchMode: -5).switchMode).toBe 0

  it 'clamps arming fields to their firmware windows', ->
    expect(sanitizeArming(smallAngle: -1).smallAngle).toBe 0
    expect(sanitizeArming(smallAngle: 180).smallAngle).toBe ARMING_SMALL_ANGLE_MAX
    expect(sanitizeArming(smallAngle: 181).smallAngle).toBe ARMING_SMALL_ANGLE_MAX
    expect(sanitizeArming(autoDisarmDelay: 256).autoDisarmDelay).toBe 255
    expect(sanitizeArming(autoDisarmDelay: NaN).autoDisarmDelay).toBe 0

  it 'masks feature bits to the supported set', ->
    expect(sanitizeFeatures 0).toBe 0
    expect(sanitizeFeatures FEATURE_SUPPORTED_MASK).toBe FEATURE_SUPPORTED_MASK
    expect(sanitizeFeatures 0xFFFFFFFF).toBe FEATURE_SUPPORTED_MASK
    expect(sanitizeFeatures -1).toBe FEATURE_SUPPORTED_MASK
    expect(sanitizeFeatures NaN).toBe 0
    # bit 31 is outside the ornithopter feature map.
    expect(sanitizeFeatures 1 << 31).toBe 0

  it 'masks beeper off-flags to 0..24 and beacon flags to the two', ->
    expect(sanitizeBeeper(offFlags: -1).offFlags).toBe BEEPER_OFF_FLAGS_MASK
    expect(sanitizeBeeper(offFlags: 0xFFFFFFFF).offFlags).toBe BEEPER_OFF_FLAGS_MASK
    expect(sanitizeBeeper(offFlags: 0).offFlags).toBe 0
    expect(sanitizeBeeper(dshotBeaconOffFlags: 0xFF).dshotBeaconOffFlags).toBe 2
    expect(sanitizeBeeper(dshotBeaconOffFlags: -1).dshotBeaconOffFlags)
      .toBe DSHOT_BEACON_ALLOWED_FLAGS

# ?????????????? Codec wire-width boundaries ??????????????????????????????????????????????????????????????????????????????????????
describe 'safety codec wire-width boundaries', ->
  it 'round-trips the failsafe record at every extreme', ->
    config = {
      delay: 255, offDelay: 255, throttle: 2000
      switchMode: 2, throttleLowDelay: 65535, procedure: 2
    }
    payload = encodeFailsafeConfig config
    expect(payload.length).toBe FAILSAFE_CONFIG_BYTES
    expect(decodeFailsafeConfig payload).toEqual config

  it 'round-trips the arming record at its extremes', ->
    config = { autoDisarmDelay: 255, smallAngle: 180 }
    payload = encodeArmingConfig config
    expect(payload.length).toBe ARMING_CONFIG_BYTES
    expect(decodeArmingConfig payload).toEqual config

  it 'round-trips the full and empty feature masks', ->
    expect(decodeFeatureConfig encodeFeatureConfig(FEATURE_SUPPORTED_MASK))
      .toBe FEATURE_SUPPORTED_MASK
    expect(decodeFeatureConfig encodeFeatureConfig(0)).toBe 0
    expect(decodeFeatureConfig encodeFeatureConfig(-1)).toBe 0xFFFFFFFF

  it 'round-trips the beeper record at its extremes', ->
    config = {
      offFlags: BEEPER_OFF_FLAGS_MASK
      dshotBeaconTone: 255
      dshotBeaconOffFlags: DSHOT_BEACON_ALLOWED_FLAGS
    }
    payload = encodeBeeperConfig config
    expect(payload.length).toBe BEEPER_CONFIG_BYTES
    expect(decodeBeeperConfig payload).toEqual config

  it 'clamps out-of-width fields instead of overflowing the DataView', ->
    expect(decodeFailsafeConfig(encodeFailsafeConfig(delay: 300)).delay).toBe 255
    expect(
      decodeArmingConfig(encodeArmingConfig(autoDisarmDelay: 300)).autoDisarmDelay
    ).toBe 255
    expect(decodeBeeperConfig(encodeBeeperConfig(dshotBeaconTone: 999))
      .dshotBeaconTone).toBe 255

# ?????????????? Store error scenarios ??????????????????????????????????????????????????????????????????????????????????????
makeSession = (initial = {}) ->
  stored = {
    failsafe: { delay: 4, offDelay: 10, throttle: 1000, switchMode: 0, throttleLowDelay: 100, procedure: 1 }
    arming: { autoDisarmDelay: 5, smallAngle: 25 }
    features: DEFAULT_FEATURE_MASK
    beeper: { offFlags: 0, dshotBeaconTone: 1, dshotBeaconOffFlags: DSHOT_BEACON_ALLOWED_FLAGS }
    initial...
  }
  {
    readFailsafeConfig: -> Promise.resolve stored.failsafe
    writeFailsafeConfig: (config) ->
      stored.failsafe = { config... }
      Promise.resolve { stored.failsafe... }
    readArmingConfig: -> Promise.resolve stored.arming
    writeArmingConfig: (config) ->
      stored.arming = { config... }
      Promise.resolve { stored.arming... }
    readFeatureConfig: -> Promise.resolve stored.features
    writeFeatureConfig: (mask) ->
      stored.features = mask
      Promise.resolve mask
    readBeeperConfig: -> Promise.resolve stored.beeper
    writeBeeperConfig: (config) ->
      stored.beeper = { config... }
      Promise.resolve { stored.beeper... }
  }

describe 'safety store error scenarios', ->
  beforeEach -> state().reset()

  it 'rejects an unknown mode', ->
    expect(-> state().setMode 'turbo').toThrow 'Unknown safety mode: turbo'

  it 'detaches to sim mode through a null session', ->
    state().attachSession makeSession()
    expect(state().mode).toBe 'device'
    state().attachSession null
    expect(state().mode).toBe 'sim'
    expect(state().session).toBe null

  it 'refuses to load without a session and records the failure', ->
    await expect(state().loadFromDevice null)
      .rejects.toThrow 'No device session attached'
    expect(state().lastError).toBe 'No device session attached'

  it 'refuses to save onto a foreign session after a read', ->
    first = makeSession()
    await state().loadFromDevice first
    state().attachSession makeSession()
    state().setFailsafe { delay: 9 }
    await expect(state().save())
      .rejects.toThrow 'Read device safety configuration before saving'

  it 'sanitises hostile masks through the public setters', ->
    state().setFeatures -1
    expect(state().draft.features).toBe FEATURE_SUPPORTED_MASK
    state().setFeatures NaN
    expect(state().draft.features).toBe 0
    state().setBeeper { offFlags: 0xFFFFFFFF }
    expect(state().draft.beeper.offFlags).toBe BEEPER_OFF_FLAGS_MASK
    state().setBeeper { dshotBeaconOffFlags: 0xFF }
    expect(state().draft.beeper.dshotBeaconOffFlags).toBe 2

# ?????????????? Session write guards ??????????????????????????????????????????????????????????????????????????????????????
asciiBytes = (text) -> Array.from(text).map (character) -> character.charCodeAt 0

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

# Stores SET_* payloads under the GET codes so the write methods'
# read-back verification sees the stored values, and swallows EEPROM_WRITE.
safetyWriteResponder = (script = {}) ->
  stored = {}
  fallback = scriptedResponder { handshakeScript..., script... }
  writeToRead = {
    [MSP_CODES.SET_FAILSAFE_CONFIG]: MSP_CODES.FAILSAFE_CONFIG
    [MSP_CODES.SET_ARMING_CONFIG]: MSP_CODES.ARMING_CONFIG
    [MSP_CODES.SET_FEATURE_CONFIG]: MSP_CODES.FEATURE_CONFIG
    [MSP_CODES.SET_BEEPER_CONFIG]: MSP_CODES.BEEPER_CONFIG
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

openSession = (script, responder = scriptedResponder script) ->
  transport = new MockMspTransport { autoRespond: true, responder }
  client = new MspClient transport, { timeoutMs: 500 }
  await client.open()
  session = new OrniFlightSession client
  await session.handshake()
  { transport, client, session }

describe 'safety session write guards', ->
  it 'emits SET + EEPROM_WRITE + read-back for each safety document', ->
    { session, transport } = await openSession handshakeScript, safetyWriteResponder()
    await session.writeFailsafeConfig { delay: 6 }
    await session.writeArmingConfig { autoDisarmDelay: 7 }
    await session.writeFeatureConfig DEFAULT_FEATURE_MASK | (1 << 18)
    await session.writeBeeperConfig { offFlags: 1 }
    commands = transport.writes.map (bytes) -> bytes[4] | bytes[5] << 8
    expect(commands).toContain MSP_CODES.SET_FAILSAFE_CONFIG
    expect(commands).toContain MSP_CODES.SET_ARMING_CONFIG
    expect(commands).toContain MSP_CODES.SET_FEATURE_CONFIG
    expect(commands).toContain MSP_CODES.SET_BEEPER_CONFIG
    expect(
      commands.filter((command) -> command == MSP_CODES.EEPROM_WRITE).length
    ).toBe 4

  it 'emits the full 9-byte beeper record even for a partial config', ->
    { session, transport } = await openSession handshakeScript, safetyWriteResponder()
    await session.writeBeeperConfig { offFlags: 4 }
    write = transport.writes.find (bytes) ->
      (bytes[4] | bytes[5] << 8) == MSP_CODES.SET_BEEPER_CONFIG
    expect(write[6] | write[7] << 8).toBe BEEPER_CONFIG_BYTES

  it 'refuses every safety write while armed', ->
    { session } = await openSession handshakeScript, safetyWriteResponder()
    session.lastStatus.armed = true
    for write in [
      session.writeFailsafeConfig { delay: 6 }
      session.writeArmingConfig { autoDisarmDelay: 7 }
      session.writeFeatureConfig 0
      session.writeBeeperConfig { offFlags: 1 }
    ]
      await expect(write).rejects.toThrow 'Cannot write configuration while armed'

  it 'throws when the failsafe read-back diverges', ->
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      return { command, direction: '>', payload: [] } if command == MSP_CODES.SET_FAILSAFE_CONFIG
      return { command, direction: '>', payload: [] } if command == MSP_CODES.EEPROM_WRITE
      if command == MSP_CODES.FAILSAFE_CONFIG
        return { command, direction: '>', payload: [1, 1, 1, 1, 0, 1, 0, 0] }
      scriptedResponder(handshakeScript) bytes
    { session } = await openSession handshakeScript, responder
    await expect(session.writeFailsafeConfig { delay: 6 })
      .rejects.toThrow 'Failsafe configuration read-back mismatch'

  it 'throws when the feature read-back diverges', ->
    responder = (bytes) ->
      command = bytes[4] | bytes[5] << 8
      return { command, direction: '>', payload: [] } if command == MSP_CODES.SET_FEATURE_CONFIG
      return { command, direction: '>', payload: [] } if command == MSP_CODES.EEPROM_WRITE
      if command == MSP_CODES.FEATURE_CONFIG
        return { command, direction: '>', payload: u32 DEFAULT_FEATURE_MASK }
      scriptedResponder(handshakeScript) bytes
    { session } = await openSession handshakeScript, responder
    await expect(session.writeFeatureConfig DEFAULT_FEATURE_MASK | (1 << 18))
      .rejects.toThrow 'Feature configuration read-back mismatch'