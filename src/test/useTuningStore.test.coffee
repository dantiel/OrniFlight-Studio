import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { engine } from '../simulation/engine.coffee'
import useTuningStore, {
  TUNING_DEFAULTS
} from '../stores/useTuningStore.coffee'

state = -> useTuningStore.getState()

describe 'useTuningStore', ->
  beforeEach ->
    state().reset()
    vi.spyOn engine, 'setPidGain'
    vi.spyOn engine, 'setOndasParam'
    # Explicit return: a beforeEach that returns a function registers it
    # as a cleanup hook — never leak the spy (it would be invoked
    # detached with `this` undefined and crash the original method).
    return

  afterEach ->
    vi.restoreAllMocks()

  it 'starts in sim mode with defaults and no dirty flag', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.pid.roll).toEqual { P: 4.0, I: 0.03, D: 23.0 }
    expect(state().draft.rate).toEqual { rcRate: 100, superRate: 0, expo: 0 }
    expect(state().draft.ondas).toEqual TUNING_DEFAULTS.ondas
    expect(state().draft.filter.gyroNotchQ).toBe 0

  it 'updates nested draft paths and marks the document dirty', ->
    state().setField 'pid.roll.P', 5.5
    expect(state().draft.pid.roll.P).toBe 5.5
    expect(state().dirty).toBe true

  it 'mirrors pid and ondas edits into the engine', ->
    state().setField 'pid.roll.P', 5.5
    expect(engine.setPidGain).toHaveBeenCalledWith 'roll_P', 5.5
    state().setField 'ondas.cadence_gain', 42
    expect(engine.setOndasParam).toHaveBeenCalledWith 'cadence_gain', 42

  it 'mirrors all nine engine gains but excludes the flap axis', ->
    state().setField 'pid.roll.P', 1
    expect(engine.setPidGain).toHaveBeenCalledTimes 9
    expect(engine.setPidGain).not.toHaveBeenCalledWith(
      'flap_P', expect.anything()
    )

  it 'mirrors all ten ondas params on a draft edit', ->
    state().setField 'pid.roll.P', 1
    expect(engine.setOndasParam).toHaveBeenCalledTimes 10
    expect(engine.setOndasParam).toHaveBeenCalledWith 'anchor_gain', 50

  it 'does not mirror rate or filter edits into the engine', ->
    state().setField 'rate.rcRate', 120
    state().setField 'filter.gyroNotchQ', 8
    expect(engine.setPidGain).not.toHaveBeenCalled()
    expect(engine.setOndasParam).not.toHaveBeenCalled()
    expect(state().draft.rate.rcRate).toBe 120
    expect(state().draft.filter.gyroNotchQ).toBe 8

  it 'guards pid fields against non-finite values', ->
    state().setField 'pid.pitch.I', NaN
    expect(state().draft.pid.pitch.I).toBe 0.04
    state().setField 'pid.yaw.D', Infinity
    expect(state().draft.pid.yaw.D).toBe 0

  it 'preserves finite zero pid values', ->
    state().setField 'pid.yaw.D', 0
    expect(state().draft.pid.yaw.D).toBe 0
    expect(state().dirty).toBe true

  it 'clamps rate fields to their documented ranges', ->
    state().setField 'rate.rcRate', 500
    expect(state().draft.rate.rcRate).toBe 250
    state().setField 'rate.superRate', -10
    expect(state().draft.rate.superRate).toBe 0
    state().setField 'rate.expo', 120
    expect(state().draft.rate.expo).toBe 100

  it 'clamps ondas params to 0..100', ->
    state().setField 'ondas.warp_gain', 150
    expect(state().draft.ondas.warp_gain).toBe 100
    state().setField 'ondas.balance_gain', -5
    expect(state().draft.ondas.balance_gain).toBe 0

  it 'clamps filter fields to their documented ranges', ->
    state().setField 'filter.gyroDlpfHz', 100000
    expect(state().draft.filter.gyroDlpfHz).toBe 65535
    state().setField 'filter.gyroNotchQ', 99
    expect(state().draft.filter.gyroNotchQ).toBe 16

  it 'rejects prototype-pollution paths', ->
    state().setField '__proto__.polluted', 'YES'
    state().setField 'pid.constructor.polluted', 'YES'
    state().setField 'ondas.prototype.polluted', 'YES'
    expect(Object.prototype.polluted).toBeUndefined()
    expect(state().dirty).toBe false

  it 'ignores descents through primitive leaves', ->
    state().setField 'pid.roll.P.sub', 5
    expect(state().dirty).toBe false
    expect(state().draft.pid.roll.P).toBe 4.0

  it 'reverts the draft to the last saved document', ->
    state().setField 'pid.roll.P', 9
    await state().save()
    state().setField 'pid.roll.P', 10
    state().revert()
    expect(state().draft.pid.roll.P).toBe 9
    expect(state().dirty).toBe false

  it 'commits the draft on save in sim mode', ->
    state().setField 'pid.roll.P', 5.5
    await state().save()
    expect(state().saved.pid.roll.P).toBe 5.5
    expect(state().dirty).toBe false

  it 'writes through the session on save in device mode', ->
    session = {
      readTuning: vi.fn(-> Promise.resolve TUNING_DEFAULTS)
      writeTuning: vi.fn((tuning) -> Promise.resolve tuning)
    }
    state().attachSession session
    expect(state().mode).toBe 'device'
    await state().loadFromDevice()
    state().setField 'pid.roll.P', 5.5
    await state().save()
    expect(session.writeTuning).toHaveBeenCalledTimes 1
    expect(state().saved.pid.roll.P).toBe 5.5
    expect(state().dirty).toBe false

  it 'refuses to save in device mode without a session', ->
    state().setMode 'device'
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'No device session attached'

  it 'records the failure message when a device save throws', ->
    session = {
      readTuning: vi.fn(-> Promise.resolve TUNING_DEFAULTS)
      writeTuning: vi.fn(-> Promise.reject new Error('read-back failed: pid'))
    }
    state().attachSession session
    await state().loadFromDevice()
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'read-back failed'
    expect(state().lastError).toContain 'read-back failed'

  it 'rejects unknown modes', ->
    expect((-> state().setMode 'auto')).toThrow 'Unknown tuning mode'

  it 'detaches to sim mode when the session clears', ->
    state().attachSession { writeTuning: (->) }
    expect(state().mode).toBe 'device'
    state().attachSession null
    expect(state().mode).toBe 'sim'
    expect(state().session).toBe null

  it 'loads tuning from the device session', ->
    read = {
      pid: { TUNING_DEFAULTS.pid..., roll: { P: 5.0, I: 0.03, D: 23.0 } }
      rate: { rcRate: 90, superRate: 10, expo: 5 }
      ondas: TUNING_DEFAULTS.ondas
      filter: {
        gyroDlpfHz: 200, gyroNotchHz: 300, gyroNotchQ: 4, dTermDlpfHz: 40
      }
    }
    session = { readTuning: vi.fn(-> Promise.resolve read) }
    result = await state().loadFromDevice session
    expect(result.pid.roll.P).toBe 5
    expect(state().mode).toBe 'device'
    expect(state().dirty).toBe false
    expect(state().saved.rate.rcRate).toBe 90
    expect(state().loadedSession).toBe session
    expect(engine.setPidGain).toHaveBeenCalledWith 'roll_P', 5

  it 'clamps pid gains to the wire-representable range', ->
    state().setField 'pid.roll.P', -5
    expect(state().draft.pid.roll.P).toBe 0
    state().setField 'pid.pitch.D', 200
    expect(state().draft.pid.pitch.D).toBe 65.535
    state().setField 'pid.yaw.I', 1000
    expect(state().draft.pid.yaw.I).toBe 65.535

  it 'writes clamped pid gains through the device session', ->
    session = {
      readTuning: vi.fn(-> Promise.resolve TUNING_DEFAULTS)
      writeTuning: vi.fn((tuning) -> Promise.resolve tuning)
    }
    state().attachSession session
    await state().loadFromDevice()
    state().setField 'pid.roll.P', 200
    await state().save()
    expect(session.writeTuning).toHaveBeenCalledTimes 1
    expect(state().saved.pid.roll.P).toBe 65.535
    expect(state().dirty).toBe false

  it 'refuses to save on a device before reading its tuning', ->
    session = { writeTuning: vi.fn((tuning) -> Promise.resolve tuning) }
    state().attachSession session
    state().setField 'pid.roll.P', 5
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'Read device tuning before saving'
    expect(session.writeTuning).not.toHaveBeenCalled()
    expect(state().dirty).toBe true
    expect(state().lastError).toContain 'Read device tuning before saving'

  it 'records the failure message when a device read throws', ->
    session = {
      readTuning: vi.fn(-> Promise.reject new Error('MSP timeout'))
    }
    state().attachSession session
    error = await state().loadFromDevice().catch (error) -> error
    expect(error.message).toContain 'MSP timeout'
    expect(state().lastError).toContain 'MSP timeout'
