import { describe, it, expect, beforeEach } from 'vitest'
import useServoStore from '../stores/useServoStore.coffee'
import { engine } from '../simulation/engine.coffee'

describe 'useServoStore', ->
  store = useServoStore
  state = -> store.getState()

  beforeEach -> state().reset()

  it 'starts in sim mode with 8 servos and 16 mix rules', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.servos).toHaveLength 8
    expect(state().draft.mixRules).toHaveLength 16
    expect(state().draft.wing.servoMountAngle).toHaveLength 4

  it 'clamps servo PWM fields and mirrors into the engine', ->
    state().setServoField 0, 'min', 400
    state().setServoField 0, 'max', 3000
    state().setServoField 0, 'middle', 1520
    state().setServoField 0, 'rate', 90
    servo = state().draft.servos[0]
    expect(servo.min).toBe 500
    expect(servo.max).toBe 2500
    expect(servo.middle).toBe 1520
    expect(servo.rate).toBe 90
    expect(state().dirty).toBe true
    expect(engine.servos[0].min).toBe 500
    expect(engine.servos[0].max).toBe 2500
    expect(engine.servos[0].midpoint).toBe 1520
    expect(engine.servos[0].rate).toBe 90

  it 'clamps the glide degree', ->
    state().setGlide 200
    expect(state().draft.glide).toBe 90
    state().setGlide -200
    expect(state().draft.glide).toBe -90

  it 'clamps signed and unsigned mix rule fields', ->
    state().setMixRuleField 0, 'rate', 999
    expect(state().draft.mixRules[0].rate).toBe 125
    state().setMixRuleField 0, 'max', -50
    expect(state().draft.mixRules[0].max).toBe -50
    state().setMixRuleField 0, 'box', 42
    expect(state().draft.mixRules[0].box).toBe 42

  it 'clamps wing fields by their wire domain', ->
    state().setWingField 'warpGain', 500
    expect(state().draft.wing.warpGain).toBe 127
    state().setWingField 'anchorGain', 500
    expect(state().draft.wing.anchorGain).toBe 100
    state().setWingPairField 'servoMountAngle', 1, -300
    expect(state().draft.wing.servoMountAngle[1]).toBe -128

  it 'revert restores the last saved document', ->
    state().setGlide 30
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft.glide).toBe 0

  it 'save commits locally in sim mode without a session', ->
    state().setServoField 1, 'middle', 1480
    await state().save()
    expect(state().dirty).toBe false
    expect(state().saved.servos[1].middle).toBe 1480

  it 'rejects device writes before a device read', ->
    session = deviceSession {}
    state().setMode 'device'
    state().attachSession session
    await expect(state().save()).rejects.toThrow(
      'Read the device before writing'
    )

  it 'loads the servo document from the device', ->
    configs = [{
      index: 0, min: 1050, max: 1950, middle: 1510, rate: 80
      forwardFromChannel: 0, reversedSources: 0
    }]
    session = deviceSession {
      configs
      glide: 15
    }
    draft = await state().loadFromDevice session
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe true
    expect(draft.glide).toBe 15
    expect(draft.servos[0].min).toBe 1050
    expect(draft.servos).toHaveLength 8
    expect(state().dirty).toBe false

  it 'writes every servo and the glide degree on device save', ->
    writes = []
    session = deviceSession { log: writes }
    await state().loadFromDevice session
    state().setGlide 25
    await state().save()
    expect(writes.filter((w) -> w[0] == 'servo')).toHaveLength 8
    expect(writes.filter((w) -> w[0] == 'rule')).toHaveLength 16
    expect(writes).toContainEqual ['glide', 25]
    expect(writes).toContainEqual ['wing', state().saved.wing]
    expect(state().dirty).toBe false

  it 'throws when saving in device mode without a session', ->
    state().setMode 'device'
    await expect(state().save()).rejects.toThrow 'No device session'

  it 'rejects unknown modes', ->
    expect((-> state().setMode 'astral')).toThrow(
      'Unknown servo mode'
    )

deviceSession = (options = {}) ->
  {
    readServoConfigurations: -> Promise.resolve options.configs ? []
    readServoTuning: -> Promise.resolve {
      glide: options.glide ? 0, cadence: 30, ferocityD: 40, balance: 10
    }
    readServoMixRules: -> Promise.resolve []
    readWingMapping: -> Promise.resolve {
      prefix: [], appendix: null, tail: []
    }
    writeServoConfiguration: (index, config) ->
      options.log?.push ['servo', index]
      Promise.resolve { index, config }
    writeGlideDegree: (glide) ->
      options.log?.push ['glide', glide]
      Promise.resolve glide
    writeServoMixRule: (index, rule) ->
      options.log?.push ['rule', index]
      Promise.resolve { index, rule }
    writeWingMapping: (appendix) ->
      options.log?.push ['wing', appendix]
      Promise.resolve appendix
  }