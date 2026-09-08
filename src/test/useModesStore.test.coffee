import { describe, it, expect, beforeEach } from 'vitest'
import useModesStore, { isRangeUsable } from '../stores/useModesStore.coffee'

describe 'useModesStore', ->
  store = useModesStore
  state = -> store.getState()

  beforeEach -> state().reset()

  it 'starts in sim mode with 20 empty slots', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.extrasAvailable).toBe false
    expect(state().draft.ranges).toHaveLength 20
    expect(state().draft.ranges[0].permanentId).toBe 0

  it 'assigns catalog boxes and clamps range fields', ->
    state().setRangeField 0, 'permanentId', 28
    state().setRangeField 0, 'auxChannelIndex', 99
    state().setRangeField 0, 'startStep', 10
    state().setRangeField 0, 'endStep', 99
    state().setRangeField 0, 'modeLogic', 9
    state().setRangeField 0, 'linkedToPermId', 36
    range = state().draft.ranges[0]
    expect(range.permanentId).toBe 28
    expect(range.auxChannelIndex).toBe 13
    expect(range.startStep).toBe 10
    expect(range.endStep).toBe 48
    expect(range.modeLogic).toBe 2
    expect(range.linkedToPermId).toBe 36
    expect(state().dirty).toBe true

  it 'rejects unknown permanent ids and linked boxes', ->
    state().setRangeField 0, 'permanentId', 3
    state().setRangeField 0, 'linkedToPermId', 255
    expect(state().draft.ranges[0].permanentId).toBe 0
    expect(state().draft.ranges[0].linkedToPermId).toBe 0
    expect(state().dirty).toBe false

  it 'ignores unknown and inherited field names', ->
    for field in ['astral', 'constructor', '__proto__', 'toString']
      state().setRangeField 0, field, 5
    expect(state().dirty).toBe false

  it 'ignores out-of-range indices', ->
    state().setRangeField 20, 'permanentId', 28
    state().setRangeField -1, 'permanentId', 28
    expect(state().dirty).toBe false
    expect(state().draft.ranges[0].permanentId).toBe 0

  it 'revert restores the last saved document', ->
    state().setRangeField 0, 'permanentId', 28
    await state().save()
    state().setRangeField 0, 'permanentId', 36
    state().revert()
    expect(state().draft.ranges[0].permanentId).toBe 28
    expect(state().dirty).toBe false

  it 'save commits locally in sim mode without a session', ->
    state().setRangeField 1, 'permanentId', 50
    await state().save()
    expect(state().dirty).toBe false
    expect(state().saved.ranges[1].permanentId).toBe 50

  it 'rejects device writes before a device read', ->
    state().setMode 'device'
    state().attachSession deviceSession {}
    await expect(state().save()).rejects.toThrow(
      'Read the device before writing'
    )

  it 'loads ranges with extras from the device', ->
    session = deviceSession {
      ranges: [{
        permanentId: 28, auxChannelIndex: 5
        startStep: 10, endStep: 20
      }]
      extras: [{
        permanentId: 28, modeLogic: 1, linkedToPermId: 36
      }]
    }
    draft = await state().loadFromDevice session
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe true
    expect(draft.extrasAvailable).toBe true
    expect(draft.ranges[0]).toMatchObject {
      permanentId: 28, modeLogic: 1, linkedToPermId: 36
    }
    expect(draft.ranges[1].permanentId).toBe 0

  it 'degrades without extras on legacy firmware', ->
    session = deviceSession { ranges: [], extras: null }
    draft = await state().loadFromDevice session
    expect(draft.extrasAvailable).toBe false
    expect(draft.ranges[0].modeLogic).toBe 0
    expect(draft.ranges[0].linkedToPermId).toBe 0

  it 'writes all 20 slots on device save', ->
    writes = []
    session = deviceSession { log: writes, ranges: [], extras: null }
    await state().loadFromDevice session
    state().setRangeField 3, 'permanentId', 50
    state().setRangeField 3, 'startStep', 12
    state().setRangeField 3, 'endStep', 24
    await state().save()
    expect(writes).toHaveLength 20
    expect(writes[3].permanentId).toBe 50
    expect(writes[3].startStep).toBe 12
    expect(writes[3].endStep).toBe 24
    expect(writes[3].linkedToPermId).toBe 0
    expect(state().dirty).toBe false

  it 'throws when saving in device mode without a session', ->
    state().setMode 'device'
    await expect(state().save()).rejects.toThrow 'No device session'

  it 'rejects unknown modes', ->
    expect((-> state().setMode 'astral')).toThrow 'Unknown modes mode'

  it 'treats ARM (permanentId 0) with a range as usable', ->
    state().setRangeField 0, 'startStep', 10
    state().setRangeField 0, 'endStep', 20
    expect(state().draft.ranges[0].permanentId).toBe 0
    expect(isRangeUsable state().draft.ranges[0]).toBe true

  it 'treats a zero-width range as empty regardless of box', ->
    state().setRangeField 0, 'permanentId', 28
    expect(state().draft.ranges[0].permanentId).toBe 28
    expect(isRangeUsable state().draft.ranges[0]).toBe false

  it 'writes ARM (permanentId 0) with a range to the device', ->
    writes = []
    session = deviceSession { log: writes, ranges: [], extras: null }
    await state().loadFromDevice session
    state().setRangeField 0, 'startStep', 10
    state().setRangeField 0, 'endStep', 20
    await state().save()
    expect(writes[0].permanentId).toBe 0
    expect(writes[0].startStep).toBe 10
    expect(writes[0].endStep).toBe 20

  it 'clamps non-finite and extreme inputs to the domain', ->
    state().setRangeField 0, 'startStep', NaN
    expect(state().draft.ranges[0].startStep).toBe 0
    state().setRangeField 0, 'endStep', Infinity
    expect(state().draft.ranges[0].endStep).toBe 48
    state().setRangeField 0, 'startStep', -Infinity
    expect(state().draft.ranges[0].startStep).toBe 0

deviceSession = (options = {}) ->
  {
    readModeRanges: -> Promise.resolve {
      ranges: options.ranges ? []
      extras: options.extras ? null
    }
    writeModeRange: (index, range) ->
      options.log?.push range
      Promise.resolve { index, range }
  }
