import { describe, it, expect, vi } from 'vitest'
import useSafetyStore from '../stores/useSafetyStore.coffee'
import {
  DEFAULT_FAILSAFE_CONFIG, DEFAULT_ARMING_CONFIG
  DEFAULT_FEATURE_MASK, DEFAULT_BEEPER_CONFIG
  BEEPER_ALL_FLAG
} from '../lib/safetyCatalog.coffee'

state = -> useSafetyStore.getState()

makeSession = (initial = {}) ->
  stored = {
    failsafe: { DEFAULT_FAILSAFE_CONFIG... }
    arming: { DEFAULT_ARMING_CONFIG... }
    features: DEFAULT_FEATURE_MASK
    beeper: { DEFAULT_BEEPER_CONFIG... }
    initial...
  }
  {
    readFailsafeConfig: vi.fn -> Promise.resolve stored.failsafe
    writeFailsafeConfig: vi.fn (config) ->
      stored.failsafe = { config... }
      Promise.resolve { stored.failsafe... }
    readArmingConfig: vi.fn -> Promise.resolve stored.arming
    writeArmingConfig: vi.fn (config) ->
      stored.arming = { config... }
      Promise.resolve { stored.arming... }
    readFeatureConfig: vi.fn -> Promise.resolve stored.features
    writeFeatureConfig: vi.fn (mask) ->
      stored.features = mask
      Promise.resolve mask
    readBeeperConfig: vi.fn -> Promise.resolve stored.beeper
    writeBeeperConfig: vi.fn (config) ->
      stored.beeper = { config... }
      Promise.resolve { stored.beeper... }
  }

describe 'useSafetyStore', ->
  beforeEach -> state().reset()

  it 'starts in sim mode with the compound firmware defaults', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft).toEqual {
      failsafe: DEFAULT_FAILSAFE_CONFIG
      arming: DEFAULT_ARMING_CONFIG
      features: DEFAULT_FEATURE_MASK
      beeper: DEFAULT_BEEPER_CONFIG
    }

  it 'patches the failsafe sub-document with clamping', ->
    state().setFailsafe { throttle: 9999, procedure: 99 }
    expect(state().draft.failsafe.throttle).toBe 2000
    expect(state().draft.failsafe.procedure).toBe 2
    expect(state().dirty).toBe true

  it 'patches the arming sub-document and keeps its neighbours', ->
    state().setArming { smallAngle: 180 }
    expect(state().draft.arming.smallAngle).toBe 180
    expect(state().draft.arming.autoDisarmDelay).toBe 5

  it 'toggles feature bits against the absolute mask', ->
    state().setFeatureBit 1 << 18, true
    expect(state().draft.features & (1 << 18)).toBeTruthy()
    expect(state().dirty).toBe true
    state().setFeatureBit 1 << 18, false
    expect(state().draft.features & (1 << 18)).toBe 0
    expect(state().draft.features).toBe DEFAULT_FEATURE_MASK

  it 'mutes and unmutes beeper conditions', ->
    state().setBeeperMode 5, false
    expect(state().draft.beeper.offFlags & (1 << 4)).toBeTruthy()
    state().setBeeperMode 5, true
    expect(state().draft.beeper.offFlags).toBe 0

  it 'toggles the silence-all sentinel bit', ->
    state().setBeeperMode 25, false
    expect(state().draft.beeper.offFlags & BEEPER_ALL_FLAG)
      .toBeTruthy()

  it 'toggles DShot beacon silence independently of offFlags', ->
    state().setBeeperBeaconMode 2, false
    expect(state().draft.beeper.dshotBeaconOffFlags & 2).toBe 2
    expect(state().draft.beeper.offFlags).toBe 0
    state().setBeeperBeaconMode 2, true
    # RX_LOST unmutes; RX_SET stays muted → 514 & ~2 = 512.
    expect(state().draft.beeper.dshotBeaconOffFlags).toBe 512

  it 'saves locally in sim mode (dry-run)', ->
    state().setFailsafe { delay: 9 }
    saved = await state().save()
    expect(saved.failsafe.delay).toBe 9
    expect(state().dirty).toBe false
    expect(state().saved.failsafe.delay).toBe 9

  it 'reverts to the saved document', ->
    state().setFailsafe { delay: 9 }
    state().revert()
    expect(state().draft.failsafe.delay).toBe 4
    expect(state().dirty).toBe false

  it 'loads all four documents from a device session and pins it', ->
    double = makeSession failsafe: { DEFAULT_FAILSAFE_CONFIG..., delay: 6 }
    draft = await state().loadFromDevice double
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe double
    expect(draft.failsafe.delay).toBe 6
    expect(state().dirty).toBe false

  it 'saves the whole compound through the session with read-backs', ->
    double = makeSession()
    await state().loadFromDevice double
    state().setFailsafe { throttle: 1150 }
    state().setFeatures DEFAULT_FEATURE_MASK | (1 << 18)
    saved = await state().save()
    expect(saved.failsafe.throttle).toBe 1150
    expect(saved.features & (1 << 18)).toBeTruthy()
    expect(double.writeFailsafeConfig).toHaveBeenCalledTimes 1
    expect(double.writeArmingConfig).toHaveBeenCalledTimes 1
    expect(double.writeFeatureConfig).toHaveBeenCalledTimes 1
    expect(double.writeBeeperConfig).toHaveBeenCalledTimes 1
    expect(state().dirty).toBe false
    expect(state().saved.failsafe.throttle).toBe 1150

  it 'refuses to save on device before reading', ->
    double = makeSession()
    state().attachSession double
    state().setFailsafe { delay: 9 }
    await expect(state().save())
      .rejects.toThrow 'Read device safety configuration before saving'
    expect(state().lastError)
      .toBe 'Read device safety configuration before saving'

  it 'falls back to defaults for documents the device omits', ->
    double = makeSession()
    double.readFailsafeConfig = vi.fn -> Promise.resolve null
    double.readFeatureConfig = vi.fn -> Promise.resolve null
    draft = await state().loadFromDevice double
    expect(draft.failsafe.delay).toBe DEFAULT_FAILSAFE_CONFIG.delay
    expect(draft.features).toBe DEFAULT_FEATURE_MASK
    expect(draft.beeper.offFlags).toBe DEFAULT_BEEPER_CONFIG.offFlags

  it 'surfaces session write errors and keeps the draft dirty', ->
    double = makeSession()
    await state().loadFromDevice double
    double.writeFailsafeConfig = vi.fn ->
      throw new Error 'Cannot write configuration while armed'
    state().setFailsafe { delay: 9 }
    await expect(state().save())
      .rejects.toThrow 'Cannot write configuration while armed'
    expect(state().lastError)
      .toBe 'Cannot write configuration while armed'
    expect(state().dirty).toBe true