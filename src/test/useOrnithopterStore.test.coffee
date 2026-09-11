import { describe, it, expect, beforeEach } from 'vitest'
import useOrnithopterStore from '../stores/useOrnithopterStore.coffee'
import { engine } from '../simulation/engine.coffee'

describe 'useOrnithopterStore', ->
  store = useOrnithopterStore
  state = -> store.getState()

  beforeEach -> state().reset()

  it 'starts in sim mode with the servo body plan', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.kernel).toBe 'servo'
    expect(state().draft.profileId).toBe 1
    expect(state().draft.servoSpeed).toBe 220
    expect(state().draft.profiles).toHaveLength 3
    expect(state().draft.activeProfile).toBe 0

  it 'switching kernel jumps to the first profile of that kernel', ->
    state().setKernel 'gearbox'
    expect(state().draft.kernel).toBe 'gearbox'
    expect(state().draft.profileId).toBe 3
    expect(state().dirty).toBe true

  it 'rejects unknown kernels', ->
    expect(-> state().setKernel 'jet').toThrow /Unknown kernel/

  it 'rejects unknown mixer profiles', ->
    expect(-> state().setProfileId 9).toThrow /Unknown mixer profile/

  it 'clamps servo speed and applies tempo presets', ->
    state().setServoSpeed 9000
    expect(state().draft.servoSpeed).toBe 400
    state().setServoSpeed 1
    expect(state().draft.servoSpeed).toBe 40
    state().applySpeedPreset 'violent'
    expect(state().draft.servoSpeed).toBe 60

  it 'clamps trims and rejects foreign trim fields', ->
    state().setTrim 'leftWing', 400
    expect(state().draft.trims.leftWing).toBe 50
    state().setTrim 'rudder', -400
    expect(state().draft.trims.rudder).toBe -50
    state().setTrim 'constructor', 99
    hasOwn = Object.prototype.hasOwnProperty.call(
      state().draft.trims, 'constructor')
    expect(hasOwn).toBe false

  it 'clamps glide angles per face with index bounds', ->
    state().setGlideAngle 0, 90
    expect(state().draft.profiles[0].glideAngle).toBe 15
    state().setGlideAngle 5, 90
    expect(state().draft.profiles[5]).toBeUndefined()

  it 'clamps waveform params and mirrors them into the engine', ->
    state().setWaveformParam 0, 'strokeSkew', 400
    expect(state().draft.profiles[0].waveform.strokeSkew).toBe 100
    expect(engine.waveform.strokeSkew).toBe 100
    state().setWaveformParam 1, 'ferocityShapeMix', -20
    expect(state().draft.profiles[1].waveform.ferocityShapeMix).toBe 0
    state().setActiveProfile 1
    expect(engine.activeFlightProfile).toBe 1
    expect(engine.waveform.ferocityShapeMix).toBe 0

  it 'save in sim mode mirrors stroke time into the engine', ->
    state().setServoSpeed 150
    state().save()
    expect(engine.servoTravelTimeMs).toBe 150
    expect(state().dirty).toBe false

  it 'revert restores the saved draft', ->
    state().setServoSpeed 80
    expect(state().dirty).toBe true
    state().revert()
    expect(state().draft.servoSpeed).toBe 220
    expect(state().dirty).toBe false

  it 'device save refuses without loadedSession', ->
    fakeSession = { writeGlideDegree: (-> Promise.resolve()), setCraftName: (-> Promise.resolve()), writeServoConfiguration: (-> Promise.resolve()) }
    state().attachSession fakeSession
    expect(state().mode).toBe 'device'
    await expect(state().save()).rejects.toThrow(/Read the device before writing/)

  it 'device load requires a session', ->
    await expect(state().loadFromDevice null)
      .rejects.toThrow(/No device session attached/)