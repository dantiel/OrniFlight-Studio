###
# ORNIFLIGHT STUDIO — Modes Store (Zustand)
#
# AUX mode-range document (MSP 34/35 + optional 238 extras): 20
# activation slots mapping flight-mode boxes to AUX channel ranges.
# Polymorphic: sim mode commits locally; device mode rides the
# OrniFlight session behind the loadedSession guard. Permanent IDs
# are validated against the static mode catalog before they reach
# the wire; linkedTo never travels as 255.
###
import { create } from 'zustand'
import {
  MAX_MODE_ACTIVATION_CONDITION_COUNT, MODE_RANGE_STEP_MAX
} from '../protocol/mspDecoders.coffee'
import { isModePermId } from '../lib/modeCatalog.coffee'

AUX_CHANNEL_LIMITS = [0, 13]
LOGIC_LIMITS = [0, 2]
PERM_ID_LIMITS = [0, 255]

# Closed set: setRangeField routes whitelisted fields only —
# inherited object keys never pass.
RANGE_FIELDS = [
  'permanentId', 'auxChannelIndex', 'startStep', 'endStep'
  'modeLogic', 'linkedToPermId'
]

MODE_LOGIC_LABELS = Object.freeze ['AND', 'OR', 'XOR']

clone = (value) -> JSON.parse JSON.stringify value

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

clampInt = (lo, hi, value) ->
  return hi if value == Infinity
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

defaultRanges = ->
  for i in [0...MAX_MODE_ACTIVATION_CONDITION_COUNT]
    {
      permanentId: 0
      auxChannelIndex: 0
      startStep: 0
      endStep: 0
      modeLogic: 0
      linkedToPermId: 0
    }

MODES_DEFAULTS = Object.freeze { ranges: defaultRanges() }

# A slot counts as configured when a real box sits in a real range.
isRangeUsable = (range) ->
  range.permanentId != 0 and range.startStep < range.endStep

useModesStore = create (set, get) ->
  defaults = clone MODES_DEFAULTS.ranges

  setRangeField: (index, field, value) ->
    return unless 0 <= index < MAX_MODE_ACTIVATION_CONDITION_COUNT
    return unless field in RANGE_FIELDS
    ranges = clone get().draft.ranges
    range = ranges[index]
    if field in ['permanentId', 'linkedToPermId']
      id = clampInt PERM_ID_LIMITS..., value
      # Foreign permanent IDs never reach the wire — the catalog is
      # the closed vocabulary of the modes document.
      return unless isModePermId id
      range[field] = id
    else if field == 'auxChannelIndex'
      range[field] = clampInt AUX_CHANNEL_LIMITS..., value
    else if field in ['startStep', 'endStep']
      range[field] = clampInt 0, MODE_RANGE_STEP_MAX, value
    else
      range[field] = clampInt LOGIC_LIMITS..., value
    set { draft: { get().draft..., ranges }, dirty: true }

  save: ->
    { mode, session, draft, loadedSession } = get()
    if mode == 'device'
      throw new Error 'No device session attached' unless session?
      unless loadedSession
        throw new Error(
          'Read the device before writing — the draft may belong ' +
          'to another craft'
        )
      for range, index in draft.ranges
        # An all-zero slot clears on the wire; logic and link ride
        # along from the extras read so chains survive the write.
        await session.writeModeRange index, {
          permanentId: range.permanentId
          auxChannelIndex: range.auxChannelIndex
          startStep: range.startStep
          endStep: range.endStep
          modeLogic: range.modeLogic
          linkedToPermId: range.linkedToPermId
        }
    saved = clone draft
    set { saved, dirty: false }
    saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown modes mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    set { session, mode: 'device', loadedSession: false }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    { ranges, extras } = await session.readModeRanges()
    draft = { ranges: defaultRanges(), extrasAvailable: extras? }
    for range, index in ranges[0...MAX_MODE_ACTIVATION_CONDITION_COUNT]
      extra = extras?[index]
      draft.ranges[index] = {
        permanentId: range.permanentId
        auxChannelIndex: range.auxChannelIndex
        startStep: range.startStep
        endStep: range.endStep
        modeLogic: extra?.modeLogic ? 0
        linkedToPermId: extra?.linkedToPermId ? 0
      }
    set {
      mode: 'device'
      session
      loadedSession: true
      draft: clone draft
      saved: clone draft
      dirty: false
    }
    clone draft

  reset: ->
    draft = { ranges: clone(MODES_DEFAULTS.ranges), extrasAvailable: false }
    set {
      mode: 'sim'
      session: null
      loadedSession: false
      draft
      saved: clone draft
      dirty: false
    }
    draft

  mode: 'sim'
  session: null
  loadedSession: false
  draft: { ranges: defaults, extrasAvailable: false }
  saved: clone { ranges: defaults, extrasAvailable: false }
  dirty: false

export default useModesStore
export { MODES_DEFAULTS, MODE_LOGIC_LABELS, isRangeUsable }