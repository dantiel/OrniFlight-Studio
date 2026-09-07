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
