###
# ORNIFLIGHT STUDIO — Sensors Store (Zustand)
#
# Polymorphic sensor document: draft ≠ saved with dirty tracking.
# The draft is a compound of two flat wire-true sub-documents —
# sensor config (MSP 96/97) and sensor alignment (126/220) — so no
# impedance exists between store and MSP. In sim mode `save` commits
# locally (dry-run); in device mode it rides the OrniFlight session,
# one SET + EEPROM_WRITE with read-back per sub-document. Calibration
# is a one-shot device request — meaningless in sim, so it throws.
# `loadedSession` pins the document to its source device.
###
import { create } from 'zustand'
import {
  DEFAULT_SENSOR_CONFIG, DEFAULT_SENSOR_ALIGNMENT
  sanitizeSensorConfig, sanitizeSensorAlignment
} from '../lib/sensorsCatalog.coffee'

clone = (value) -> JSON.parse JSON.stringify value

draftDefaults = ->
  {
    sensorConfig: clone DEFAULT_SENSOR_CONFIG
    sensorAlignment: clone DEFAULT_SENSOR_ALIGNMENT
  }

useSensorsStore = create (set, get) ->
  defaults = draftDefaults()

  setSensorConfig: (patch = {}) ->
    draft = get().draft
    sensorConfig = sanitizeSensorConfig { draft.sensorConfig..., patch... }
    return if JSON.stringify(sensorConfig) == JSON.stringify(draft.sensorConfig)
    set { draft: { draft..., sensorConfig }, dirty: true }

  setSensorAlignment: (patch = {}) ->
    draft = get().draft
    sensorAlignment = sanitizeSensorAlignment {
      draft.sensorAlignment..., patch...
    }
    return if JSON.stringify(sensorAlignment) ==
      JSON.stringify(draft.sensorAlignment)
    set { draft: { draft..., sensorAlignment }, dirty: true }

  # One-shot ACC/MAG calibration rides the device only — a sim session
  # has no gyroscope to train, so the request is rejected loudly.
  calibrateAccel: ->
    { mode, session } = get()
    try
      throw new Error 'Sensor calibration requires a device session' unless session?
      unless mode == 'device' and get().loadedSession == session
        throw new Error 'Read device sensor configuration before calibrating'
      await session.calibrateAccelerometer()
    catch error
      set { lastError: error?.message or 'Accelerometer calibration failed' }
      throw error
    set { lastError: null }
    true

  calibrateMag: ->
    { mode, session } = get()
    try
      throw new Error 'Sensor calibration requires a device session' unless session?
      unless mode == 'device' and get().loadedSession == session
        throw new Error 'Read device sensor configuration before calibrating'
      await session.calibrateMagnetometer()
    catch error
      set { lastError: error?.message or 'Magnetometer calibration failed' }
      throw error
    set { lastError: null }
    true

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device sensor configuration before saving'
        sensorConfig = await session.writeSensorConfig draft.sensorConfig
        sensorAlignment = await session.writeSensorAlignment(
          draft.sensorAlignment
        )
        saved = { sensorConfig, sensorAlignment }
      else
        saved = draft
    catch error
      set { lastError: error?.message or 'Sensor save failed' }
      throw error
    saved = clone saved
    set { saved, draft: clone(saved), dirty: false, lastError: null }
    clone saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown sensor mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    try
      throw new Error 'No device session attached' unless session?
      sensorConfig = await session.readSensorConfig()
      sensorAlignment = await session.readSensorAlignment()
      draft = {
        sensorConfig: if sensorConfig?
          sensorConfig
        else
          clone DEFAULT_SENSOR_CONFIG
        sensorAlignment: if sensorAlignment?
          sensorAlignment
        else
          clone DEFAULT_SENSOR_ALIGNMENT
      }
    catch error
      set { lastError: error?.message or 'Sensor read failed' }
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

export default useSensorsStore
