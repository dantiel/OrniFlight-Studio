import { describe, it, expect } from 'vitest'
import {
  decodeFailsafeConfig, encodeFailsafeConfig, FAILSAFE_CONFIG_BYTES
  decodeArmingConfig, encodeArmingConfig, ARMING_CONFIG_BYTES
  decodeFeatureConfig, encodeFeatureConfig, FEATURE_CONFIG_BYTES
  decodeBeeperConfig, encodeBeeperConfig, BEEPER_CONFIG_BYTES
} from '../protocol/mspDecoders.coffee'
import {
  DEFAULT_FAILSAFE_CONFIG, DEFAULT_ARMING_CONFIG
  DEFAULT_FEATURE_MASK, DEFAULT_BEEPER_CONFIG
} from '../lib/safetyCatalog.coffee'

bytes = (list) -> Uint8Array.from list

describe 'safety codecs', ->
  it 'round-trips the failsafe 8-byte record field for field', ->
    config = {
      delay: 7, offDelay: 20, throttle: 1180
      switchMode: 2, throttleLowDelay: 250, procedure: 0
    }
    payload = encodeFailsafeConfig config
    expect(payload.length).toBe FAILSAFE_CONFIG_BYTES
    expect(decodeFailsafeConfig payload).toEqual config

  it 'emits the firmware failsafe wire layout byte for byte', ->
    payload = encodeFailsafeConfig DEFAULT_FAILSAFE_CONFIG
    # throttle 1000 = 0x03E8 LE at offset 2, lowDelay 100 at offset 5.
    expect(Array.from payload).toEqual [4, 10, 232, 3, 0, 100, 0, 1]

  it 'degrades a short failsafe payload onto firmware defaults', ->
    decoded = decodeFailsafeConfig bytes [4, 10]
    expect(decoded.delay).toBe 4
    expect(decoded.offDelay).toBe 10
    expect(decoded.throttle).toBe DEFAULT_FAILSAFE_CONFIG.throttle
    expect(decoded.procedure).toBe DEFAULT_FAILSAFE_CONFIG.procedure

  it 'encodes failsafe defaults when fields are omitted', ->
    payload = encodeFailsafeConfig {}
    expect(decodeFailsafeConfig payload).toEqual DEFAULT_FAILSAFE_CONFIG

  it 'round-trips the arming 3-byte record and skips the reserved byte', ->
    config = { autoDisarmDelay: 8, smallAngle: 60 }
    payload = encodeArmingConfig config
    expect(payload.length).toBe ARMING_CONFIG_BYTES
    expect(Array.from payload).toEqual [8, 0, 60]
    expect(decodeArmingConfig payload).toEqual config

  it 'falls back to firmware defaults for a 2-byte arming payload', ->
    decoded = decodeArmingConfig bytes [8, 0]
    expect(decoded.autoDisarmDelay).toBe 8
    expect(decoded.smallAngle).toBe DEFAULT_ARMING_CONFIG.smallAngle

  it 'round-trips the absolute feature mask as u32 LE', ->
    mask = (1 << 13) | (1 << 18) # RX_PARALLEL_PWM | OSD = 0x42000
    payload = encodeFeatureConfig mask
    expect(payload.length).toBe FEATURE_CONFIG_BYTES
    expect(Array.from payload).toEqual [0, 32, 4, 0]
    expect(decodeFeatureConfig payload).toBe mask

  it 'defaults the feature mask for an empty payload', ->
    expect(decodeFeatureConfig bytes []).toBe DEFAULT_FEATURE_MASK

  it 'round-trips the beeper 9-byte record', ->
    config = {
      offFlags: 0x0000FFFF, dshotBeaconTone: 4, dshotBeaconOffFlags: 2
    }
    payload = encodeBeeperConfig config
    expect(payload.length).toBe BEEPER_CONFIG_BYTES
    expect(decodeBeeperConfig payload).toEqual config

  it 'emits the firmware beeper defaults byte for byte', ->
    payload = encodeBeeperConfig {}
    # offFlags 0, tone 1, dshotBeaconOffFlags 514 = 0x0202 LE.
    expect(Array.from payload).toEqual [0, 0, 0, 0, 1, 2, 2, 0, 0]

  it 'decodes a 4-byte SET-sized payload onto firmware defaults', ->
    decoded = decodeBeeperConfig bytes [1, 0, 0, 0]
    expect(decoded.offFlags).toBe 1
    expect(decoded.dshotBeaconTone).toBe DEFAULT_BEEPER_CONFIG.dshotBeaconTone
    expect(decoded.dshotBeaconOffFlags)
      .toBe DEFAULT_BEEPER_CONFIG.dshotBeaconOffFlags
