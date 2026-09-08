import { describe, it, expect, beforeEach } from 'vitest'
import useReceiverStore from '../stores/useReceiverStore.coffee'
import { RXFAIL_MODE } from '../protocol/mspDecoders.coffee'

describe 'useReceiverStore', ->
  store = useReceiverStore
  state = -> store.getState()

  beforeEach -> state().reset()

  it 'starts in sim mode with ornithopter receiver defaults', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.provider).toBe 9 # CRSF first
    expect(state().draft.maxcheck).toBe 1900
    expect(state().draft.midrc).toBe 1500
    expect(state().draft.mincheck).toBe 1050
    expect(state().draft.channelMap).toBe 'AETR1234'
    expect(state().draft.rxFail).toHaveLength 18

  it 'clamps config fields into their wire domains', ->
    state().setRxConfigField 'provider', 99
    expect(state().draft.provider).toBe 12
    state().setRxConfigField 'maxcheck', 9999
    expect(state().draft.maxcheck).toBe 2500
    state().setRxConfigField 'rxMinUsec', 100
    expect(state().draft.rxMinUsec).toBe 500
    state().setRxConfigField 'rxMaxUsec', 9999
    expect(state().draft.rxMaxUsec).toBe 3000
    state().setRxConfigField 'airModeActivateThreshold', -5
    expect(state().draft.airModeActivateThreshold).toBe 0
    state().setRxConfigField 'airModeActivateThreshold', 999
    expect(state().draft.airModeActivateThreshold).toBe 250
    expect(state().dirty).toBe true

  it 'ignores unknown and inherited field names', ->
    for field in ['astral', 'constructor', '__proto__', 'toString']
      state().setRxConfigField field, 1200
    expect(state().dirty).toBe false

  it 'edits channel-map positions with letter validation', ->
    state().setChannelMapPosition 0, 'T'
    expect(state().draft.channelMap).toBe 'TETR1234'
    state().setChannelMapPosition 9, 'A'
    state().setChannelMapPosition 1, '?'
    expect(state().draft.channelMap).toBe 'TETR1234'
    expect(state().dirty).toBe true

  it 'edits failsafe slots within the step domain', ->
    state().setRxFailField 3, 'mode', RXFAIL_MODE.SET
    state().setRxFailField 3, 'step', 99
    expect(state().draft.rxFail[3].mode).toBe RXFAIL_MODE.SET
    expect(state().draft.rxFail[3].step).toBe 60
    state().setRxFailField 18, 'step', 10
    state().setRxFailField -1, 'step', 10
    expect(state().draft.rxFail[0].step).toBe 0

  it 'revert restores the last saved document', ->
    state().setRxConfigField 'midrc', 1480
    await state().save()
    state().setRxConfigField 'midrc', 1520
    state().revert()
    expect(state().draft.midrc).toBe 1480
    expect(state().dirty).toBe false

  it 'save commits locally in sim mode without a session', ->
    state().setChannelMapPosition 3, 'T'
    await state().save()
    expect(state().dirty).toBe false
    expect(state().saved.channelMap).toBe 'AETT1234'

  it 'rejects device writes before a device read', ->
    state().setMode 'device'
    state().attachSession deviceSession {}
    await expect(state().save()).rejects.toThrow(
      'Read the device before writing'
    )

  it 'loads the receiver document from the device', ->
    session = deviceSession {
      config: { provider: 2, midrc: 1490 }
      rxMap: [0, 1, 3, 2, 4, 5, 6, 7]
      rxFail: [{ mode: 2, value: 1200 }]
    }
    draft = await state().loadFromDevice session
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe true
    expect(draft.provider).toBe 2
    expect(draft.midrc).toBe 1490
    expect(draft.channelMap).toBe 'AETR1234'
    expect(draft.rxFail[0]).toEqual { mode: 2, step: 18 }
    expect(draft.rxFail[1].mode).toBe RXFAIL_MODE.AUTO
    expect(state().dirty).toBe false

  it 'writes config, map and 18 failsafe slots on device save', ->
    writes = []
    session = deviceSession {
      log: writes
      config: { provider: 2, midrc: 1490 }
      rxMap: [0, 1, 3, 2, 4, 5, 6, 7]
    }
    await state().loadFromDevice session
    state().setRxConfigField 'provider', 7
    state().setChannelMapPosition 2, 'T'
    await state().save()
    expect(writes.filter((w) -> w[0] == 'rxConfig')).toHaveLength 1
    expect(writes.filter((w) -> w[0] == 'rxMap')).toHaveLength 1
    expect(writes.filter((w) -> w[0] == 'rxFail')).toHaveLength 18
    expect(state().dirty).toBe false

    # Regression: rxConfigFromDraft must emit a flat {field: value}
    # document, never a CoffeeScript object-comprehension array.
    rxConfig = writes.find((w) -> w[0] == 'rxConfig')[1]
    expect(rxConfig).toEqual {
      provider: 7
      maxcheck: 1900
      midrc: 1490
      mincheck: 1050
      spektrumSatBind: 0
      rxMinUsec: 885
      rxMaxUsec: 2115
      rcInterpolation: 0
      rcInterpolationInterval: 0
      airModeActivateThreshold: 0
    }

    # Regression: the map handed to the session must be length-8 and
    # carry the inverted wire assignment.
    rxMap = writes.find((w) -> w[0] == 'rxMap')[1]
    expect(rxMap.length).toBe 8
    expect(Array.from rxMap).toEqual [0, 1, 3, 2, 4, 5, 6, 7]

  it 'throws when saving in device mode without a session', ->
    state().setMode 'device'
    await expect(state().save()).rejects.toThrow 'No device session'

  it 'rejects unknown modes', ->
    expect((-> state().setMode 'astral')).toThrow(
      'Unknown receiver mode'
    )

  it 'clamps non-finite and extreme inputs to the domain', ->
    state().setRxConfigField 'maxcheck', NaN
    expect(state().draft.maxcheck).toBe 500
    state().setRxConfigField 'maxcheck', Infinity
    expect(state().draft.maxcheck).toBe 2500
    state().setRxConfigField 'maxcheck', -Infinity
    expect(state().draft.maxcheck).toBe 500
    state().setRxFailField 0, 'step', Infinity
    expect(state().draft.rxFail[0].step).toBe 60
    state().setRxFailField 0, 'step', -Infinity
    expect(state().draft.rxFail[0].step).toBe 0

deviceSession = (options = {}) ->
  {
    readRxConfig: -> Promise.resolve options.config ? null
    readRxMap: -> Promise.resolve options.rxMap ? []
    readRxFailConfig: -> Promise.resolve options.rxFail ? []
    writeRxConfig: (config) ->
      options.log?.push ['rxConfig', config]
      Promise.resolve config
    writeRxMap: (rxMap) ->
      options.log?.push ['rxMap', rxMap]
      Promise.resolve rxMap
    writeRxFailChannel: (index, channel) ->
      options.log?.push ['rxFail', index, channel]
      Promise.resolve { index, channel }
  }