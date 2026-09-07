import { describe, it, expect, beforeEach } from 'vitest'
import useConfigurationStore, {
  AIRFRAME_DEFAULTS
} from '../stores/useConfigurationStore.coffee'
import { engine } from '../simulation/engine.coffee'

describe 'useConfigurationStore', ->
  store = useConfigurationStore
  state = -> store.getState()

  beforeEach ->
    state().reset()

  it 'starts in sim mode with a clean draft', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft).toEqual state().saved
    expect(state().draft.geometry.wingSpan).toBe(
      AIRFRAME_DEFAULTS.geometry.wingSpan
    )

  it 'sets nested fields and recomputes derived geometry', ->
    state().setField 'geometry.wingSpan', 1500
    draft = state().draft
    expect(draft.geometry.wingSpan).toBe 1500
    expect(draft.geometry.wingArea).toBe 1500 * 180
    expect(draft.geometry.aspectRatio).toBeCloseTo 1500 / 180
    expect(state().dirty).toBe true

  it 'sets mass and CG fields', ->
    state().setField 'mass.cgX', -25
    expect(state().draft.mass.cgX).toBe -25
    expect(state().draft.mass.totalMass).toBe 520

  it 'clamps pair count and normalizes servo mounts', ->
    state().setField 'pairCount', 3
    expect(state().draft.pairCount).toBe 3
    expect(state().draft.servoMounts).toHaveLength 3
    expect(state().draft.servoMounts[2].index).toBe 2
    state().setField 'pairCount', 99
    expect(state().draft.pairCount).toBe 4
    state().setField 'pairCount', 0
    expect(state().draft.pairCount).toBe 1

  it 'edits servo mount fields by dotted path', ->
    state().setField 'servoMounts.0.angle', 12
    expect(state().draft.servoMounts[0].angle).toBe 12
    expect(state().draft.servoMounts[1].angle).toBe 0

  it 'revert restores the last saved draft', ->
    state().setField 'geometry.wingSpan', 1500
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft).toEqual state().saved
    expect(state().draft.geometry.wingSpan).toBe 1200

  it 'save commits the draft locally in sim mode', ->
    state().setField 'geometry.chord', 200
    await state().save()
    expect(state().dirty).toBe false
    expect(state().saved.geometry.chord).toBe 200
    state().revert()
    expect(state().draft.geometry.chord).toBe 200

  it 'mirrors draft edits into the engine preview', ->
    state().setField 'geometry.wingSpan', 1500
    expect(engine.geometry.wingSpan).toBe 1500
    expect(engine.geometry.wingArea).toBe 1500 * 180
    expect(engine.mass.totalMass).toBe 520

  it 'mirrors pair count and mounts into the engine', ->
    state().setField 'pairCount', 3
    state().setField 'servoMounts.2.z', 40
    expect(engine.pairCount).toBe 3
    expect(engine.servoMounts).toHaveLength 3
    expect(engine.servoMounts[2].z).toBe 40

  it 'rejects unknown modes', ->
    expect((-> state().setMode 'astral')).toThrow(
      'Unknown configuration mode'
    )

  it 'throws when saving in device mode without a session', ->
    state().setMode 'device'
    await expect(state().save()).rejects.toThrow 'No device session'

  it 'writes servo configurations through the session in device mode', ->
    writes = []
    session = {
      writeServoConfiguration: (index, config) ->
        writes.push { index, config }
        Promise.resolve { index, config }
    }
    state().setMode 'device'
    state().attachSession session
    configs = [
      { min: 1100, max: 1900, middle: 1520, rate: 90 }
      { min: 1000, max: 2000, middle: 1500, rate: 100 }
    ]
    await state().save configs
    expect(writes).toHaveLength 2
    expect(writes[0].index).toBe 0
    expect(writes[0].config.min).toBe 1100
    expect(state().dirty).toBe false

  it 'loads servo configurations from the device', ->
    configs = [{
      index: 0, min: 1050, max: 1950, middle: 1510, rate: 80
      angleAtMin: 30, angleAtMax: 50
      forwardFromChannel: 0, reversedSources: 0
    }]
    session = {
      readServoConfigurations: -> Promise.resolve configs
      writeServoConfiguration: -> Promise.resolve null
    }
    draft = await state().loadFromDevice session
    expect(state().mode).toBe 'device'
    expect(draft.servos).toEqual configs
    expect(state().dirty).toBe false

  it 'falls back to defaults when the device has no servo configs', ->
    session = {
      readServoConfigurations: -> Promise.resolve []
      writeServoConfiguration: -> Promise.resolve null
    }
    draft = await state().loadFromDevice session
    expect(draft.servos).toHaveLength 4

  it 'detaching the session preserves the draft', ->
    state().setMode 'device'
    state().attachSession {
      readServoConfigurations: -> Promise.resolve []
      writeServoConfiguration: -> Promise.resolve null
    }
    state().setField 'geometry.wingSpan', 1400
    state().attachSession null
    expect(state().session).toBeNull()
    expect(state().mode).toBe 'device'
    expect(state().draft.geometry.wingSpan).toBe 1400
    expect(state().dirty).toBe true

  # ── Purificatio: edge cases / impurities ─────────────────────

  it 'clamps a non-finite pair count to the lower bound', ->
    state().setField 'pairCount', NaN
    expect(state().draft.pairCount).toBe 1
    expect(state().draft.servoMounts).toHaveLength 1
    state().setField 'pairCount', Infinity
    expect(state().draft.pairCount).toBe 1

  it 'guards mass fields against non-finite values', ->
    state().setField 'mass.totalMass', NaN
    expect(state().draft.mass.totalMass).toBe 520
    expect(engine.mass.totalMass).toBe 520
    state().setField 'mass.cgX', Infinity
    expect(state().draft.mass.cgX).toBe 0

  it 'preserves a finite zero in mass and CG fields', ->
    state().setField 'mass.totalMass', 0
    state().setField 'mass.cgX', 0
    expect(state().draft.mass.totalMass).toBe 0
    expect(state().draft.mass.cgX).toBe 0

  it 'ignores empty and malformed field paths', ->
    state().setField '', 'stray'
    state().setField 'geometry.', 'stray'
    expect(state().draft['']).toBeUndefined()
    expect(state().draft.geometry['']).toBeUndefined()
    expect(state().dirty).toBe false

  it 'guards servo mount fields against non-finite values', ->
    state().setField 'servoMounts.0.x', Infinity
    state().setField 'servoMounts.0.z', NaN
    state().setField 'servoMounts.0.angle', Infinity
    expect(state().draft.servoMounts[0].x).toBe 0
    expect(state().draft.servoMounts[0].z).toBe 0
    expect(state().draft.servoMounts[0].angle).toBe 0
    expect(engine.servoMounts[0].x).toBe 0

  it 'rejects prototype-pollution paths', ->
    state().reset()
    state().setField '__proto__.polluted', 'YES'
    state().setField 'constructor.prototype.polluted', 'YES'
    state().setField 'servos.__proto__.pollutedArr', 'YES'
    state().setField 'geometry.__proto__.sub', 'YES'
    expect(Object.prototype.polluted).toBeUndefined()
    expect(Array.prototype.pollutedArr).toBeUndefined()
    expect(state().dirty).toBe false

  it 'ignores descents through primitive leaves', ->
    state().setField 'mass.totalMass.sub', 5
    state().setField 'pairCount.deep', 9
    expect(state().dirty).toBe false
    expect(state().draft.mass.totalMass).toBe 520
    expect(state().draft.pairCount).toBe 2