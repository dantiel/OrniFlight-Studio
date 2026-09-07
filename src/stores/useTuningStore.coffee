###
# ORNIFLIGHT STUDIO — Tuning Store (Zustand)
#
# Polymorphic PID/Rate/ONDAS/Filter tuning document: draft ↔ saved
# with dirty tracking. In sim mode `save` commits locally (dry-run);
# in device mode it rides the OrniFlight session (MSP 112/202, 111/204,
# 92/193, 114/206 + EEPROM_WRITE with section-wise read-back). PID gains
# and ONDAS params mirror into the engine singleton so the live
# simulation follows the draft immediately; rates, filters and the flap
# axis stay document-only because the sim does not model them.
# A device save requires a prior successful read of that session —
# `loadedSession` pins the document to its source device so values from
# a previous craft can never be written to a newly connected one.
###
import { create } from 'zustand'
import { engine } from '../simulation/engine.coffee'
import {
  ONDAS_DEFAULTS, ONDAS_KEYS, PID_AXES, PID_TERMS, TUNING_FALLBACKS
} from '../protocol/mspDecoders.coffee'

clone = (value) -> JSON.parse JSON.stringify value

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

# Prototype-pollution guard: never traverse or write magic segments.
FORBIDDEN_SEGMENTS = new Set ['__proto__', 'constructor', 'prototype']

isObjectLike = (value) -> value? and typeof value == 'object'

validPath = (parts) ->
  parts.length and parts.every (part) ->
    part isnt '' and not FORBIDDEN_SEGMENTS.has(part)

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

RC_RATE_MAX = 250
RATE_MAX = 100
ONDAS_MAX = 100
NOTCH_Q_MAX = 16
HZ_MAX = 65535
# PID gains ride a u16×1000 wire field (MSP 112/202), so the ceiling is
# 65535 / 1000. Clamping here keeps sim and device documents identical
# and prevents encode-side truncation from surfacing as a read-back
# mismatch on save.
PID_GAIN_MAX = 65.535

TUNING_DEFAULTS = Object.freeze
  pid: TUNING_FALLBACKS.pid
  rate: TUNING_FALLBACKS.rate
  ondas: ONDAS_DEFAULTS
  filter: TUNING_FALLBACKS.filter

clampGain = (value, fallback) ->
  Math.max 0, Math.min PID_GAIN_MAX, finiteOr fallback, value

normalizePid = (pid = {}) ->
  normalized = {}
  for axis in PID_AXES
    source = pid[axis] or {}
    fallback = TUNING_DEFAULTS.pid[axis]
    normalized[axis] =
      P: clampGain source.P, fallback.P
      I: clampGain source.I, fallback.I
      D: clampGain source.D, fallback.D
  normalized

normalizeRate = (rate = {}) ->
  rcRate: clampInt 0, RC_RATE_MAX, rate.rcRate ? TUNING_DEFAULTS.rate.rcRate
  superRate: clampInt 0, RATE_MAX, rate.superRate ? TUNING_DEFAULTS.rate.superRate
  expo: clampInt 0, RATE_MAX, rate.expo ? TUNING_DEFAULTS.rate.expo

normalizeOndas = (ondas = {}) ->
  normalized = {}
  for key in ONDAS_KEYS
    normalized[key] = clampInt 0, ONDAS_MAX, ondas[key] ? ONDAS_DEFAULTS[key]
  normalized

normalizeFilter = (filter = {}) ->
  gyroDlpfHz: clampInt 0, HZ_MAX, filter.gyroDlpfHz ? 0
  gyroNotchHz: clampInt 0, HZ_MAX, filter.gyroNotchHz ? 0
  gyroNotchQ: clampInt 0, NOTCH_Q_MAX, filter.gyroNotchQ ? 0
  dTermDlpfHz: clampInt 0, HZ_MAX, filter.dTermDlpfHz ? 0

normalizeDraft = (draft = {}) ->
  pid: normalizePid draft.pid
  rate: normalizeRate draft.rate
  ondas: normalizeOndas draft.ondas
  filter: normalizeFilter draft.filter

# Engine mirror: only the nine modeled gains and the ONDAS params —
# the flap axis and rate/filter are document-only (see header).
MIRROR_AXES = ['roll', 'pitch', 'yaw']

applyToEngine = (draft) ->
  for axis in MIRROR_AXES
    for term in PID_TERMS
      engine.setPidGain "#{axis}_#{term}", draft.pid[axis][term]
  for key in ONDAS_KEYS
    engine.setOndasParam key, draft.ondas[key]

useTuningStore = create (set, get) ->
  defaults = clone TUNING_DEFAULTS

  setField: (path, value) ->
    parts = String(path or '').split '.'
    return unless validPath parts
    section = parts[0]
    next = clone get().draft
    node = next
    leaf = parts.pop()
    for part in parts
      if isObjectLike(node)
        node = node[part] ?= {}
      else
        return
    return unless isObjectLike node
    node[leaf] = value
    draft = normalizeDraft next
    # Only the two modeled sections mirror into the engine; rate and
    # filter edits stay document-only and skip 19 redundant writes.
    applyToEngine draft if section in ['pid', 'ondas']
    set { draft, dirty: true }

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device tuning before saving'
        saved = normalizeDraft await session.writeTuning draft
      else
        saved = normalizeDraft draft
    catch error
      set { lastError: error?.message or 'Tuning save failed' }
      throw error
    applyToEngine saved
    set {
      saved: clone(saved)
      draft: clone(saved)
      dirty: false
      lastError: null
    }
    clone saved

  revert: ->
    draft = clone get().saved
    applyToEngine draft
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown tuning mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    try
      read = await session.readTuning()
    catch error
      set { lastError: error?.message or 'Tuning read failed' }
      throw error
    draft = normalizeDraft read
    applyToEngine draft
    set {
      mode: 'device'
      session
      loadedSession: session
      draft: clone draft
      saved: clone draft
      dirty: false
      lastError: null
    }
    clone draft

  reset: ->
    defaults = clone TUNING_DEFAULTS
    applyToEngine defaults
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

export default useTuningStore
export { TUNING_DEFAULTS, PID_GAIN_MAX }
