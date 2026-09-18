###
# ORNIFLIGHT STUDIO — Ornithopter Store (Zustand)
#
# The unified body-plan document: kernel (Direktantrieb /
# Getriebe), mixer profile (firmware MixerProfile enum
# 0…7), servo speed, per-servo trims, the three flight
# profiles (CH7 → active index) with their glide degrees.
#
# Polymorphic — sim mode holds full authority and mirrors
# mappable fields into the engine singleton; device mode rides
# the OrniFlight session with the loadedSession guard:
#   · modelName  → session.setCraftName
#   · servoSpeed → per-servo rate (60000/ms per 60°)
#   · glideAngle → session.writeGlideDegree (active profile)
# Kernel/profile remain studio-side body-plan metadata on a
# device — the firmware carries no MixerProfile enum.
###
import { create } from 'zustand'
import { engine } from '../simulation/engine.coffee'
import {
  KERNELS, MIXER_PROFILES, profilesForKernel, firstForKernel, profileById
} from '../lib/mixerCatalog.coffee'
import {
  WAVEFORM_DEFAULTS, WAVEFORM_LIMITS
} from '../simulation/waveform.coffee'
import {
  AIRFRAME_LIMITS, MOUNT_LIMITS, MOUNT_PAIRS, defaultAirframe
} from '../lib/airframeCatalog.coffee'

SPEED_LIMITS = [40, 400]
TRIM_LIMITS = [-50, 50]
GLIDE_LIMITS = [-15, 15]
PROFILE_IDS = [0..7]
WAVEFORM_KEYS = Object.keys WAVEFORM_DEFAULTS
AIRFRAME_FIELD_NAMES = Object.keys AIRFRAME_LIMITS
MOUNT_FIELD_NAMES = Object.keys MOUNT_LIMITS

TRIM_FIELDS = [
  'leftWing', 'rightWing', 'rudder', 'backLeftWing'
  'vtailLeft', 'vtailRight', 'elevator'
]
# Closed set — inherited object keys never pass.
DOC_FIELDS = [
  'modelName', 'kernel', 'profileId', 'servoSpeed', 'activeProfile'
]

clone = (value) -> JSON.parse JSON.stringify value

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

defaultProfile = ->
  glideAngle: 0
  flappingAngle: 0
  waveform: { WAVEFORM_DEFAULTS... }

defaultDraft = ->
  modelName: 'Orni I'
  kernel: 'servo'
  profileId: 1
  servoSpeed: 220
  trims:
    leftWing: 0
    rightWing: 0
    rudder: 0
    backLeftWing: 0
    vtailLeft: 0
    vtailRight: 0
    elevator: 0
  airframe: defaultAirframe()
  profiles: [defaultProfile(), defaultProfile(), defaultProfile()]
  activeProfile: 0

# Airframe → engine: geometry/mass/mounts mirror into the 3D viewport.
# Mount station/vertical normalise to the engine's σ grid (±300 mm ≈ ±1 σ).
mirrorAirframe = (airframe) ->
  engine.setAirframe
    geometry: { wingSpan: airframe.wingSpan, chord: airframe.chord }
    mass:
      totalMass: airframe.totalMass
      cgX: airframe.cgX
      cgZ: airframe.cgZ
      cgLat: airframe.cgLat
    servoMounts: airframe.mounts.map (m, i) ->
      {
        index: i
        x: 0
        z: m.station / 300
        y: m.vertical / 300
        angle: m.angle
        phaseShift: 0
      }

mirrorToEngine = (draft) ->
  # Servo speed rides the engine as the travel-time of one stroke.
  engine.setSimulationParams
    servoTravelTimeMs: draft.servoSpeed
  name = profileById(draft.profileId).arrangement
  engine.applyArrangement name if name
  mirrorAirframe draft.airframe
  # Waveform + flight profiles — the stroke's shape soul mirrors live.
  for i in [0...3]
    engine.setGlideAngle i, draft.profiles[i].glideAngle
    engine.setFlappingAngle i, draft.profiles[i].flappingAngle
    for k in WAVEFORM_KEYS
      engine.setFlightProfileParam i, k, draft.profiles[i].waveform[k]
  engine.applyFlightProfile draft.activeProfile

useOrnithopterStore = create (set, get) ->
  defaults = defaultDraft()

  setField: (field, value) ->
    return unless field in DOC_FIELDS
    draft = clone get().draft
    draft[field] = value
    set { draft, dirty: true }

  setModelName: (name) ->
    name = String(name or '').slice 0, 32
    set
      draft: { get().draft..., modelName: name }
      dirty: true

  setKernel: (kernel) ->
    unless KERNELS.some (k) -> k.id is kernel
      throw new Error "Unknown kernel: #{kernel}"
    draft = clone get().draft
    draft.kernel = kernel
    draft.profileId = firstForKernel kernel
    set { draft, dirty: true }
    mirrorToEngine draft

  setProfileId: (id) ->
    id = Number id
    unless Number.isFinite(id) and 0 <= id <= 7
      throw new Error "Unknown mixer profile: #{id}"
    draft = { get().draft..., profileId: id }
    set { draft, dirty: true }
    mirrorToEngine draft

  setServoSpeed: (value) ->
    set
      draft:
        { get().draft..., servoSpeed: clampInt SPEED_LIMITS..., value }
      dirty: true

  applySpeedPreset: (presetId) ->
    draft = clone get().draft
    draft.servoSpeed = switch presetId
      when 'smooth' then 280
      when 'tuned' then 220
      when 'direct' then 150
      when 'swift' then 100
      when 'violent' then 60
      else draft.servoSpeed
    set { draft, dirty: true }

  setTrim: (prop, value) ->
    return unless prop in TRIM_FIELDS
    trims = clone get().draft.trims
    trims[prop] = clampInt TRIM_LIMITS..., value
    set
      draft: { get().draft..., trims }
      dirty: true

  setGlideAngle: (index, value) ->
    return unless 0 <= index < 3
    profiles = clone get().draft.profiles
    profiles[index].glideAngle = clampInt GLIDE_LIMITS..., value
    set
      draft: { get().draft..., profiles }
      dirty: true
    engine.setGlideAngle index, profiles[index].glideAngle

  setFlappingAngle: (index, value) ->
    return unless 0 <= index < 3
    profiles = clone get().draft.profiles
    profiles[index].flappingAngle = clampInt GLIDE_LIMITS..., value
    set
      draft: { get().draft..., profiles }
      dirty: true
    engine.setFlappingAngle index, profiles[index].flappingAngle

  setWaveformParam: (index, key, value) ->
    return unless 0 <= index < 3
    return unless key in WAVEFORM_KEYS
    limits = WAVEFORM_LIMITS[key]
    profiles = clone get().draft.profiles
    profiles[index].waveform[key] =
      clampInt limits.min, limits.max, value
    set
      draft: { get().draft..., profiles }
      dirty: true
    engine.setFlightProfileParam index, key, profiles[index].waveform[key]
    engine.applyFlightProfile index if index is get().draft.activeProfile

  setActiveProfile: (index) ->
    index = clampInt 0, 2, index
    set
      draft: { get().draft..., activeProfile: index }
      dirty: true
    engine.applyFlightProfile index

  setAirframeField: (field, value) ->
    return unless field in AIRFRAME_FIELD_NAMES
    limits = AIRFRAME_LIMITS[field]
    airframe = clone get().draft.airframe
    airframe[field] = clampInt limits.min, limits.max, value
    set
      draft: { get().draft..., airframe }
      dirty: true
    mirrorAirframe airframe

  setMountField: (index, field, value) ->
    return unless 0 <= index < MOUNT_PAIRS
    return unless field in MOUNT_FIELD_NAMES
    limits = MOUNT_LIMITS[field]
    airframe = clone get().draft.airframe
    mounts = clone airframe.mounts
    mounts[index][field] = clampInt limits.min, limits.max, value
    airframe.mounts = mounts
    set
      draft: { get().draft..., airframe }
      dirty: true
    mirrorAirframe airframe

  save: ->
    { mode, session, draft, loadedSession } = get()
    if mode == 'device'
      throw new Error 'No device session attached' unless session?
      unless loadedSession
        throw new Error(
          'Read the device before writing — the draft may belong ' +
          'to another craft'
        )
      await session.setCraftName draft.modelName
      profile = MIXER_PROFILES[draft.profileId]
      rate = clampInt 0, 255, Math.round 60000 / draft.servoSpeed
      for i in [0...profile.servos]
        await session.writeServoConfiguration i, { rate }
      await session.writeGlideDegree(
        draft.profiles[draft.activeProfile].glideAngle
      )
    else
      mirrorToEngine draft
    saved = clone draft
    set { saved, dirty: false }
    saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown ornithopter mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    set { session, mode: 'device', loadedSession: false }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    configs = await session.readServoConfigurations()
    tuning = await session.readServoTuning()
    draft = clone get().draft
    if configs.length
      rate = finiteOr 220, configs[0]?.rate
      msPer60 = if rate > 0 then Math.round 60000 / rate else 220
      draft.servoSpeed = clampInt SPEED_LIMITS..., msPer60
    draft.profiles[draft.activeProfile].glideAngle =
      clampInt GLIDE_LIMITS..., tuning?.glide ? 0
    set {
      mode: 'device'
      session
      loadedSession: true
      draft
      saved: clone draft
      dirty: false
    }
    clone draft

  reset: ->
    defaults = defaultDraft()
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

export default useOrnithopterStore