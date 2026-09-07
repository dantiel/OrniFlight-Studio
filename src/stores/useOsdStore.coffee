###
# ORNIFLIGHT STUDIO — OSD Store (Zustand)
#
# Polymorphic OSD layout document: draft ↔ saved with dirty tracking.
# The document IS the wire format — items as raw u16[52] item positions
# (x | y << 5 | profileVisibility << 11), so no impedance exists between
# store and MSP. In sim mode `save` commits locally (dry-run); in device
# mode it rides the OrniFlight session (MSP 84/85 + EEPROM_WRITE with
# read-back). A device save requires a prior successful read of that
# session — `loadedSession` pins the document to its source device so
# values from a previous craft can never be written to a new one.
###
import { create } from 'zustand'
import {
  OSD_DEFAULTS, OSD_ITEM_COUNT, OSD_PROFILE_COUNT
  OSD_DEFAULT_PROFILE_INDEX, clampCell, movePos, sanitizePos
  setVisibleInProfile, toggleVisibleInProfile
} from '../lib/osdCatalog.coffee'

cloneItems = (items) -> (pos for pos in items)

validIndex = (index) ->
  Number.isInteger(index) and 0 <= index < OSD_ITEM_COUNT

validProfile = (profileIndex) ->
  Number.isInteger(profileIndex) and
    1 <= profileIndex <= OSD_PROFILE_COUNT

# Every slot exists, u16, wire-masked; holes fall back to the firmware
# defaults so the grid is always complete.
normalizeItems = (items) ->
  normalized = (OSD_DEFAULTS[i] for i in [0...OSD_ITEM_COUNT])
  for i in [0...OSD_ITEM_COUNT]
    normalized[i] = sanitizePos items[i] if items?[i]?
  normalized

useOsdStore = create (set, get) ->
  defaults = cloneItems OSD_DEFAULTS

  setItemPos: (index, x, y) ->
    return unless validIndex index
    { x, y } = clampCell x, y
    draft = get().draft.slice()
    draft[index] = movePos draft[index], x, y
    set { draft, dirty: true }

  setItemVisible: (index, profileIndex, visible) ->
    return unless validIndex(index) and validProfile(profileIndex)
    draft = get().draft.slice()
    draft[index] = setVisibleInProfile draft[index], profileIndex, visible
    set { draft, dirty: true }

  toggleItemVisibility: (index, profileIndex = get().profileIndex) ->
    return unless validIndex(index) and validProfile(profileIndex)
    draft = get().draft.slice()
    draft[index] = toggleVisibleInProfile draft[index], profileIndex
    set { draft, dirty: true }

  # Palette drop-in: move to a cell and make visible in the active
  # profile. Toggling off afterwards leaves the position intact.
  placeItem: (index, cell) ->
    return unless validIndex index
    { x, y } = clampCell cell?.x, cell?.y
    draft = get().draft.slice()
    draft[index] = movePos draft[index], x, y
    draft[index] = setVisibleInProfile(
      draft[index], get().profileIndex, true
    )
    set { draft, dirty: true }

  setProfileIndex: (profileIndex) ->
    return unless validProfile profileIndex
    set { profileIndex }

  beginDrag: (index) ->
    return unless validIndex index
    set {
      dragState: {
        index, origin: get().draft[index], wasDirty: get().dirty
      }
    }

  dragTo: (x, y) ->
    drag = get().dragState
    return unless drag?
    { x, y } = clampCell x, y
    next = movePos get().draft[drag.index], x, y
    return if next == get().draft[drag.index]
    draft = get().draft.slice()
    draft[drag.index] = next
    set { draft, dirty: true }

  dropAt: (x, y) ->
    get().dragTo x, y
    set { dragState: null }

  cancelDrag: ->
    drag = get().dragState
    return unless drag?
    draft = get().draft.slice()
    draft[drag.index] = drag.origin
    set { draft, dirty: drag.wasDirty, dragState: null }

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device OSD layout before saving'
        readBack = await session.writeOsdConfig { items: draft }
        saved = normalizeItems readBack?.items
      else
        saved = normalizeItems draft
    catch error
      set { lastError: error?.message or 'OSD save failed' }
      throw error
    saved = cloneItems saved
    set {
      saved
      draft: cloneItems saved
      dirty: false
      lastError: null
    }
    cloneItems saved

  revert: ->
    draft = cloneItems get().saved
    set { draft, dirty: false, dragState: null, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown OSD mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    throw new Error 'No device session attached' unless session?
    try
      read = await session.readOsdConfig()
      draft = normalizeItems read?.items
    catch error
      set { lastError: error?.message or 'OSD read failed' }
      throw error
    profileIndex = Math.max(
      1, Math.min OSD_PROFILE_COUNT,
        (read?.profileIndex ? OSD_DEFAULT_PROFILE_INDEX)
    )
    draft = cloneItems draft
    set {
      mode: 'device'
      session
      loadedSession: session
      draft
      saved: cloneItems draft
      profileIndex
      dirty: false
      dragState: null
      lastError: null
    }
    cloneItems draft

  reset: ->
    defaults = cloneItems OSD_DEFAULTS
    set {
      mode: 'sim'
      session: null
      loadedSession: null
      draft: cloneItems defaults
      saved: cloneItems defaults
      profileIndex: OSD_DEFAULT_PROFILE_INDEX
      dirty: false
      dragState: null
      lastError: null
    }
    defaults

  mode: 'sim'
  session: null
  loadedSession: null
  draft: defaults
  saved: cloneItems defaults
  profileIndex: OSD_DEFAULT_PROFILE_INDEX
  dirty: false
  dragState: null
  lastError: null

export default useOsdStore
