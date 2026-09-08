###
# ORNIFLIGHT STUDIO — Adjustments Store (Zustand)
#
# Polymorphic adjustment document: draft ≠ saved with dirty tracking.
# The draft is the full 30-slot wire array (MSP 52); each slot is a
# 6-byte record {slot, aux, startStep, endStep, adjustmentConfig,
# auxSwitchChannelIndex}. In sim mode `save` commits locally
# (dry-run); in device mode only slots that actually changed ride
# SET_ADJUSTMENT_RANGE + EEPROM_WRITE, followed by one full read-back
# as the new saved document. `loadedSession` pins the document to
# its source device.
###
import { create } from 'zustand'
import {
  MAX_ADJUSTMENT_RANGE_COUNT, DEFAULT_ADJUSTMENT_RANGE
  sanitizeAdjustmentRange
} from '../lib/adjustmentsCatalog.coffee'

clone = (value) -> JSON.parse JSON.stringify value

draftDefaults = ->
  ranges = []
  for index in [0...MAX_ADJUSTMENT_RANGE_COUNT]
    ranges.push { DEFAULT_ADJUSTMENT_RANGE..., index }
  { ranges }

useAdjustmentsStore = create (set, get) ->
  defaults = draftDefaults()

  setRange: (slot, patch = {}) ->
    unless Number.isInteger(slot) and 0 <= slot < MAX_ADJUSTMENT_RANGE_COUNT
      throw new Error "Adjustment slot out of range: #{slot}"
    draft = get().draft
    range = sanitizeAdjustmentRange { draft.ranges[slot]..., patch... }
    range.index = slot
    return if JSON.stringify(range) == JSON.stringify(draft.ranges[slot])
    ranges = draft.ranges[..]
    ranges[slot] = range
    set { draft: { draft..., ranges }, dirty: true }

  save: ->
    { mode, session, draft, saved } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device adjustment ranges before saving'
        # Only touched slots ride the wire — 30 unconditional
        # SET+EEPROM pairs would hammer the flight controller.
        changed = []
        for index in [0...MAX_ADJUSTMENT_RANGE_COUNT]
          a = JSON.stringify draft.ranges[index]
          b = JSON.stringify saved.ranges[index]
          changed.push index unless a == b
        for index in changed
          await session.writeAdjustmentRange index, draft.ranges[index]
        ranges = await session.readAdjustmentRanges()
        while ranges.length < MAX_ADJUSTMENT_RANGE_COUNT
          ranges.push { DEFAULT_ADJUSTMENT_RANGE..., index: ranges.length }
        savedDocument = { ranges }
      else
        savedDocument = draft
    catch error
      set { lastError: error?.message or 'Adjustments save failed' }
      throw error
    savedDocument = clone savedDocument
    set { saved: savedDocument, draft: clone(savedDocument), dirty: false, lastError: null }
    clone savedDocument

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown adjustments mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    try
      throw new Error 'No device session attached' unless session?
      ranges = await session.readAdjustmentRanges()
      unless ranges.length
        ranges = draftDefaults().ranges
      while ranges.length < MAX_ADJUSTMENT_RANGE_COUNT
        ranges.push { DEFAULT_ADJUSTMENT_RANGE..., index: ranges.length }
      draft = { ranges }
    catch error
      set { lastError: error?.message or 'Adjustments read failed' }
      throw error
    draft = clone draft
    set {
      mode: 'device'
      session
      loadedSession: session
      draft
      saved: clone draft
      dirty: false
      lastError: null
    }
    clone draft

  reset: ->
    defaults = draftDefaults()
    set {
      mode: 'sim'
      session: null
      loadedSession: null
      draft: clone defaults
      saved: clone defaults
      dirty: false
      lastError: null
    }
    defaults

  mode: 'sim'
  session: null
  loadedSession: null
  draft: defaults
  saved: clone defaults
  dirty: false
  lastError: null

export default useAdjustmentsStore
