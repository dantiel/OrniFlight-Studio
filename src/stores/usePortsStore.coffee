###
# ORNIFLIGHT STUDIO — Ports Store (Zustand)
#
# Polymorphic serial port document: draft ↔ saved with dirty
# tracking. The document IS the wire format — 7-byte CF_SERIAL_CONFIG
# records (identifier, functionMask u16, four baudrate indices) —
# so no impedance exists between store and MSP 54/55. In sim mode
# `save` commits locally (dry-run); in device mode it rides the
# OrniFlight session (SET_CF_SERIAL_CONFIG + EEPROM_WRITE with
# read-back). `loadedSession` pins the document to its source device.
# Function toggles run firmware arbitration: enabling a function
# clears every conflicting function on the same port.
###
import { create } from 'zustand'
import {
  SIM_PORT_DEFAULTS, BAUD_FIELDS, clampBaud, toggleFunction
} from '../lib/serialCatalog.coffee'

clonePorts = (ports) -> ports.map (port) -> { port... }

normalizePorts = (ports = []) ->
  for port in ports
    identifier: port.identifier ? 0
    functionMask: (port.functionMask ? 0) & 0xFFFF
    mspBaud: clampBaud port.mspBaud
    gpsBaud: clampBaud port.gpsBaud
    telemetryBaud: clampBaud port.telemetryBaud
    blackboxBaud: clampBaud port.blackboxBaud

BAUD_FIELD_NAMES = Object.freeze (field for [field] in BAUD_FIELDS)

usePortsStore = create (set, get) ->
  defaults = clonePorts SIM_PORT_DEFAULTS

  setPortFunction: (identifier, functionId, enabled) ->
    ports = clonePorts get().draft
    port = ports.find (p) -> p.identifier == identifier
    return unless port?
    next = toggleFunction port.functionMask, functionId, Boolean(enabled)
    return if next == port.functionMask
    port.functionMask = next
    set { draft: ports, dirty: true }

  setPortBaud: (identifier, field, value) ->
    return unless field in BAUD_FIELD_NAMES
    ports = clonePorts get().draft
    port = ports.find (p) -> p.identifier == identifier
    return unless port?
    value = clampBaud value
    return if port[field] == value
    port[field] = value
    set { draft: ports, dirty: true }

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device port configuration before saving'
        readBack = await session.writeSerialConfig draft
        saved = normalizePorts readBack
      else
        saved = normalizePorts draft
    catch error
      set { lastError: error?.message or 'Port save failed' }
      throw error
    saved = clonePorts saved
    set { saved, draft: clonePorts(saved), dirty: false, lastError: null }
    clonePorts saved

  revert: ->
    draft = clonePorts get().saved
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown ports mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    try
      read = await session.readSerialConfig()
      draft =
        if read?.length then normalizePorts read
        else clonePorts SIM_PORT_DEFAULTS
    catch error
      set { lastError: error?.message or 'Port read failed' }
      throw error
    draft = clonePorts draft
    set {
      mode: 'device'
      session
      loadedSession: session
      draft
      saved: clonePorts draft
      dirty: false
      lastError: null
    }
    clonePorts draft

  reset: ->
    defaults = clonePorts SIM_PORT_DEFAULTS
    set {
      mode: 'sim'
      session: null
      loadedSession: null
      draft: clonePorts defaults
      saved: clonePorts defaults
      dirty: false
      lastError: null
    }
    defaults

  mode: 'sim'
  session: null
  loadedSession: null
  draft: defaults
  saved: clonePorts defaults
  dirty: false
  lastError: null

export default usePortsStore
export { SIM_PORT_DEFAULTS, BAUD_FIELD_NAMES }