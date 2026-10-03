import { describe, it, expect, beforeEach } from 'vitest'
import useServoStore, {
  SURFACE_DEFAULTS, CONTROL_SURFACE_IDS
} from '../stores/useServoStore.coffee'
import { INPUT_SOURCES, inputSourceById } from '../lib/servoCatalog.coffee'

describe 'useServoStore', ->
  store = useServoStore
  state = -> store.getState()

  beforeEach -> state().reset()

  it 'starts in sim mode with a control-surface map', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.surfaces).toBeDefined()
    for id in CONTROL_SURFACE_IDS
      expect(state().draft.surfaces[id].inputSource).toBe(
        SURFACE_DEFAULTS[id].inputSource
      )

  it 'assigns a named input source to a surface', ->
    state().setSurfaceSource 'rudder', 'stabYaw'
    expect(state().draft.surfaces.rudder.inputSource).toBe 'stabYaw'
    expect(state().dirty).toBe true

  it 'assigns a target channel to a surface', ->
    state().setSurfaceChannel 'rudder', 3
    expect(state().draft.surfaces.rudder.targetChannel).toBe 3
    expect(state().dirty).toBe true

  it 'clamps the target channel to the servo domain', ->
    state().setSurfaceChannel 'motor', 99
    expect(state().draft.surfaces.motor.targetChannel).toBe 7
    state().setSurfaceChannel 'motor', -3
    expect(state().draft.surfaces.motor.targetChannel).toBe 0

  it 'ignores unknown surfaces and unknown sources', ->
    state().setSurfaceSource 'astral', 'stabYaw'
    state().setSurfaceSource 'rudder', 'astral'
    state().setSurfaceChannel 'astral', 3
    expect(state().dirty).toBe false
    expect(state().draft.surfaces.rudder.inputSource).toBe 'stabYaw'

  it 'revert restores the last saved document', ->
    state().setSurfaceChannel 'rudder', 5
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft.surfaces.rudder.targetChannel).toBe 0

  it 'save commits locally in sim mode without a session', ->
    state().setSurfaceSource 'rudder', 'rcYaw'
    await state().save()
    expect(state().dirty).toBe false
    expect(state().saved.surfaces.rudder.inputSource).toBe 'rcYaw'

  it 'rejects device writes before a device read', ->
    session = deviceSession {}
    state().setMode 'device'
    state().attachSession session
    await expect(state().save()).rejects.toThrow(
      'Read the device before writing'
    )

  it 'loads the surface mapping from device mix rules', ->
    session = deviceSession {
      rules: [
        { index: 0, targetChannel: 2, inputSource: 3 }   # rudder → Gier
        { index: 1, targetChannel: 1, inputSource: 2 }   # elevator → Nick
      ]
    }
    draft = await state().loadFromDevice session
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe true
    expect(draft.surfaces.rudder.targetChannel).toBe 2
    expect(draft.surfaces.rudder.inputSource).toBe 'stabYaw'
    expect(draft.surfaces.elevator.inputSource).toBe 'stabPitch'
    expect(state().dirty).toBe false

  it 'writes one mix rule per surface on device save', ->
    writes = []
    session = deviceSession { log: writes }
    await state().loadFromDevice session
    state().setSurfaceSource 'rudder', 'rcYaw'
    await state().save()
    expect(writes).toHaveLength CONTROL_SURFACE_IDS.length
    first = writes[0]
    expect(first[0]).toBe 'rule'
    expect(first[1]).toBe 0
    expect(first[2].targetChannel).toBe 0
    expect(first[2].inputSource).toBe inputSourceById('rcYaw').code
    expect(state().dirty).toBe false

  it 'throws when saving in device mode without a session', ->
    state().setMode 'device'
    await expect(state().save()).rejects.toThrow 'No device session'

  it 'rejects unknown modes', ->
    expect((-> state().setMode 'astral')).toThrow(
      'Unknown servo mode'
    )

  it 'exposes a named input-source vocabulary', ->
    for source in INPUT_SOURCES
      expect(inputSourceById(source.id)).toBeDefined()
    expect(inputSourceById('stabYaw').code).toBe 3

deviceSession = (options = {}) ->
  {
    readServoMixRules: -> Promise.resolve options.rules ? []
    writeServoMixRule: (index, rule) ->
      options.log?.push ['rule', index, rule]
      Promise.resolve { index, rule }
  }
