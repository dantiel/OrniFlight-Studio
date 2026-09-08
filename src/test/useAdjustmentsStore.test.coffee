import { describe, it, expect, vi, beforeEach } from 'vitest'
import useAdjustmentsStore from '../stores/useAdjustmentsStore.coffee'
import {
  MAX_ADJUSTMENT_RANGE_COUNT
} from '../lib/adjustmentsCatalog.coffee'

state = -> useAdjustmentsStore.getState()

record = (patch = {}) ->
  {
    adjustmentIndex: 0, auxChannelIndex: 0, startStep: 0, endStep: 0
    adjustmentConfig: 0, auxSwitchChannelIndex: 0, patch...
  }

makeSession = ->
  stored = (record { index: i } for i in [0...MAX_ADJUSTMENT_RANGE_COUNT])
  {
    readAdjustmentRanges: vi.fn -> Promise.resolve stored
    writeAdjustmentRange: vi.fn (index, range) ->
      stored[index] = { range..., index }
      Promise.resolve stored
  }

describe 'useAdjustmentsStore', ->
  beforeEach -> state().reset()

  it 'starts with 30 default slots in sim mode', ->
    expect(state().mode).toBe 'sim'
    expect(state().draft.ranges).toHaveLength MAX_ADJUSTMENT_RANGE_COUNT
    expect(state().draft.ranges[0].adjustmentConfig).toBe 0
    expect(state().draft.ranges[29].index).toBe 29

  it 'patches a slot and clamps to channel/step bounds', ->
    state().setRange 0, { auxChannelIndex: 13, startStep: 48, endStep: 99 }
    slot = state().draft.ranges[0]
    expect(slot.auxChannelIndex).toBe 13
    expect(slot.startStep).toBe 48
    expect(slot.endStep).toBe 48
    expect(state().dirty).toBe true

  it 'rejects out-of-range slot indices', ->
    expect(-> state().setRange 30, { adjustmentConfig: 1 }).toThrow(
      'out of range'
    )
    expect(state().dirty).toBe false

  it 'saves locally in sim mode (dry-run)', ->
    state().setRange 3, { adjustmentConfig: 5 }
    saved = await state().save()
    expect(saved.ranges[3].adjustmentConfig).toBe 5
    expect(state().dirty).toBe false

  it 'reverts to the saved document', ->
    state().setRange 1, { startStep: 10 }
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft.ranges[1].startStep).toBe(
      state().saved.ranges[1].startStep
    )

  it 'loads and pads the full document from a device session', ->
    session = makeSession()
    session.readAdjustmentRanges.mockImplementation ->
      Promise.resolve [record { adjustmentConfig: 3 }]
    state().attachSession session
    draft = await state().loadFromDevice()
    expect(draft.ranges).toHaveLength MAX_ADJUSTMENT_RANGE_COUNT
    expect(draft.ranges[0].adjustmentConfig).toBe 3
    expect(draft.ranges[29].index).toBe 29

  it 'writes only changed slots on device save', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    state().setRange 2, { adjustmentConfig: 7 }
    state().setRange 5, { startStep: 20 }
    saved = await state().save()
    expect(session.writeAdjustmentRange).toHaveBeenCalledTimes 2
    expect(saved.ranges[2].adjustmentConfig).toBe 7
    expect(saved.ranges[5].startStep).toBe 20
    expect(state().dirty).toBe false

  it 'refuses to save against a stale session', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    state().attachSession makeSession()
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'Read device adjustment ranges'
    expect(state().lastError).toContain 'Read device adjustment ranges'
