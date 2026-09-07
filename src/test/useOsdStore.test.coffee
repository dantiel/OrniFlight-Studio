import { describe, it, expect, vi } from 'vitest'
import useOsdStore from '../stores/useOsdStore.coffee'
import {
  OSD_DEFAULTS, OSD_ITEM_COUNT, itemPos, posCell, visibleInProfile
  PROFILE_MASK
} from '../lib/osdCatalog.coffee'

state = -> useOsdStore.getState()

# Polymorphic session double: stores the last written layout and serves
# it back on read, exactly like the firmware round-trip the real
# OrniFlightSession performs.
sessionDouble = ->
  stored = OSD_DEFAULTS
  {
    readOsdConfig: vi.fn -> Promise.resolve { items: stored }
    writeOsdConfig: vi.fn (config) ->
      stored = [...config.items]
      Promise.resolve { items: stored }
  }

describe 'useOsdStore', ->
  beforeEach ->
    state().reset()

  it 'starts in sim mode with firmware defaults and no dirty flag', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().profileIndex).toBe 1
    expect(state().draft).toEqual OSD_DEFAULTS
    expect(state().dragState).toBe null

  it 'moves an item while preserving its visibility flags', ->
    state().setItemPos 21, 20, 3
    expect(posCell state().draft[21]).toEqual { x: 20, y: 3 }
    expect(visibleInProfile state().draft[21], 1).toBe true
    expect(state().dirty).toBe true

  it 'clamps positions into the visible grid', ->
    state().setItemPos 5, 99, -4
    expect(posCell state().draft[5]).toEqual { x: 29, y: 0 }

  it 'ignores out-of-range item indices and profile indices', ->
    state().setItemPos 52, 1, 1
    state().toggleItemVisibility 0, 4
    expect(state().dirty).toBe false

  it 'toggles visibility per profile', ->
    state().setItemVisible 0, 1, true
    expect(visibleInProfile state().draft[0], 1).toBe true
    expect(visibleInProfile state().draft[0], 2).toBe false
    state().toggleItemVisibility 0, 1
    expect(visibleInProfile state().draft[0], 1).toBe false

  it 'places a palette item onto the first free cell, visible', ->
    state().placeItem 15, { x: 4, y: 5 }
    expect(posCell state().draft[15]).toEqual { x: 4, y: 5 }
    expect(visibleInProfile state().draft[15], 1).toBe true

  it 'runs the drag lifecycle with clamp and cancellation', ->
    state().setItemVisible 0, 1, true
    origin = state().draft[0]
    state().beginDrag 0
    expect(state().dragState.index).toBe 0
    state().dragTo 25, 14
    expect(posCell state().draft[0]).toEqual { x: 25, y: 14 }
    expect(visibleInProfile state().draft[0], 1).toBe true
    state().dropAt 26, 14
    expect(state().dragState).toBe null
    expect(posCell state().draft[0]).toEqual { x: 26, y: 14 }
    dropped = state().draft[0]
    state().beginDrag 0
    state().dragTo 10, 10
    state().cancelDrag()
    expect(state().draft[0]).toBe dropped
    expect(state().dragState).toBe null
    expect(posCell state().draft[0]).toEqual { x: 26, y: 14 }

  it 'does not dirty on a drag that ends where it started', ->
    state().beginDrag 21
    state().dragTo 9, 10
    expect(state().dirty).toBe false
    state().dropAt 9, 10
    expect(state().dirty).toBe false
    expect(state().draft[21]).toBe itemPos(9, 10) | PROFILE_MASK

  it 'commits the draft on save in sim mode', ->
    state().setItemPos 21, 12, 4
    await state().save()
    expect(state().saved[21]).toBe state().draft[21]
    expect(state().dirty).toBe false

  it 'reverts the draft to the last saved document', ->
    state().setItemPos 21, 12, 4
    await state().save()
    state().setItemPos 21, 13, 5
    state().revert()
    expect(posCell state().draft[21]).toEqual { x: 12, y: 4 }
    expect(state().dirty).toBe false

  it 'writes through the session on save in device mode', ->
    session = sessionDouble()
    state().attachSession session
    expect(state().mode).toBe 'device'
    await state().loadFromDevice()
    state().setItemPos 21, 6, 8
    await state().save()
    expect(session.writeOsdConfig).toHaveBeenCalledTimes 1
    expect(state().saved[21]).toBe state().draft[21]
    expect(state().dirty).toBe false

  it 'refuses to save in device mode without a session', ->
    state().setMode 'device'
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'No device session attached'

  it 'refuses to save before reading the attached device', ->
    state().attachSession sessionDouble()
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'Read device OSD layout before saving'

  it 'records the failure message when a device save throws', ->
    session = sessionDouble()
    session.writeOsdConfig = vi.fn ->
      Promise.reject new Error 'OSD configuration read-back failed'
    state().attachSession session
    await state().loadFromDevice()
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'read-back failed'
    expect(state().lastError).toContain 'read-back failed'

  it 'adopts the device profile index on read', ->
    session = {
      readOsdConfig: vi.fn -> Promise.resolve { profileIndex: 2, items: null }
      writeOsdConfig: vi.fn -> Promise.resolve { items: [] }
    }
    state().attachSession session
    await state().loadFromDevice()
    expect(state().profileIndex).toBe 2

  it 'clamps a bogus device profile index into range', ->
    session = {
      readOsdConfig: vi.fn -> Promise.resolve { profileIndex: 9, items: null }
      writeOsdConfig: vi.fn -> Promise.resolve { items: [] }
    }
    state().attachSession session
    await state().loadFromDevice()
    expect(state().profileIndex).toBe 3

  it 'rejects unknown modes', ->
    expect(-> state().setMode 'auto').toThrow 'Unknown OSD mode'

  it 'switches the active profile', ->
    state().setProfileIndex 2
    expect(state().profileIndex).toBe 2
    state().setProfileIndex 9
    expect(state().profileIndex).toBe 2