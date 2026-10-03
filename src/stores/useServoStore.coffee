###
# ORNIFLIGHT STUDIO — Servo Store (Zustand)
#
# Control-servo document: the PWM control surfaces of a gearbox craft
# (rudder / v-tail / elevator / motor). Each declared surface maps a
# NAMED input source to a target servo channel — a simplified, honest
# mixer, not the 8-rule Betaflight grid. The view renders only the
# surfaces the active mixer declares (mixerCatalog). Flapping servos
# (wing pairs + ONDAS + geometry) live in useOrnithopterStore.
#
# Polymorphic: sim mode commits locally; device mode rides the
# OrniFlight session — one servo mix rule per surface (MSP 241/242).
# The loadedSession guard forces a device read before any device write.
###
import { create } from 'zustand'
import {
  MAX_SERVO_MIX_RULES
} from '../protocol/mspDecoders.coffee'
import {
  INPUT_SOURCES, CONTROL_SURFACE_IDS, inputSourceById
} from '../lib/servoCatalog.coffee'

CHANNEL_LIMITS = [0, 7]

clone = (value) -> JSON.parse JSON.stringify value

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

# Default mapping — one entry per possible surface. The view filters
# this to the surfaces the active mixer actually declares.
SURFACE_DEFAULTS =
  rudder:     { inputSource: 'stabYaw',      targetChannel: 0 }
  elevator:   { inputSource: 'stabPitch',    targetChannel: 1 }
  vtailLeft:  { inputSource: 'stabPitch',    targetChannel: 1 }
  vtailRight: { inputSource: 'stabYaw',      targetChannel: 2 }
  motor:      { inputSource: 'stabThrottle', targetChannel: 3 }

normalizeSurfaces = (surfaces = {}) ->
  out = {}
  for id, def of SURFACE_DEFAULTS
    source = surfaces[id] or {}
    srcId = def.inputSource
    srcId = source.inputSource if inputSourceById(source.inputSource)?
    out[id] =
      inputSource: srcId
      targetChannel: clampInt(
        CHANNEL_LIMITS..., source.targetChannel ? def.targetChannel
      )
  out

# Each surface → one servo mix rule (full-rate, full-range pass-through;
# only the named source and target channel vary).
mixRuleFor = (surface) ->
  source = inputSourceById surface.inputSource
  {
    targetChannel: surface.targetChannel
    inputSource: source.code
    rate: 100
    speed: 0
    min: -100
    max: 100
    box: 0
  }

useServoStore = create (set, get) ->
  defaults = clone { surfaces: normalizeSurfaces() }

  setSurfaceSource: (id, sourceId) ->
    return unless SURFACE_DEFAULTS[id]?
    return unless inputSourceById(sourceId)?
    surfaces = clone get().draft.surfaces
    surfaces[id].inputSource = sourceId
    set { draft: { get().draft..., surfaces }, dirty: true }

  setSurfaceChannel: (id, channel) ->
    return unless SURFACE_DEFAULTS[id]?
    surfaces = clone get().draft.surfaces
    surfaces[id].targetChannel = clampInt CHANNEL_LIMITS..., channel
    set { draft: { get().draft..., surfaces }, dirty: true }

  save: ->
    { mode, session, draft, loadedSession } = get()
    if mode == 'device'
      throw new Error 'No device session attached' unless session?
      unless loadedSession
        throw new Error(
          'Read the device before writing — the draft may belong ' +
          'to another craft'
        )
      index = 0
      for id in CONTROL_SURFACE_IDS
        await session.writeServoMixRule index, mixRuleFor draft.surfaces[id]
        index += 1
    saved = clone draft
    set { saved, dirty: false }
    saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown servo mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    set { session, mode: 'device', loadedSession: false }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    rules = await session.readServoMixRules()
    surfaces = clone get().draft.surfaces
    for id, index in CONTROL_SURFACE_IDS
      rule = rules[index]
      continue unless rule?
      source = INPUT_SOURCES.find((s) -> s.code is rule.inputSource)
      surfaces[id] =
        inputSource: source?.id ? SURFACE_DEFAULTS[id].inputSource
        targetChannel: clampInt(
          CHANNEL_LIMITS..., rule.targetChannel
        )
    draft = { surfaces }
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
    defaults = clone { surfaces: normalizeSurfaces() }
    set {
      mode: 'sim'
      session: null
      loadedSession: false
      draft: defaults
      saved: clone defaults
      dirty: false
    }
    defaults

  mode: 'sim'
  session: null
  loadedSession: false
  draft: defaults
  saved: clone defaults
  dirty: false

export default useServoStore
export { SURFACE_DEFAULTS, CONTROL_SURFACE_IDS, MAX_SERVO_MIX_RULES }
