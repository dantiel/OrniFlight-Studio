import { describe, it, expect, vi } from 'vitest'
import useVtxStore from '../stores/useVtxStore.coffee'
import {
  DEFAULT_VTX_CONFIG, frequencyFor
} from '../lib/vtxCatalog.coffee'

state = -> useVtxStore.getState()

makeSession = (initial) ->
  stored = initial
  {
    readVtxConfig: vi.fn -> Promise.resolve stored
    writeVtxConfig: vi.fn (config) ->
      stored = { config..., deviceIsReady: 1 }
      Promise.resolve { stored... }
  }

describe 'useVtxStore', ->
  beforeEach -> state().reset()

  it 'starts in sim mode with firmware defaults', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft).toEqual DEFAULT_VTX_CONFIG

  it 'sets band/channel and derives the frequency', ->
    state().setBandChannel 5, 8
    expect(state().draft.band).toBe 5
    expect(state().draft.channel).toBe 8
    expect(state().draft.freq).toBe 5917
    expect(state().dirty).toBe true

  it 'keeps the channel when switching bands', ->
    state().setChannel 3
    state().setBand 2
    expect(state().draft.band).toBe 2
    expect(state().draft.channel).toBe 3
    expect(state().draft.freq).toBe frequencyFor 2, 3

  it 'enters custom mode with band 0 and clamps the frequency', ->
    state().setCustomFreq 9999
    expect(state().draft.band).toBe 0
    expect(state().draft.channel).toBe 0
    expect(state().draft.freq).toBe 5950
    state().setCustomFreq 100
    expect(state().draft.freq).toBe 5600

  it 'ignores invalid band/channel indices', ->
    state().setBandChannel 9, 1
    state().setBandChannel 1, 99
    state().setBand 0
    expect(state().dirty).toBe false

  it 'toggles pitmode and low power disarm as 0/1', ->
    state().setPitMode true
    state().setLowPowerDisarm true
    expect(state().draft.pitmode).toBe 1
    expect(state().draft.lowPowerDisarm).toBe 1
    state().setPitMode false
    expect(state().draft.pitmode).toBe 0

  it 'saves locally in sim mode (dry-run)', ->
    state().setPower 2
    saved = await state().save()
    expect(saved.power).toBe 2
    expect(state().dirty).toBe false
    expect(state().saved.power).toBe 2

  it 'reverts to the saved document', ->
    state().setPower 2
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft.power).toBe state().saved.power

  it 'loads from a device session and pins it', ->
    double = makeSession {
      DEFAULT_VTX_CONFIG..., band: 1, channel: 1, freq: 5865
      deviceIsReady: 1
    }
    draft = await state().loadFromDevice double
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe double
    expect(draft.band).toBe 1
    expect(draft.freq).toBe 5865
    expect(state().dirty).toBe false

  it 'saves through the device session with read-back', ->
    double = makeSession { DEFAULT_VTX_CONFIG..., deviceIsReady: 1 }
    await state().loadFromDevice double
    state().setBandChannel 1, 2
    saved = await state().save()
    expect(saved.band).toBe 1
    expect(saved.channel).toBe 2
    expect(saved.freq).toBe 5845
    expect(double.writeVtxConfig).toHaveBeenCalledTimes 1
    expect(state().dirty).toBe false

  it 'refuses to save on device before reading', ->
    double = makeSession { DEFAULT_VTX_CONFIG..., deviceIsReady: 1 }
    state().attachSession double
    state().setPower 2
    await expect(state().save())
      .rejects.toThrow 'Read device VTX configuration before saving'
    expect(state().lastError)
      .toBe 'Read device VTX configuration before saving'

  it 'falls back to defaults when the device reports nothing', ->
    double = makeSession null
    draft = await state().loadFromDevice double
    expect(draft.band).toBe 4
    expect(draft.freq).toBe 5740
