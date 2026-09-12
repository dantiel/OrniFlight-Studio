###
# ORNIFLIGHT STUDIO — Servo Store (Zustand)
#
# Horus-centred servo document: servo configurations (MSP 120/212),
# glide degree (MSP 212 ≤4-byte payload), servo mix rules (MSP
# 241/242) and the wing-mapping appendix (MSP 94/95). Polymorphic:
# sim mode commits locally and mirrors into the engine singleton;
# device mode rides the OrniFlight session. The loadedSession guard
# forces a device read before any device write — a foreign device
# is never overwritten by an unloaded draft.
###
import { create } from 'zustand'
import { engine } from '../simulation/engine.coffee'
import {
  MAX_SERVO_CONFIGS, MAX_SERVO_MIX_RULES, ORNITHOPTER_PAIR_COUNT
} from '../protocol/mspDecoders.coffee'
import { servoPresetById } from '../lib/servoCatalog.coffee'

PWM_LIMITS = [500, 2500]
RATE_LIMITS = [-125, 125]
GLIDE_LIMITS = [-90, 90]
SIGNED_LIMITS = [-128, 127]
GAIN_LIMITS = [0, 100]
CHANNEL_LIMITS = [0, 255]
U8_LIMITS = [0, 255]
PROFILE_INDEX_LIMITS = [0, 3]

SIGNED_WING_FIELDS = [
  'flapBaseAmplitude', 'cadence', 'ferocityD', 'balance'
  'warpGain', 'warpYawGain'
]
# Firmware msp.c serialises these as raw u8 (no 0–100 domain comment).
FULL_U8_WING_FIELDS = [
  'itermRelaxCutoff', 'servoMaxAmplitude', 'flapMagnitude'
  'freqChannel', 'freqMin', 'freqMax'
]
PAIR_ARRAY_FIELDS = [
  'servoMountAngle', 'flappingPhaseShift', 'wingOriginOffset'
]
WING_GAIN_FIELDS = [
  'ferocityP', 'ferocityRoll', 'ferocityYaw', 'anchorGain'
  'resonanceGain', 'prescience', 'espelho', 'saudade', 'ssff'
]
# Closed set: setWingField routes catalog fields only — inherited
# object keys ('constructor', '__proto__', 'toString') never pass.
WING_FIELD_NAMES = [
  SIGNED_WING_FIELDS..., FULL_U8_WING_FIELDS..., WING_GAIN_FIELDS...
  'servoTravelTimeMs', 'profileIndex'
]

clone = (value) -> JSON.parse JSON.stringify value

finiteOr = (fallback, value) ->
  return fallback unless value?
  number = Number(value)
  if Number.isFinite(number) then number else fallback

clampInt = (lo, hi, value) ->
  Math.max lo, Math.min hi, Math.round finiteOr lo, value

# The wire carries 8 servoParam_t slots; the engine mirrors only
# its 4 physical servos — the remaining slots ride store-only.
defaultServos = ->
  servos = engine.servos.map (servo) -> {
    index: servo.index
    min: servo.min
    max: servo.max
    middle: servo.midpoint
    rate: servo.rate
    forwardFromChannel: servo.index
    reversedSources: 0
  }
  while servos.length < MAX_SERVO_CONFIGS
    index = servos.length
    servos.push {
      index
      min: 1000
      max: 2000
      middle: 1500
      rate: 100
      forwardFromChannel: index
      reversedSources: 0
    }
  servos

defaultMixRules = ->
  for i in [0...MAX_SERVO_MIX_RULES]
    {
      index: i
      targetChannel: 0
      inputSource: 0
      rate: 0
      speed: 0
      min: 0
      max: 100
      box: 0
    }

# Wing-mapping appendix defaults mirror the engine's ONDAS soul.
defaultWing = ->
  flapBaseAmplitude: 45
  itermRelaxCutoff: 0
  cadence: 30
  ferocityD: 40
  balance: 10
  ferocityP: 20
  ferocityRoll: 30
  ferocityYaw: 25
  warpGain: 20
  warpYawGain: 15
  anchorGain: 50
  resonanceGain: 10
  servoMountAngle: [0, 0, 0, 0]
  flappingPhaseShift: [0, 0, 0, 0]
  prescience: 5
  espelho: 0
  saudade: 0
  ssff: 20
  servoTravelTimeMs: 300
  servoMaxAmplitude: 45
  flapMagnitude: 45
  wingOriginOffset: [0, 0, 0, 0]
  freqChannel: 0
  freqMin: 3
  freqMax: 8
  profileIndex: 0

SERVO_DEFAULTS = Object.freeze {
  servos: defaultServos()
  glide: 0
  mixRules: defaultMixRules()
  wing: defaultWing()
}

mirrorServoToEngine = (servo) ->
  engine.setServoParam servo.index, 'min', servo.min
  engine.setServoParam servo.index, 'max', servo.max
  engine.setServoParam servo.index, 'midpoint', servo.middle
  engine.setServoParam servo.index, 'rate', servo.rate

normalizeServo = (servo = {}, index = 0) ->
  {
    index
    min: clampInt PWM_LIMITS..., servo.min ? 1000
    max: clampInt PWM_LIMITS..., servo.max ? 2000
    middle: clampInt PWM_LIMITS..., servo.middle ? 1500
    rate: clampInt RATE_LIMITS..., servo.rate ? 100
    forwardFromChannel: clampInt(
      CHANNEL_LIMITS..., servo.forwardFromChannel ? index
    )
    reversedSources: finiteOr 0, servo.reversedSources
  }

clampWingField = (field, value) ->
  if field in SIGNED_WING_FIELDS
    clampInt SIGNED_LIMITS..., value
  else if field == 'servoTravelTimeMs'
    clampInt 0, 65535, value
  else if field in FULL_U8_WING_FIELDS
    clampInt U8_LIMITS..., value
  else if field == 'profileIndex'
    clampInt PROFILE_INDEX_LIMITS..., value
  else
    clampInt GAIN_LIMITS..., value

useServoStore = create (set, get) ->
  defaults = clone SERVO_DEFAULTS

  setServoField: (index, field, value) ->
    return unless 0 <= index < MAX_SERVO_CONFIGS
    servos = clone get().draft.servos
    servo = servos[index]
    return unless servo?
    if field in ['min', 'max', 'middle']
      servo[field] = clampInt PWM_LIMITS..., value
    else if field == 'rate'
      servo[field] = clampInt RATE_LIMITS..., value
    else if field == 'forwardFromChannel'
      servo[field] = clampInt CHANNEL_LIMITS..., value
    else if field == 'reversedSources'
      servo[field] = finiteOr 0, value
    else
      return
    mirrorServoToEngine servo
    set { draft: { get().draft..., servos }, dirty: true }

  # Loads a preset's physical pulse envelope into one slot. Names are
  # never written — the firmware stays servo-agnostic, only values move.
  applyServoPreset: (index, presetId) ->
    return unless 0 <= index < MAX_SERVO_CONFIGS
    preset = servoPresetById presetId
    return unless preset?
    servos = clone get().draft.servos
    servo = servos[index]
    return unless servo?
    servo.min = preset.min
    servo.max = preset.max
    servo.middle = preset.middle
    mirrorServoToEngine servo
    set { draft: { get().draft..., servos }, dirty: true }

  setGlide: (value) ->
    glide = clampInt GLIDE_LIMITS..., value
    set { draft: { get().draft..., glide }, dirty: true }

  setMixRuleField: (index, field, value) ->
    return unless 0 <= index < MAX_SERVO_MIX_RULES
    rules = clone get().draft.mixRules
    rule = rules[index]
    return unless rule?
    if field in ['targetChannel', 'inputSource', 'speed', 'box']
      rule[field] = clampInt CHANNEL_LIMITS..., value
    else if field in ['rate', 'min', 'max']
      rule[field] = clampInt RATE_LIMITS..., value
    else
      return
    set { draft: { get().draft..., mixRules: rules }, dirty: true }

  setWingField: (field, value) ->
    return unless field in WING_FIELD_NAMES
    wing = clone get().draft.wing
    wing[field] = clampWingField field, value
    set { draft: { get().draft..., wing }, dirty: true }

  setWingPairField: (field, index, value) ->
    return unless field in PAIR_ARRAY_FIELDS
    return unless 0 <= index < ORNITHOPTER_PAIR_COUNT
    wing = clone get().draft.wing
    wing[field] = clone wing[field]
    wing[field][index] = clampInt SIGNED_LIMITS..., value
    set { draft: { get().draft..., wing }, dirty: true }

  save: ->
    { mode, session, draft, loadedSession } = get()
    if mode == 'device'
      throw new Error 'No device session attached' unless session?
      unless loadedSession
        throw new Error(
          'Read the device before writing — the draft may belong ' +
          'to another craft'
        )
      for servo, i in draft.servos
        await session.writeServoConfiguration i, servo
      await session.writeGlideDegree draft.glide
      for rule, i in draft.mixRules
        await session.writeServoMixRule i, rule
      await session.writeWingMapping draft.wing
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
    configs = await session.readServoConfigurations()
    tuning = await session.readServoTuning()
    rules = await session.readServoMixRules()
    wingEnvelope = await session.readWingMapping()
    servos = defaultServos()
    for config, i in configs[0...MAX_SERVO_CONFIGS]
      servos[i] = normalizeServo config, i
    draft = {
      servos
      glide: tuning?.glide ? 0
      mixRules: if rules.length then rules else defaultMixRules()
      wing: wingEnvelope?.appendix ? defaultWing()
    }
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
    defaults = clone SERVO_DEFAULTS
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
export { SERVO_DEFAULTS }