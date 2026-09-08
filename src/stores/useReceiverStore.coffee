###
# ORNIFLIGHT STUDIO — Receiver Store (Zustand)
#
# Receiver document: serial RX configuration (MSP 44/45), the channel
# map (MSP 64/65) and per-channel failsafe slots (MSP 77/78).
# Polymorphic: sim mode commits locally; device mode rides the
# OrniFlight session. The loadedSession guard forces a device read
# before any device write — a foreign device is never overwritten by
# an unloaded draft.
###
import { create } from 'zustand'
import {
  MAX_SUPPORTED_RC_CHANNEL_COUNT, RX_MAPPABLE_CHANNEL_COUNT
  RC_CHANNEL_LETTERS, RXFAIL_MODE, RXFAIL_STEP_MAX
  channelMapFromRxMap, rxMapFromChannelMap
  rxFailStepToValue, rxFailValueToStep
} from '../protocol/mspDecoders.coffee'

PROVIDER_LIMITS = [0, 12]
CHECK_LIMITS = [500, 2500]
USEC_LIMITS = [500, 3000]
THRESHOLD_LIMITS = [0, 250]
BIND_LIMITS = [0, 255]
U8_LIMITS = [0, 255]
INTERPOLATION_LIMITS = [0, 255]

# Closed set: setRxConfigField routes whitelisted fields only —
# inherited object keys ('constructor', '__proto__', 'toString')
# never pass.
RX_FIELD_NAMES = [
  'provider', 'maxcheck', 'midrc', 'mincheck', 'spektrumSatBind'
  'rxMinUsec', 'rxMaxUsec', 'rcInterpolation'
  'rcInterpolationInterval', 'airModeActivateThreshold'
]

RXFAIL_FIELD_NAMES = ['mode', 'step']

DEFAULT_CHANNEL_MAP = 'AETR1234'

clone = (value) -> JSON.parse JSON.stringify value

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

defaultRxFail = ->
  for i in [0...MAX_SUPPORTED_RC_CHANNEL_COUNT]
    { mode: RXFAIL_MODE.AUTO, step: 0 }

defaultDraft = ->
  provider: 9
  maxcheck: 1900
  midrc: 1500
  mincheck: 1050
  spektrumSatBind: 0
  rxMinUsec: 885
  rxMaxUsec: 2115
  rcInterpolation: 0
  rcInterpolationInterval: 0
  airModeActivateThreshold: 0
  channelMap: DEFAULT_CHANNEL_MAP
  rxFail: defaultRxFail()

RECEIVER_DEFAULTS = Object.freeze { draft: defaultDraft() }

# Build a flat {field: value} document — CoffeeScript object
# comprehensions with a literal key would emit an array of
# single-key objects, so the keys are assigned explicitly.
rxConfigFromDraft = (draft) ->
  result = {}
  for field in RX_FIELD_NAMES
    result[field] = draft[field]
  result

clampField = (field, value) ->
  if field == 'provider'
    clampInt PROVIDER_LIMITS..., value
  else if field in ['maxcheck', 'midrc', 'mincheck']
    clampInt CHECK_LIMITS..., value
  else if field in ['rxMinUsec', 'rxMaxUsec']
    clampInt USEC_LIMITS..., value
  else if field == 'airModeActivateThreshold'
    clampInt THRESHOLD_LIMITS..., value
  else if field in ['rcInterpolation', 'rcInterpolationInterval']
    clampInt INTERPOLATION_LIMITS..., value
  else if field == 'spektrumSatBind'
    clampInt BIND_LIMITS..., value
  else
    clampInt U8_LIMITS..., value

useReceiverStore = create (set, get) ->
  defaults = clone RECEIVER_DEFAULTS.draft

  setRxConfigField: (field, value) ->
    return unless field in RX_FIELD_NAMES
    draft = clone get().draft
    draft[field] = clampField field, value
    set { draft, dirty: true }

  setChannelMapPosition: (position, letter) ->
    return unless 0 <= position < RX_MAPPABLE_CHANNEL_COUNT
    return unless letter in RC_CHANNEL_LETTERS
    map = get().draft.channelMap
    letters = map.split ''
    letters[position] = letter
    draft = { get().draft..., channelMap: letters.join '' }
    set { draft, dirty: true }

  setRxFailField: (index, field, value) ->
    return unless 0 <= index < MAX_SUPPORTED_RC_CHANNEL_COUNT
    return unless field in RXFAIL_FIELD_NAMES
    channels = clone get().draft.rxFail
    channel = channels[index]
    if field == 'mode'
      channel.mode = clampInt 0, Object.keys(RXFAIL_MODE).length - 1, value
    else
      channel.step = clampInt 0, RXFAIL_STEP_MAX, value
    draft = { get().draft..., rxFail: channels }
    set { draft, dirty: true }

  save: ->
    { mode, session, draft, loadedSession } = get()
    if mode == 'device'
      throw new Error 'No device session attached' unless session?
      unless loadedSession
        throw new Error(
          'Read the device before writing — the draft may belong ' +
          'to another craft'
        )
      await session.writeRxConfig rxConfigFromDraft(draft)
      await session.writeRxMap rxMapFromChannelMap(draft.channelMap)
      for channel, index in draft.rxFail
        await session.writeRxFailChannel index, {
          mode: channel.mode
          value: rxFailStepToValue channel.step
        }
    saved = clone draft
    set { saved, dirty: false }
    saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown receiver mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    set { session, mode: 'device', loadedSession: false }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    config = await session.readRxConfig()
    rxMap = await session.readRxMap()
    rxFail = await session.readRxFailConfig()
    channels = defaultRxFail()
    for channel, index in rxFail[0...MAX_SUPPORTED_RC_CHANNEL_COUNT]
      channels[index] = {
        mode: channel.mode
        step: rxFailValueToStep channel.value
      }
    draft = {
      provider: config?.provider ? 9
      maxcheck: config?.maxcheck ? 1900
      midrc: config?.midrc ? 1500
      mincheck: config?.mincheck ? 1050
      spektrumSatBind: config?.spektrumSatBind ? 0
      rxMinUsec: config?.rxMinUsec ? 885
      rxMaxUsec: config?.rxMaxUsec ? 2115
      rcInterpolation: config?.rcInterpolation ? 0
      rcInterpolationInterval: config?.rcInterpolationInterval ? 0
      airModeActivateThreshold: config?.airModeActivateThreshold ? 0
      channelMap: (
        if rxMap.length then channelMapFromRxMap(rxMap)
        else DEFAULT_CHANNEL_MAP
      )
      rxFail: channels
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
    draft = clone RECEIVER_DEFAULTS.draft
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
  draft: defaults
  saved: clone defaults
  dirty: false

export default useReceiverStore
export { RECEIVER_DEFAULTS }