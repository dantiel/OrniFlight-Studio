###
# ORNIFLIGHT STUDIO — Safety Store (Zustand)
#
# Polymorphic safety document: draft ↔ saved with dirty tracking.
# The draft is a compound of four independent flat wire-true
# sub-documents — failsafe (MSP 75/76), arming (61/62), features
# (36/37), beeper (184/185) — so no impedance exists between store
# and MSP. In sim mode `save` commits locally (dry-run); in device
# mode it rides the OrniFlight session, one SET + EEPROM_WRITE with
# read-back per sub-document. `loadedSession` pins the document to
# its source device so values from a previous craft can never be
# written to a new one.
###
import { create } from 'zustand'
import {
  DEFAULT_FAILSAFE_CONFIG, DEFAULT_ARMING_CONFIG
  DEFAULT_FEATURE_MASK, DEFAULT_BEEPER_CONFIG
  sanitizeFailsafe, sanitizeArming, sanitizeFeatures, sanitizeBeeper
  featureSetBit, featureClearBit, beeperFlagFor
} from '../lib/safetyCatalog.coffee'

clone = (value) -> JSON.parse JSON.stringify value

draftDefaults = ->
  {
    failsafe: clone DEFAULT_FAILSAFE_CONFIG
    arming: clone DEFAULT_ARMING_CONFIG
    features: DEFAULT_FEATURE_MASK
    beeper: clone DEFAULT_BEEPER_CONFIG
  }

useSafetyStore = create (set, get) ->
  defaults = draftDefaults()

  setFailsafe: (patch = {}) ->
    draft = get().draft
    failsafe = sanitizeFailsafe { draft.failsafe..., patch... }
    return if JSON.stringify(failsafe) == JSON.stringify(draft.failsafe)
    set { draft: { draft..., failsafe }, dirty: true }

  setArming: (patch = {}) ->
    draft = get().draft
    arming = sanitizeArming { draft.arming..., patch... }
    return if JSON.stringify(arming) == JSON.stringify(draft.arming)
    set { draft: { draft..., arming }, dirty: true }

  setFeatures: (mask) ->
    features = sanitizeFeatures mask
    return if features == get().draft.features
    set { draft: { get().draft..., features }, dirty: true }

  setFeatureBit: (bit, enabled) ->
    { features } = get().draft
    mask = if enabled
      featureSetBit features, bit
    else
      featureClearBit features, bit
    get().setFeatures mask

  setBeeper: (patch = {}) ->
    draft = get().draft
    beeper = sanitizeBeeper { draft.beeper..., patch... }
    return if JSON.stringify(beeper) == JSON.stringify(draft.beeper)
    set { draft: { draft..., beeper }, dirty: true }

  # `enabled` means the condition beeps; the wire stores the inverse
  # (a set off-mask flag silences it).
  setBeeperMode: (mode, enabled) ->
    { beeper } = get().draft
    flag = beeperFlagFor mode
    offFlags = if enabled
      beeper.offFlags & ~flag
    else
      beeper.offFlags | flag
    get().setBeeper { offFlags }

  # The DShot beacon honours only RX_LOST | RX_SET — the firmware
  # masks dshotBeaconOffFlags against DSHOT_BEACON_ALLOWED_MODES.
  setBeeperBeaconMode: (mode, enabled) ->
    { beeper } = get().draft
    flag = beeperFlagFor mode
    offFlags = if enabled
      beeper.dshotBeaconOffFlags & ~flag
    else
      beeper.dshotBeaconOffFlags | flag
    get().setBeeper { dshotBeaconOffFlags: offFlags }

  save: ->
    { mode, session, draft } = get()
    try
      if mode == 'device'
        throw new Error 'No device session attached' unless session?
        unless get().loadedSession == session
          throw new Error 'Read device safety configuration before saving'
        failsafe = await session.writeFailsafeConfig draft.failsafe
        arming = await session.writeArmingConfig draft.arming
        features = await session.writeFeatureConfig draft.features
        beeper = await session.writeBeeperConfig draft.beeper
        saved = { failsafe, arming, features, beeper }
      else
        saved = draft
    catch error
      set { lastError: error?.message or 'Safety save failed' }
      throw error
    saved = clone saved
    set { saved, draft: clone(saved), dirty: false, lastError: null }
    clone saved

  revert: ->
    draft = clone get().saved
    set { draft, dirty: false, lastError: null }

  setMode: (mode) ->
    unless mode in ['sim', 'device']
      throw new Error "Unknown safety mode: #{mode}"
    set { mode }

  attachSession: (session) ->
    if session?
      set { session, mode: 'device' }
    else
      set { session: null, mode: 'sim' }

  loadFromDevice: (session = get().session) ->
    try
      throw new Error 'No device session attached' unless session?
      failsafe = await session.readFailsafeConfig()
      arming = await session.readArmingConfig()
      features = await session.readFeatureConfig()
      beeper = await session.readBeeperConfig()
      draft = {
        failsafe: if failsafe?
          failsafe
        else
          clone DEFAULT_FAILSAFE_CONFIG
        arming: if arming?
          arming
        else
          clone DEFAULT_ARMING_CONFIG
        features: if features? then features else DEFAULT_FEATURE_MASK
        beeper: if beeper?
          beeper
        else
          clone DEFAULT_BEEPER_CONFIG
      }
    catch error
      set { lastError: error?.message or 'Safety read failed' }
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

export default useSafetyStore