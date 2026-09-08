###
# ORNIFLIGHT STUDIO — Configuration Store (Zustand)
#
# Polymorphic airframe configuration document: draft ↔ saved with
# dirty tracking. In sim mode `save` commits locally; in device mode
# it rides the OrniFlight session (MSP 212 + EEPROM_WRITE). Geometry,
# mass, CG and servo mounts are local model state — OrniFlight
# exposes no MSP codes for them — while servo configurations sync
# through MSP 120/212. Edits mirror into the engine singleton so the
# 3D preview follows the draft immediately.
###
import { create } from 'zustand'
import { engine } from '../simulation/engine.coffee'
import { deriveGeometry } from '../simulation/OrnithopterModel.coffee'

PAIR_MIN = 1
PAIR_MAX = 4

clone = (value) -> JSON.parse JSON.stringify value

DEFAULT_TOTAL_MASS = 520

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

# Prototype-pollution guard: never traverse or write magic segments.
# `node['__proto__']` resolves to Object.prototype (truthy), so a naive
# descent turns `setField '__proto__.polluted', v` into a global write.
FORBIDDEN_SEGMENTS = new Set ['__proto__', 'constructor', 'prototype']

isObjectLike = (value) -> value? and typeof value == 'object'

validPath = (parts) ->
  parts.length and parts.every (part) ->
    part isnt '' and not FORBIDDEN_SEGMENTS.has(part)

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

normalizeGeometry = (geometry = {}) -> deriveGeometry geometry

normalizeMass = (mass = {}) ->
  {
    mass...
    totalMass: finiteOr DEFAULT_TOTAL_MASS, mass.totalMass
    cgX: finiteOr 0, mass.cgX
    cgZ: finiteOr 0, mass.cgZ
  }

# Wire-true servo defaults — the firmware servoParam_t has no
# angle fields; the 4-byte MSP 120 trailer carries glide + ONDAS.
defaultServos = ->
  engine.servos.map (servo) -> {
    index: servo.index
    min: servo.min
    max: servo.max
    middle: servo.midpoint
    rate: servo.rate
    forwardFromChannel: servo.index
    reversedSources: 0
  }

normalizeMounts = (pairCount, mounts = []) ->
  normalized = []
  for i in [0...pairCount]
    source = mounts.find((m) -> m?.index == i)
    source ?= { index: i, x: 0, z: 0, angle: 0 }
    normalized.push {
      index: i
      x: finiteOr 0, source.x
      z: finiteOr 0, source.z
      angle: finiteOr 0, source.angle
    }
  normalized

normalizeDraft = (draft = {}) ->
  pairCount = clampInt PAIR_MIN, PAIR_MAX, draft.pairCount ? 2
  {
    draft...
    pairCount
    geometry: normalizeGeometry draft.geometry
    mass: normalizeMass draft.mass
    servoMounts: normalizeMounts pairCount, draft.servoMounts
  }

buildDefaults = ->
  normalizeDraft {
    geometry: {}
    mass: { totalMass: DEFAULT_TOTAL_MASS, cgX: 0, cgZ: 0 }
    pairCount: 2
    servos: defaultServos()
    servoMounts: []
  }

AIRFRAME_DEFAULTS = Object.freeze buildDefaults()

applyToEngine = (draft) ->
  engine.setAirframe {
    geometry: draft.geometry
    mass: draft.mass
    pairCount: draft.pairCount
    servoMounts: draft.servoMounts
  }

useConfigurationStore = create (set, get) ->
  defaults = clone AIRFRAME_DEFAULTS

  setField: (path, value) ->
    parts = String(path or '').split '.'
    return unless validPath parts
    next = clone get().draft
    node = next
    leaf = parts.pop()
    for part in parts
      if Array.isArray(node) and /^\d+$/.test part
        node = node[Number part] ?= {}
      else if isObjectLike(node)
        node = node[part] ?= {}
      else
        return
    return unless isObjectLike node
    node[leaf] = value
    draft = normalizeDraft next
    applyToEngine draft
    set { draft, dirty: true }

  save: (servoConfigs = null) ->
    { mode, session, draft } = get()
    if mode == 'device'
      throw new Error 'No device session attached' unless session?
      configs = servoConfigs ? defaultServos()
      for config, i in configs
        await session.writeServoConfiguration i, config
    saved = normalizeDraft draft
    applyToEngine saved
    set { saved: clone(saved), draft: clone(saved), dirty: false }
    clone saved

  revert: ->
    draft = clone get().saved
    applyToEngine draft
    set { draft, dirty: false }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown configuration mode: #{mode}"
    set { mode }

  attachSession: (session) -> set { session }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    configs = await session.readServoConfigurations()
    servos = if configs.length then configs else defaultServos()
    draft = normalizeDraft { get().draft..., servos }
    set {
      mode: 'device'
      session
      draft: clone draft
      saved: clone draft
      dirty: false
    }
    clone draft

  reset: ->
    defaults = clone AIRFRAME_DEFAULTS
    applyToEngine defaults
    set {
      mode: 'sim'
      session: null
      draft: clone defaults
      saved: clone defaults
      dirty: false
    }
    defaults

  mode: 'sim'
  session: null
  draft: defaults
  saved: clone defaults
  dirty: false

export default useConfigurationStore
export { AIRFRAME_DEFAULTS }