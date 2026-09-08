###
# ORNIFLIGHT STUDIO — Power Store (Zustand)
#
# Polymorphic power document: draft ≠ saved with dirty tracking.
# The draft is a compound of three flat wire-true sub-documents —
# battery (MSP 32/33), voltage meter (56/57), current meter (40/41)
# — so no impedance exists between store and MSP. In sim mode `save`
# commits locally (dry-run); in device mode it rides the OrniFlight
# session, one SET + EEPROM_WRITE with read-back per sub-document.
# `loadedSession` pins the document to its source device.
###
import { create } from 'zustand'
import {
  DEFAULT_BATTERY_CONFIG, DEFAULT_VOLTAGE_METER_CONFIG
  DEFAULT_CURRENT_METER_CONFIG
  sanitizeBatteryConfig, sanitizeVoltageMeterConfig
  sanitizeCurrentMeterConfig
} from '../lib/powerCatalog.coffee'

clone = (value) -> JSON.parse JSON.stringify value

draftDefaults = ->
  {
    battery: clone DEFAULT_BATTERY_CONFIG
    voltageMeter: clone DEFAULT_VOLTAGE_METER_CONFIG
    currentMeter: clone DEFAULT_CURRENT_METER_CONFIG
  }

usePowerStore = create (set, get) ->
  defaults = draftDefaults()

  setBattery: (patch = {}) ->
    draft = get().draft
    battery = sanitizeBatteryConfig { draft.battery..., patch... }
    return if JSON.stringify(battery) == JSON.stringify(draft.battery)
    set { draft: { draft..., battery }, dirty: true }

  setVoltageMeter: (patch = {}) ->
    draft = get().draft
    voltageMeter = sanitizeVoltageMeterConfig {
      draft.voltageMeter..., patch...
    }
    return if JSON.stringify(voltageMeter) ==
      JSON.stringify(draft.voltageMeter)
    set { draft: { draft..., voltageMeter }, dirty: true }

  setCurrentMeter: (patch = {}) ->
    draft = get().draft
    currentMeter = sanitizeCurrentMeterConfig {
      draft.currentMeter..., patch...
    }
    return if JSON.stringify(currentMeter) ==
      JSON.stringify(draft.currentMeter)
    set { draft: { draft..., currentMeter }, dirty: true }

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device power configuration before saving'
        battery = await session.writeBatteryConfig draft.battery
        voltageMeter = await session.writeVoltageMeterConfig(
          draft.voltageMeter
        )
        currentMeter = await session.writeCurrentMeterConfig(
          draft.currentMeter
        )
        saved = { battery, voltageMeter, currentMeter }
      else
        saved = draft
    catch error
      set { lastError: error?.message or 'Power save failed' }
      throw error
    saved = clone saved
    set { saved, draft: clone(saved), dirty: false, lastError: null }
    clone saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown power mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    try
      throw new Error 'No device session attached' unless session?
      battery = await session.readBatteryConfig()
      voltageMeter = await session.readVoltageMeterConfig()
      currentMeter = await session.readCurrentMeterConfig()
      draft = {
        battery: if battery? then battery else clone DEFAULT_BATTERY_CONFIG
        voltageMeter: if voltageMeter?
          voltageMeter
        else
          clone DEFAULT_VOLTAGE_METER_CONFIG
        currentMeter: if currentMeter?
          currentMeter
        else
          clone DEFAULT_CURRENT_METER_CONFIG
      }
    catch error
      set { lastError: error?.message or 'Power read failed' }
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

export default usePowerStore
