###
# ORNIFLIGHT STUDIO — VTX Store (Zustand)
#
# Polymorphic VTX document: draft ↔ saved with dirty tracking. The
# document IS the wire format — the MSP 88 layout (vtxType, band,
# channel, power, pitmode, freq, deviceIsReady, lowPowerDisarm) —
# so no impedance exists between store and MSP. In sim mode `save`
# commits locally (dry-run); in device mode it rides the OrniFlight
# session (MSP 88/89 + EEPROM_WRITE with read-back). `loadedSession`
# pins the document to its source device so values from a previous
# craft can never be written to a new one.
###
import { create } from 'zustand'
import {
  VTX_BANDS, VTX_CHANNEL_COUNT, VTX_POWER_COUNT
  DEFAULT_VTX_CONFIG, frequencyFor, clampFrequency
} from '../lib/vtxCatalog.coffee'

clone = (value) -> JSON.parse JSON.stringify value

validBand = (band) ->
  Number.isInteger(band) and 1 <= band <= VTX_BANDS.length

validChannel = (channel) ->
  Number.isInteger(channel) and 1 <= channel <= VTX_CHANNEL_COUNT

validPower = (power) ->
  Number.isInteger(power) and 0 <= power < VTX_POWER_COUNT

useVtxStore = create (set, get) ->
  defaults = clone DEFAULT_VTX_CONFIG

  setBandChannel: (band, channel) ->
    return unless validBand(band) and validChannel(channel)
    draft = { get().draft..., band, channel, freq: frequencyFor band, channel }
    set { draft, dirty: true }

  setBand: (band) ->
    return unless validBand band
    { channel } = get().draft
    channel = 1 unless validChannel channel
    get().setBandChannel band, channel

  setChannel: (channel) ->
    return unless validChannel channel
    { band } = get().draft
    return unless validBand band
    get().setBandChannel band, channel

  setCustomFreq: (freq) ->
    freq = clampFrequency freq
    { band, freq: current } = get().draft
    return if band == 0 and current == freq
    draft = { get().draft..., band: 0, channel: 0, freq }
    set { draft, dirty: true }

  setPower: (power) ->
    return unless validPower power
    return if power == get().draft.power
    draft = { get().draft..., power }
    set { draft, dirty: true }

  setPitMode: (pitmode) ->
    pitmode = if pitmode then 1 else 0
    return if pitmode == get().draft.pitmode
    draft = { get().draft..., pitmode }
    set { draft, dirty: true }

  setLowPowerDisarm: (lowPowerDisarm) ->
    lowPowerDisarm = if lowPowerDisarm then 1 else 0
    return if lowPowerDisarm == get().draft.lowPowerDisarm
    draft = { get().draft..., lowPowerDisarm }
    set { draft, dirty: true }

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device VTX configuration before saving'
        saved = await session.writeVtxConfig draft
      else
        saved = draft
    catch error
      set { lastError: error?.message or 'VTX save failed' }
      throw error
    saved = clone saved
    set { saved, draft: clone(saved), dirty: false, lastError: null }
    clone saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown VTX mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    try
      read = await session.readVtxConfig()
      draft = if read? then read else clone DEFAULT_VTX_CONFIG
    catch error
      set { lastError: error?.message or 'VTX read failed' }
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
    defaults = clone DEFAULT_VTX_CONFIG
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

export default useVtxStore
export { DEFAULT_VTX_CONFIG }