# ═══════════════════════════════════════════════════════════════
# ORNIFLIGHT STUDIO — Ornithopter Simulation Engine
# Pure domain model: no React, no DOM, no rendering.
# Ported & refined from orniflight-configurator ONDAS simulator.
#
# Architecture: CoffeeScript class — the model IS a stateful entity.
# Classes earn their place when coherent state + behavior bundle into
# a single conceptual unit. Pure computation helpers stay at module
# level. Methods mutate @ state and return @ for fluent chaining.
# ═══════════════════════════════════════════════════════════════

import {
  shapeWave, ferocityUnits, WAVEFORM_DEFAULTS, WAVEFORM_LIMITS
  modulateWaveform
  advanceHarmonizedPhase
  throttleSkewShift, aileronSkewShift
  throttleSkewRateShift, aileronSkewRateShift
  SKEW_RATE_LPF_TAU
} from './waveform.coffee'
import { MATH_PARAMS } from '../lib/mathSuite.coffee'

TWO_PI = 2 * Math.PI
PI     = Math.PI

# Flap cadence bounds — the effective (AUX-modulated) base frequency is
# clamped here so a frequency-modulator channel can never wind the phase
# integrator into an unstable region (the historical feedback loop that
# rocketed cadence to the 20 Hz clamp on tiny stick input).
MIN_FLAP_HZ = 1.0
MAX_FLAP_HZ = 20.0

# Pilot steering centre deflection — full-stick elevator (pitch) or
# aileron (roll) shifts the wing stroke centre by this many degrees.
# Faithful to ../OrniFlight/ mixer (servos.c servoMixerOrnithopter): steering
# lives on the CENTRE (elevator = common, aileron = differential), not on
# the amplitude axis.
CENTER_MAX_DEG = 30.0

# PID flap-centre authority — @pidSumF is clamped to ±PID_CORR_LIMIT
# (40 rad/s²); this maps a saturated correction to a visible ±10° wing
# centre deflection in BOTH glide and flapping (the configurator's
# flap-centre path: PID controls where the wing spends its time).
PID_CENTER_DEG_PER_UNIT = 0.25

# Glide/flap boundary — below this throttle the bird stops flapping and
# holds both wings at the profile glide angle. Faithful to ../OrniFlight/
# firmware pg.h:201 GLIDE_MODE_THRESHOLD = 1040µs PWM.
GLIDE_MODE_THRESHOLD = 1040

# Rate-PID authority guard — the configurator's clamp+low-pass. With the
# gyro integrated (not recomputed) the derivative-on-measurement term
# sees its own last-substep injection and self-resonates; bounding the
# total correction and slewing it through a first-order low-pass breaks
# that high-frequency loop (configurator: Sum clamp ±5, α=0.25).
PID_CORR_LIMIT = 40.0    # rad/s² — ample for P to track the ±720°/s target
PID_CORR_ALPHA  = 0.25

# Derivative attenuation — the raw *_D gains are configurator-scale
# (roll_D = 23), tuned for its flap-centre control path. The Studio's PID
# injects the correction straight into the integrated gyro, where a D of
# 23 reverses its own last-substep injection 23× and self-resonates. Match
# the configurator's effective derivative authority (~0.12× the per-step
# change) instead.
PID_DERIV_SCALE = 0.005

# ═══════════════════════════════════════════════════════════════
# Pure helpers — zero side effects, zero dependency on instance
# ═══════════════════════════════════════════════════════════════

clamp    = (lo, hi, x) -> Math.max lo, Math.min hi, x
wrapAngle = (a) -> ((a + PI) % TWO_PI + TWO_PI) % TWO_PI - PI
rcToRate = (val) -> ((val - 1500) / 500) * 720 * PI / 180
angleToPwm = (angleDeg) ->
  clamp 1000, 2000, Math.round 1500 + (angleDeg / 45.0) * 500

# Flight presets — data, not control flow
PRESETS =
  gentle:
    baseAmplitude: 30.0
    flapFrequency: 4.0
    roll_P: 2.0
    pitch_P: 3.0
    yaw_P: 1.5
  acro:
    baseAmplitude: 45.0
    flapFrequency: 6.0
    roll_P: 4.0
    pitch_P: 6.0
    yaw_P: 3.0
  race:
    baseAmplitude: 55.0
    flapFrequency: 8.0
    roll_P: 7.0
    pitch_P: 9.0
    yaw_P: 5.0

# ═══════════════════════════════════════════════════════════════
# Servo arrangements — named ornithopter layouts, ported from the
# orniflight-configurator simulator. Each entry owns the wing-pair
# count, longitudinal CG station (σ·100, + = nose) and per-pair mount
# geometry: dihedral angle (deg), fore/aft station (σ·100) and optional
# vertical deck offset. The 3D viewport renders exactly these pairs;
# setAirframe may still override for a specific craft, but the archetype
# is the engine's self-consistent default.
ARRANGEMENTS =
  tandem_x:
    pairs: 2
    cg: 0
    angles: [30, -30, 0, 0]
    dists:  [40, -40, 0, 0]
  single:
    pairs: 1
    cg: -20
    angles: [0, 0, 0, 0]
    dists:  [0, 0, 0, 0]
  single_canard:
    pairs: 1
    cg: 20
    angles: [0, 0, 0, 0]
    dists:  [0, 0, 0, 0]
  tandem_parallel:
    pairs: 2
    cg: 0
    angles: [20, 20, 0, 0]
    dists:  [40, -40, 0, 0]
  triple:
    pairs: 3
    cg: 0
    angles: [30, 0, -30, 0]
    dists:  [45, 0, -45, 0]
  quad:
    pairs: 4
    cg: 0
    angles: [30, 10, -10, -30]
    dists:  [50, 17, -17, -50]
  double_decker:
    pairs: 4
    cg: 0
    angles: [30, 30, -30, -30]
    dists:  [40, 40, -40, -40]
    ys:     [6, -6, 6, -6]

DEFAULT_ARRANGEMENT = 'tandem_x'

# Arrangement spec → per-pair servo-mount array (engine σ convention).
# dists are σ·100 (40 → +0.4σ fore, matching the airframe's 120 mm/300);
# ys are deck offsets (6 → 0.3σ vertical, matching vertical 90 mm/300).
buildServoMounts = (spec) ->
  n = spec.pairs ? 1
  ys = spec.ys ? []
  for i in [0...n]
    index: i
    x: 0
    z: (spec.dists?[i] ? 0) / 100
    y: (ys[i] ? 0) * 0.05
    angle: spec.angles?[i] ? 0
    phaseShift: 0

# ONDAS gain defaults (mirror of constructor @ondas) + scaling
ONDAS_DEFAULTS =
  cadence_gain: 30
  ferocity_d_gain: 40
  ferocity_p_gain: 20
  balance_gain: 10
  ferocity_roll_gain: 30
  ferocity_yaw_gain: 25
  warp_gain: 20
  warp_yaw_gain: 15
  anchor_gain: 50
  resonance_gain: 10
  ferocity_downstroke: 12
  ferocity_upstroke: 12
  prescience_gain: 0
  espelho_gain: 0
  saudade_gain: 0
  ssff_gain: 0
  aeroelastic_glide_coefficient: 20
  aeroelastic_flap_coefficient: 40

scaleGains = (gains) ->
  scaled = {}
  for own k, d of ONDAS_DEFAULTS
    scaled[k] = (gains[k] ? d) * 0.01
  scaled

# Airframe geometry — wing area and aspect ratio derive from span
# and chord. Local model state: OrniFlight exposes no MSP codes for
# geometry, mass or CG, so the configuration document owns them.
AIRFRAME_SPAN_DEFAULT  = 1200
AIRFRAME_CHORD_DEFAULT = 180

export deriveGeometry = (geometry = {}) ->
  span = Number(geometry.wingSpan) or AIRFRAME_SPAN_DEFAULT
  chord = Number(geometry.chord) or AIRFRAME_CHORD_DEFAULT
  wingSpan: span
  chord: chord
  wingArea: span * chord
  aspectRatio: if chord > 0 then span / chord else 0

export arrangementNames = -> Object.keys ARRANGEMENTS

export getArrangement = (name) ->
  ARRANGEMENTS[name] ? ARRANGEMENTS[DEFAULT_ARRANGEMENT]

# Arrangement → airframe-document mounts (angle deg, station mm, vertical
# mm). dists are σ·100 → station = dist·3 (300 mm/σ); ys deck units →
# vertical = ys·15 (fits the ±100 mm MOUNT_LIMITS). Re-seeded into the
# airframe document when the mixer profile changes so multi-wing layouts
# (single → quad, double_decker biplane) render faithfully.
export arrangementMounts = (name) ->
  spec = getArrangement name
  for i in [0...4]
    angle:    spec.angles?[i] ? 0
    station:  (spec.dists?[i] ? 0) * 3
    vertical: (spec.ys?[i] ? 0) * 15

# ═══════════════════════════════════════════════════════════════
# OrnithopterModel — the bird's physics, PID, and ONDAS soul
# ═══════════════════════════════════════════════════════════════

export class OrnithopterModel

  # ── Constructor: initialize all state ──────────────────────

  constructor: ->

    @t        = 0.0
    @dt       = 0.002
    @attitude = { roll: 0, pitch: 0, yaw: 0 }
    @gyro     = { roll: 0, pitch: 0, yaw: 0 }

    @targetRates = { roll: 0, pitch: 0, yaw: 0 }
    @pidI        = { roll: 0, pitch: 0, yaw: 0 }
    @prevGyro    = { roll: 0, pitch: 0, yaw: 0 }
    @pidSumF     = { roll: 0, pitch: 0, yaw: 0 }

    @flapPhase     = 0.0
    @flapFrequency = 6.0
    @baseAmplitude = 45.0

    # AUX frequency modulator — an AUX channel offsets the base cadence
    # (OrniFlight behaviour): deflection around 1500 maps to ±gain Hz.
    # freqAuxChannel is 0-based (AUX1..AUX14); -1 = off.
    @freqAuxChannel = 3     # AUX4
    @freqAuxGain    = 6.0   # Hz at full stick deflection
    @_effectiveFrequency = 6.0
    @cadenceHz      = 6.0

    # Phase-quantized harmonizer state (Josephson washboard pendulum).
    # basePhase = virtual beat grid (advances at flapFrequency); phaseOffset
    # = debt to the grid (settles on whole strokes 2π·k); debtVel = the
    # pendulum's extra flap rate. ferHold/ferHoldVel = the mirror-pendulum
    # that gives the ferocity dwell bias its own inertial catch + decay.
    @basePhase   = 0.0
    @phaseOffset = 0.0
    @debtVel     = 0.0
    @ferHold     = 0.0
    @ferHoldVel  = 0.0

    @wingAngleL    = 0.0
    @wingAngleR    = 0.0
    @wingVelocityL = 0.0
    @wingVelocityR = 0.0

    @servos = for i in [0...4]
      index:          i
      name:           "Servo #{i + 1}"
      midpoint:       1500
      min:            1000
      max:            2000
      rate:           100
      phaseShift:     0.0
      amplitudeScale: 1.0

    @ondas =
      cadence_gain:         30
      ferocity_d_gain:      40
      ferocity_p_gain:      20
      balance_gain:         10
      ferocity_roll_gain:   30
      ferocity_yaw_gain:    25
      warp_gain:            20
      warp_yaw_gain:        15
      anchor_gain:          50
      resonance_gain:       10
      ferocity_downstroke:  12
      ferocity_upstroke:    12
      prescience_gain:      0
      espelho_gain:         0
      saudade_gain:         0
      ssff:                 20

    @pidGains =
      roll_P:  4.0
      roll_I:  0.03
      roll_D:  23.0
      pitch_P: 6.0
      pitch_I: 0.04
      pitch_D: 28.0
      yaw_P:   3.0
      yaw_I:   0.05
      yaw_D:   0.0

    @throttle = 0.28

    @sticks =
      throttle: 1280
      roll:     1500
      pitch:    1500
      yaw:      1500

    # Throttle % above the glide/flap boundary — drives stroke amplitude
    # (OrniFlight: throttle scales amplitude, CH6 commands frequency).
    @throttlePct = clamp 0, 1,
      (@sticks.throttle - GLIDE_MODE_THRESHOLD) / (2000 - GLIDE_MODE_THRESHOLD)

    # AUX channels (AUX1..AUX14) — pure RC surface, no physics. They
    # drive the modes range document and the receiver channel bars in
    # simulation so the UI is testable end-to-end without a controller.
    @aux = (1500 for i in [0...14])

    @battery =
      voltage:  12.6
      current:  0.8
      capacity: 1500
      consumed: 0.0

    @geometry = deriveGeometry()
    @mass =
      totalMass: 520
      cgX: 0
      cgZ: 0
      cgLat: 0
    @applyArrangement DEFAULT_ARRANGEMENT

    # Sim tuning — aeroelastic coefficients, yaw authority split and
    # servo travel time mirror the configurator's mature physics knobs.
    @selfLevelGain = 3.0
    @yawAmpMix = 0.5
    @aeroelasticFlapCoefficient = 20.0
    @aeroelasticGlideCoefficient = 4.0
    @servoTravelTimeMs = 300

    # Firmware amplitude coupling (../OrniFlight/ servos.c pgResetFn):
    # flap_magnitude=4 (centi-deg/µs above threshold), flap_base_amplitude=60.
    @flapMagnitude     = 4
    @flapBaseAmplitude = 60

    # Waveform — the stroke's shape soul. Runtime params mirror the
    # orniflight-configurator simulator: ferocity (dwell), form mix
    # (square↔triangle), centre skew per half, and the throttle/
    # aileron skew+slew couplings. Three flight profiles carry their
    # own waveform + glide/flap centres; CH7 selects the active one.
    @waveform = { WAVEFORM_DEFAULTS... }
    @flightProfiles = for i in [0...3]
      {
        index: i
        glideAngle: 0
        flappingAngle: 0
        waveform: { WAVEFORM_DEFAULTS... }
      }
    @activeFlightProfile = 0
    @liveWaveform = { WAVEFORM_DEFAULTS... }

    @connected        = false
    @disturbancePulse = 0.0
    # Disturbance authority (deg/s) — the strength of a drag-to-disturb
    # nudge. Mirrors the configurator's disturb_force (10..300, 80 base).
    @disturbForce     = 80.0

    @_servoAngles = [0, 0, 0, 0]
    @_servoPwm    = [1500, 1500, 1500, 1500]

    # Skew/slew transient state — mirror of the configurator's skew/slew.
    # Sentinels seed the rate LPF without a stale kick on first flap tick.
    @_prevThrottlePct = -1.0
    @_throttleRateLPF = 0.0
    @_prevAileronNorm = -2.0
    @_aileronRateLPF  = 0.0

    @telemetry =
      attitude:        { roll: 0, pitch: 0, yaw: 0 }
      gyro:            { roll: 0, pitch: 0, yaw: 0 }
      wingAngleL:      0
      wingAngleR:      0
      flapPhase:       0
      pairCount:       2
      servoMounts:     []
      flapFrequency:   6.0
      cadence:         6.0
      amplitude:       45.0
      batteryVoltage:  12.6
      servoPositions:  [1500, 1500, 1500, 1500]
      waveformHistory: []

  # ── Lifecycle ──────────────────────────────────────────────

  connect: ->
    @connected       = true
    @battery.voltage = 12.6
    @

  disconnect: ->
    @connected = false
    @

  reset: ->
    @t          = 0.0
    @attitude   = { roll: 0, pitch: 0, yaw: 0 }
    @gyro       = { roll: 0, pitch: 0, yaw: 0 }
    @pidI       = { roll: 0, pitch: 0, yaw: 0 }
    @prevGyro   = { roll: 0, pitch: 0, yaw: 0 }
    @pidSumF    = { roll: 0, pitch: 0, yaw: 0 }
    @disturbancePulse = 0.0
    @flapPhase  = 0.0
    @basePhase   = 0.0
    @phaseOffset = 0.0
    @debtVel     = 0.0
    @ferHold     = 0.0
    @ferHoldVel  = 0.0
    @

  # ── Setters — mutation helpers, return @ for chaining ──────

  setStick: (axis, value) ->
    @sticks[axis] = clamp 1000, 2000, value
    @_updateTargetRates()
    @throttle    = (@sticks.throttle - 1000) / 1000
    @throttlePct = clamp 0, 1,
      (@sticks.throttle - GLIDE_MODE_THRESHOLD) / (2000 - GLIDE_MODE_THRESHOLD)
    @

  setAux: (index, value) ->
    return @ unless 0 <= index < @aux.length
    @aux[index] = clamp 900, 2100, value
    @

  setFreqMod: (patch = {}) ->
    if patch.auxChannel?
      @freqAuxChannel = clamp -1, @aux.length - 1, Math.round patch.auxChannel
    if patch.gain?
      @freqAuxGain = clamp 0, 12, Number(patch.gain) or 0
    @

  setOndasParam: (name, value) ->
    meta = MATH_PARAMS[name]
    @ondas[name] = if meta
      clamp meta.min, meta.max, value
    else
      clamp 0, 100, value
    @

  # ── Waveform / flight-profile setters ─────────────────────

  setWaveformParam: (name, value) ->
    limits = WAVEFORM_LIMITS[name]
    return @ unless limits?
    v = clamp limits.min, limits.max, value
    @waveform[name] = v
    @flightProfiles[@activeFlightProfile].waveform[name] = v
    @

  setFlightProfileParam: (index, name, value) ->
    profile = @flightProfiles[index]
    return @ unless profile?
    limits = WAVEFORM_LIMITS[name]
    return @ unless limits?
    profile.waveform[name] = clamp limits.min, limits.max, value
    @waveform[name] = profile.waveform[name] if index is @activeFlightProfile
    @

  setGlideAngle: (index, value) ->
    profile = @flightProfiles[index]
    return @ unless profile?
    profile.glideAngle = clamp -90, 90, value
    @

  setFlappingAngle: (index, value) ->
    profile = @flightProfiles[index]
    return @ unless profile?
    profile.flappingAngle = clamp -90, 90, value
    @

  applyFlightProfile: (index) ->
    return @ unless @flightProfiles[index]?
    @activeFlightProfile = index
    @waveform = { @flightProfiles[index].waveform... }
    @

  setPidGain: (name, value) ->
    @pidGains[name] = value
    @

  setServoParam: (index, param, value) ->
    return @ unless @servos[index]
    @servos[index][param] = value
    @

  setAirframe: (values = {}) ->
    if values.geometry?
      @geometry = deriveGeometry { @geometry..., values.geometry... }
    @mass = { @mass..., values.mass... } if values.mass?
    @pairCount = values.pairCount if values.pairCount?
    if values.servoMounts?
      @servoMounts = for i in [0...@pairCount]
        source = values.servoMounts.find((m) -> m?.index == i)
        source ?= { index: i, x: 0, z: 0, y: 0, angle: 0, phaseShift: 0 }
        {
          index: i
          x: Number(source.x) or 0
          z: Number(source.z) or 0
          y: Number(source.y) or 0
          angle: Number(source.angle) or 0
          phaseShift: Number(source.phaseShift) or 0
        }
    @

  applyArrangement: (name) ->
    spec = ARRANGEMENTS[name] ? ARRANGEMENTS[DEFAULT_ARRANGEMENT]
    @arrangement = name
    @pairCount   = spec.pairs
    @cgStation   = (spec.cg ? 0) / 100
    @servoMounts = buildServoMounts spec
    @

  setSimulationParams: (params = {}) ->
    if params.selfLevelGain?
      @selfLevelGain = Number(params.selfLevelGain) or 0
    if params.yawAmpMix?
      @yawAmpMix = clamp 0, 1, params.yawAmpMix
    if params.aeroelasticFlapCoefficient?
      @aeroelasticFlapCoefficient =
        Number(params.aeroelasticFlapCoefficient) or 0
    if params.aeroelasticGlideCoefficient?
      @aeroelasticGlideCoefficient =
        Number(params.aeroelasticGlideCoefficient) or 0
    if params.servoTravelTimeMs?
      @servoTravelTimeMs = clamp 30, 500, params.servoTravelTimeMs
    @

  # ── Simulation step ────────────────────────────────────────

  step: (frameDt = @dt) ->
    return @ unless @connected

    @dt = frameDt
    subSteps = 5
    subDt    = @dt / subSteps

    @_applyFrequencyModulator()

    for [0...subSteps]
      @_physicsStep subDt
      @_pidStep subDt
      @_ondasStep subDt

      damp = 0.98
      @attitude.roll  =
        wrapAngle (@attitude.roll  + @gyro.roll  * subDt) * damp
      @attitude.pitch =
        wrapAngle (@attitude.pitch + @gyro.pitch * subDt) * damp
      @attitude.yaw   =
        wrapAngle (@attitude.yaw   + @gyro.yaw   * subDt)
      @t += subDt

    @_updateTelemetrySnapshot()
    @

  bump: ->
    # Random omnidirectional nudge — the one-shot "DISTURB" pulse.
    # Scaled by @disturbForce so the strength slider governs it too.
    f = @disturbForce * PI / 180
    @gyro.roll  += (Math.random() - 0.5) * f * 2.0
    @gyro.pitch += (Math.random() - 0.5) * f * 2.0
    @gyro.yaw   += (Math.random() - 0.5) * f * 0.7
    @

  # Directional disturbance (deg/s) — fed by the 3D bird's right-drag
  # while dragging. Applied straight into the gyro rates so the PID +
  # ONDAS couplings must fight it, exactly as the configurator's
  # _applyDisturbDrag injects wx/wy/wz into gyroRoll/Pitch/Yaw.
  disturb: (dRollDeg = 0, dPitchDeg = 0, dYawDeg = 0) ->
    k = PI / 180
    @gyro.roll  += dRollDeg  * k
    @gyro.pitch += dPitchDeg * k
    @gyro.yaw   += dYawDeg   * k
    @

  setDisturbForce: (value) ->
    @disturbForce = clamp 0, 400, value
    @

  # Zero the rigid-body state (gyro + attitude + PID integrators) while
  # leaving the stroke running — the configurator's "Reset" button.
  resetAttitude: ->
    @attitude   = { roll: 0, pitch: 0, yaw: 0 }
    @gyro       = { roll: 0, pitch: 0, yaw: 0 }
    @pidI       = { roll: 0, pitch: 0, yaw: 0 }
    @prevGyro   = { roll: 0, pitch: 0, yaw: 0 }
    @pidSumF    = { roll: 0, pitch: 0, yaw: 0 }
    @disturbancePulse = 0.0
    @

  # ── Presets ────────────────────────────────────────────────

  applyPreset: (name) ->
    p = PRESETS[name]
    return @ unless p
    @baseAmplitude      = p.baseAmplitude
    @flapFrequency      = p.flapFrequency
    @pidGains.roll_P    = p.roll_P
    @pidGains.pitch_P   = p.pitch_P
    @pidGains.yaw_P     = p.yaw_P
    @

  # ═══════════════════════════════════════════════════════════
  # Private — prefixed with _, operate on @ state
  # ═══════════════════════════════════════════════════════════

  _updateTargetRates: ->
    @targetRates.roll  = rcToRate @sticks.roll
    @targetRates.pitch = rcToRate @sticks.pitch
    @targetRates.yaw   = rcToRate @sticks.yaw

    # Attitude self-leveling — when sticks sit near centre, blend an
    # attitude→rate feedback so the bird returns to level (deg/s per
    # degree cancels to rad/s per rad). Stick deflection disables it.
    normR = (@sticks.roll  - 1500) / 500
    normP = (@sticks.pitch - 1500) / 500
    normY = (@sticks.yaw   - 1500) / 500
    active = Math.abs(normR) > 0.03 or
      Math.abs(normP) > 0.03 or Math.abs(normY) > 0.03
    unless active
      @targetRates.roll  += -@attitude.roll  * @selfLevelGain
      @targetRates.pitch += -@attitude.pitch * @selfLevelGain
      @targetRates.yaw   += -@attitude.yaw   * @selfLevelGain * 0.6

  # Recompute the effective cadence once per frame. Frequency lives on
  # the AUX/CH6 axis, NOT throttle — ../OrniFlight/ firmware maps AUX
  # directly to [ornithopter_freq_min .. ornithopter_freq_max]; throttle
  # scales stroke AMPLITUDE. The Studio keeps @flapFrequency as the
  # no-AUX fallback base and @freqAuxGain as the deflection scale.
  _applyFrequencyModulator: ->
    baseHz = @flapFrequency
    mod = 0
    channel = @freqAuxChannel
    if 0 <= channel < @aux.length
      norm = clamp -1, 1, (@aux[channel] - 1500) / 500
      mod = norm * @freqAuxGain
    @_effectiveFrequency =
      clamp MIN_FLAP_HZ, MAX_FLAP_HZ, baseHz + mod
    @

  # Firmware getFlappingAmplitude (../OrniFlight/ pid.c:1091) — coupled
  # mode (the default, BOXORNITHOPTERINDEPENDENT inactive):
  #   ampLin = (throttle − GLIDE_MODE_THRESHOLD) · flap_magnitude·0.01
  #              · flap_base_amplitude·0.1
  #   amp    = ampLin · maxAmp / √(ampLin² + maxAmp²)   (Marcinkiewicz soft knee)
  # maxAmp = @baseAmplitude (the servo_max_amplitude analogue). Returns
  # degrees; callers convert to radians.
  _firmwareAmplitude: (throttleUs) ->
    return 0 if throttleUs <= GLIDE_MODE_THRESHOLD
    ampLin = (throttleUs - GLIDE_MODE_THRESHOLD) * @flapMagnitude * 0.01 *
               @flapBaseAmplitude * 0.1
    maxAmp = @baseAmplitude
    (ampLin * maxAmp) / Math.sqrt(ampLin * ampLin + maxAmp * maxAmp)

  _physicsStep: (subDt) ->
    # Rigid-body rate integration, faithful to the configurator's
    # _physicsStep: gyro += (ctrl − gyro·damp)·dt. The wing forcing is
    # the flap's own aero reaction (small); passive aerodynamic damping
    # scales with flapping authority + the ONDAS anchor gain; external
    # disturbance (drag-to-disturb) injects directly into the rates.
    # This replaces the old "gyro = wingAngle·thrust" recompute that
    # overwrote any injected disturbance every substep — which is why
    # the ONDAS filters never visibly reacted.
    thrustFactor =
      @_firmwareAmplitude(@sticks.throttle) *
        @_effectiveFrequency * @_effectiveFrequency * 0.00015

    wingRoll  = (@wingAngleL - @wingAngleR) * 0.02
    wingPitch = (@wingAngleL + @wingAngleR) * 0.02
    wingYaw   = (@wingAngleR - @wingAngleL) * 0.005

    # Passive aerodynamic damping — a rotating bird meets asymmetric
    # airflow that opposes rotation. Authority gates it (folded wings =
    # free tumble); the anchor gain stiffens it (ONDAS damping anchor).
    authority = clamp 0.05, 1, @baseAmplitude / 45.0
    dampBase  = 1.3
    anchorBoost = @ondas.anchor_gain * 0.08
    dampRoll  = (dampBase + anchorBoost) * authority
    dampPitch = (dampBase + anchorBoost) * authority
    dampYaw   = (dampBase * 0.6 + anchorBoost) * authority

    @gyro.roll  += (wingRoll  * thrustFactor - @gyro.roll  * dampRoll)  * subDt
    @gyro.pitch += (wingPitch * thrustFactor - @gyro.pitch * dampPitch) * subDt
    @gyro.yaw   += (wingYaw   * thrustFactor - @gyro.yaw   * dampYaw)   * subDt

    # Safety clamp — the configurator's 1500 deg/s limit.
    GYRO_LIMIT = 26.18
    @gyro.roll  = clamp -GYRO_LIMIT, GYRO_LIMIT, @gyro.roll
    @gyro.pitch = clamp -GYRO_LIMIT, GYRO_LIMIT, @gyro.pitch
    @gyro.yaw   = clamp -GYRO_LIMIT, GYRO_LIMIT, @gyro.yaw

    noiseFloor = 0.0001
    @gyro.roll  += (Math.random() - 0.5) * noiseFloor
    @gyro.pitch += (Math.random() - 0.5) * noiseFloor
    @gyro.yaw   += (Math.random() - 0.5) * noiseFloor

    @gyro.roll  += @disturbancePulse * (Math.random() - 0.5) * 0.1
    @gyro.pitch += @disturbancePulse * (Math.random() - 0.5) * 0.1
    @gyro.yaw   += @disturbancePulse * (Math.random() - 0.5) * 0.05
    @disturbancePulse *= 0.85

  _pidStep: (subDt) ->
    for axis in ['roll', 'pitch', 'yaw']
      P = @pidGains["#{axis}_P"]
      I = @pidGains["#{axis}_I"]
      D = @pidGains["#{axis}_D"]

      target  = @targetRates[axis]
      current = @gyro[axis]
      error   = target - current

      pOut = error * P

      # Integrate over the substep dt — the old `@dt` was the full
      # frame delta, wound 5x per frame, and kept the model spinning
      # after stick release (integrator windup).
      @pidI[axis] = clamp -20, 20, @pidI[axis] + error * I * subDt
      iOut = @pidI[axis]

      # Derivative on measurement, not error. Differentiating the error
      # turned every setpoint jump into a derivative kick — a stick
      # release spiked gyro to -289 rad/s and whipped the model back.
      dMeas = current - @prevGyro[axis]
      dOut  =
        if subDt > 0 then -(dMeas / subDt) * D * PID_DERIV_SCALE else 0
      @prevGyro[axis] = current

      correction = pOut + iOut + dOut

      # Authority guard — see PID_CORR_LIMIT. Bounding + slewing the
      # total keeps the D term from self-resonating against the newly
      # integrated gyro (its own injection reappears in dMeas next step).
      correction = clamp -PID_CORR_LIMIT, PID_CORR_LIMIT, correction
      @pidSumF[axis] += PID_CORR_ALPHA * (correction - @pidSumF[axis])
      @gyro[axis] += @pidSumF[axis] * subDt

  # Flap-centre offsets (rad) — pilot stick + PID correction, the SAME
  # signal in glide and flapping. Firmware: PID controls where the wing
  # spends its time (flap centre), so the stabilizer keeps steering even
  # with amplitude collapsed to zero in glide. Elevator = common (both
  # wings), aileron = differential (L/R opposite), yaw = differential
  # (glide-capable rudder). @pidSumF is the low-passed rate correction.
  _flapCenters: ->
    elevatorNorm = (@sticks.pitch - 1500) / 500
    aileronNorm  = (@sticks.roll  - 1500) / 500
    pitch: (elevatorNorm * CENTER_MAX_DEG +
      @pidSumF.pitch * PID_CENTER_DEG_PER_UNIT) * (PI / 180)
    roll: (aileronNorm * CENTER_MAX_DEG +
      @pidSumF.roll * PID_CENTER_DEG_PER_UNIT) * (PI / 180)
    yaw: (@pidSumF.yaw * PID_CENTER_DEG_PER_UNIT) * (PI / 180)

  _ondasStep: (subDt) ->
    g = scaleGains @ondas

    rateError =
      roll:  @targetRates.roll  - @gyro.roll
      pitch: @targetRates.pitch - @gyro.pitch
      yaw:   @targetRates.yaw   - @gyro.yaw

    # ── Glide mode ──────────────────────────────────────────────
    # Throttle at/below the flap boundary stops the stroke and holds both
    # wings at the profile glide angle, still steered by the pitch/roll
    # centres (OrniFlight firmware: throttle ≤ GLIDE_MODE_THRESHOLD 1040µs
    # → glide branch; servoMixer keeps pidData.Sum in charge).
    return @_glideStep() if @throttlePct <= 0

    # ── Phase-quantized harmonization (Josephson washboard pendulum) ──
    # The base frequency is a beat GRID. ONDAS cadence demand (kGainMod>1)
    # is a *rate* target for the phase debt, not a raw frequency scale.
    # Weak demand nudges the phase and rings back onto the SAME beat; a
    # strong demand whips the debt over the π barrier — a quantized whole-
    # stroke slip (2π) — so the flap always lands on a beat, never between.
    cadenceTarget = @_effectiveFrequency * TWO_PI
    kGainMod      = clamp 0.5, 2.0, 1.0 + rateError.pitch * g.cadence_gain * 0.01
    { phase, cadence } = advanceHarmonizedPhase @, cadenceTarget, kGainMod, subDt
    @flapPhase = phase
    cadenceFreq = cadence / TWO_PI
    @cadenceHz  = cadenceFreq

    sinPhi = Math.sin @flapPhase
    cosPhi = Math.cos @flapPhase

    # Ferocity mirror-pendulum: the dwell demand is a damped pendulum
    # (ω₀=10, ζ=0.7) tracking the live pitch error. It catches the demanded
    # ferocity with pendulum momentum and decays back inertially, so the
    # dwell change lands in step with the phase-quantized cadence rather
    # than snapping the reversal boundary mid-stroke.
    fOmega = 10.0
    fZeta  = 0.7
    ferErr = @ferHold - rateError.pitch
    restore = -fOmega * fOmega * ferErr
    damping = -2.0 * fZeta * fOmega * @ferHoldVel
    @ferHoldVel += (restore + damping) * subDt
    @ferHold += @ferHoldVel * subDt

    heldError = { rateError..., pitch: @ferHold }
    # The ONDAS Ferocity layer (downstroke/upstroke 1..100) is the base
    # stroke shape — the sim must breathe from the SAME sliders the
    # signature ribbon previews. The waveform stroke/return ferocity are
    # the device-profile echo; ONDAS is the live soul driving shapeWave.
    ferBase =
      strokeFerocity:  @ondas.ferocity_downstroke
      returnFerocity:  @ondas.ferocity_upstroke
      ferocityShapeMix: @waveform.ferocityShapeMix
    live = modulateWaveform ferBase, g, heldError

    # ── Skew + slew coupling (orniflight-configurator simulator) ──
    # Throttle → symmetric skew: gas front-loads the downstroke, idle
    # front-loads the upstroke. Aileron → differential skew: one wing
    # front-loads while the other late-loads (roll torque). Rate slew
    # adds a transient kick, decayed by LPF τ once the stick rests.
    throttle01  = @throttlePct
    aileronNorm = (@sticks.roll - 1500) / 500

    thrSkewShift = throttleSkewShift throttle01, @waveform.throttleSkewMix
    ailSkewShift = aileronSkewShift  aileronNorm, @waveform.aileronSkewMix

    thrRateBoost = 0.0
    if @_prevThrottlePct < 0
      @_prevThrottlePct = throttle01
    else if subDt > 0
      throttleRate = (throttle01 - @_prevThrottlePct) / subDt
      @_prevThrottlePct = throttle01
      alpha = subDt / (SKEW_RATE_LPF_TAU + subDt)
      @_throttleRateLPF += (throttleRate - @_throttleRateLPF) * alpha
      thrRateBoost =
        throttleSkewRateShift @_throttleRateLPF, @waveform.throttleSkewRateMix

    ailRateBoost = 0.0
    if @_prevAileronNorm < -1.5
      @_prevAileronNorm = aileronNorm
    else if subDt > 0
      aileronRate = (aileronNorm - @_prevAileronNorm) / subDt
      @_prevAileronNorm = aileronNorm
      alpha = subDt / (SKEW_RATE_LPF_TAU + subDt)
      @_aileronRateLPF += (aileronRate - @_aileronRateLPF) * alpha
      ailRateBoost =
        aileronSkewRateShift @_aileronRateLPF, @waveform.aileronSkewRateMix

    strokeSkewEff =
      @waveform.strokeSkew + thrSkewShift + thrRateBoost
    returnSkewEff =
      @waveform.returnSkew - thrSkewShift - thrRateBoost

    strokeSkewL = strokeSkewEff + ailSkewShift + ailRateBoost
    strokeSkewR = strokeSkewEff - ailSkewShift - ailRateBoost
    returnSkewL = returnSkewEff + ailSkewShift + ailRateBoost
    returnSkewR = returnSkewEff - ailSkewShift - ailRateBoost

    @liveWaveform =
      { live..., strokeSkew: strokeSkewEff, returnSkew: returnSkewEff }

    fLiveStroke = ferocityUnits live.strokeFerocity
    fLiveReturn = ferocityUnits live.returnFerocity
    pulseL = shapeWave @flapPhase,
      fLiveStroke, fLiveReturn, -1, live.ferocityShapeMix,
      strokeSkewL, returnSkewL
    pulseR = shapeWave @flapPhase,
      fLiveStroke, fLiveReturn, -1, live.ferocityShapeMix,
      strokeSkewR, returnSkewR
    amp    = @_firmwareAmplitude(@sticks.throttle) * (PI / 180)

    rollDiff  = rateError.roll * g.warp_gain * 0.3
    rollDiff += rateError.roll * g.ferocity_roll_gain * 0.1 *
      (if sinPhi > 0 then 1.0 else 0.6)

    # NOTE — YAW is NOT a raw amplitude offset. The firmware (pid.c:2060)
    # routes yaw through the smooth ferocity wave-shaping path
    # (flappingFerocityDifferentialYaw, pendulum-filtered ferHold, gated by
    # yaw_amp_mix) and the flap-CENTRE twist (servoMixerOrnithopter
    # INPUT_STABILIZED_YAW). A direct `rateError.yaw · gain` added to ampL/ampR
    # jumps the instant the yaw stick moves (targetRates.yaw steps) and kinks
    # at sinΦ=0 via |sinΦ| — the "weird jump" in the curve. Yaw authority here
    # lives in yawCenter (differential flap-centre, below), matching firmware.

    # Centre terms — faithful to the OrniFlight firmware mixer:
    #   · elevator (pitch) → COMMON centre: both wings shift the SAME
    #     physical direction (the flapping analogue of the elevator —
    #     nose-up raises both stroke centres, nose-down lowers them)
    #   · aileron  (roll)  → DIFFERENTIAL centre: one wing up, the
    #     other down (roll torque)
    # Pilot stick + PID drive the centre (the configurator's flap-centre
    # path — PID controls where the wing spends its time, same in glide
    # & flapping). The amplitude/ferocity couplings below layer agility
    # and aggression on top of that stabilizer centre.
    centers = @_flapCenters()
    pitchCenter = centers.pitch
    rollCenter  = centers.roll
    yawCenter   = centers.yaw

    resonanceMod = (rateError.roll * sinPhi) * g.resonance_gain * 0.1
    balanceMod   = @pidI.pitch * g.balance_gain * 0.2

    totalRate =
      Math.abs(@gyro.roll) + Math.abs(@gyro.pitch) +
        Math.abs(@gyro.yaw)
    anchorMod = 1.0 / (1.0 + totalRate * g.anchor_gain * 0.5)

    # Left wing — common pitch centre + differential roll centre + flap
    ampL  = amp * (1.0 + resonanceMod) * anchorMod
    ampL += rollDiff
    ampL += balanceMod * (if sinPhi < 0 then 1.0 else 0.0)
    @wingAngleL = pitchCenter + rollCenter + yawCenter + pulseL * ampL

    # Right wing — same common pitch centre, mirrored roll centre + flap
    ampR  = amp * (1.0 + resonanceMod) * anchorMod
    ampR -= rollDiff
    ampR += balanceMod * (if sinPhi < 0 then 1.0 else 0.0)
    @wingAngleR = pitchCenter - rollCenter - yawCenter + pulseR * ampR

    # Wing velocities
    @wingVelocityL = cosPhi * ampL * cadenceFreq * TWO_PI
    @wingVelocityR = cosPhi * ampR * cadenceFreq * TWO_PI

    # cadenceFreq is the *instantaneous* modulated cadence — it drives
    # phase advance and wing velocity only. Writing it back to
    # @flapFrequency would compound the pitch modulation every substep
    # and rocket the base cadence to the 20 Hz clamp (positive feedback).
    # @flapFrequency stays the base, set by preset/thrust physics.

    @_computeServoSignals sinPhi, ampL, ampR

  _glideStep: ->
    centers = @_flapCenters()
    glideAngle =
      @flightProfiles[@activeFlightProfile].glideAngle * (PI / 180)

    # Glide is the flap-centre path with amplitude collapsed to zero: the
    # wings hold at the profile glide angle PLUS the live PID centre
    # (elevator common, aileron/yaw differential). The stabilizer keeps
    # steering — a disturbed glide visibly deflects the wings to correct,
    # exactly as the firmware's glide branch keeps the PID loop in charge.
    @wingAngleL = glideAngle + centers.pitch + centers.roll + centers.yaw
    @wingAngleR = glideAngle + centers.pitch - centers.roll - centers.yaw
    @wingVelocityL = 0.0
    @wingVelocityR = 0.0
    @cadenceHz     = 0.0

    # Purge flapping transients so a fresh flap burst starts clean
    # (no stale slew/ferocity kick) — OrniFlight firmware glide branch.
    @_prevThrottlePct = -1.0
    @_throttleRateLPF = 0.0
    @_prevAileronNorm = -2.0
    @_aileronRateLPF  = 0.0
    @ferHold     = 0.0
    @ferHoldVel  = 0.0

    @_computeServoSignals 0, 0, 0
    @

  _computeServoSignals: (sinPhi, ampL, ampR) ->
    angleL_deg = @wingAngleL * 180 / PI
    angleR_deg = @wingAngleR * 180 / PI

    for servo, i in @servos
      phase     = servo.phaseShift * PI / 180
      midpoint  = servo.midpoint
      ampScale  = servo.amplitudeScale
      rateScale = servo.rate / 100.0

      blendedAngle =
        if i < 2
          angleL_deg * (1.0 - 0.3 * i) +
            angleR_deg * (0.3 * i)
        else
          angleR_deg * (1.0 - 0.3 * (i - 2)) +
            angleL_deg * (0.3 * (i - 2))

      @_servoAngles[i] =
        blendedAngle * ampScale * rateScale
      @_servoPwm[i] =
        angleToPwm @_servoAngles[i]

  _updateTelemetrySnapshot: ->
    tel = @telemetry
    tel.attitude       = { @attitude... }
    tel.gyro           = { @gyro... }
    tel.wingAngleL     = @wingAngleL
    tel.wingAngleR     = @wingAngleR
    tel.flapPhase      = @flapPhase
    tel.pairCount      = @pairCount
    tel.servoMounts    = @servoMounts.map (m) -> { m... }
    tel.flapFrequency  = @_effectiveFrequency
    tel.cadence        = @cadenceHz
    tel.liveWaveform   = { @liveWaveform... }
    tel.amplitude      =
      Math.max(Math.abs(@wingAngleL), Math.abs(@wingAngleR)) *
        180 / PI
    tel.batteryVoltage =
      @battery.voltage - (@battery.consumed * 0.001)
    tel.servoPositions =
      @_servoPwm or [1500, 1500, 1500, 1500]

    # The living stroke — every frame carries the full time-domain
    # truth the StrokeScope needs: wing pair, gyro, the live ferocity
    # envelope, flap phase and the per-servo PWM. The history is the
    # single feed for the motion diagrams (scope, phase-plane, ferocity).
    tel.waveformHistory.push
      t:          @t
      wingL:      @wingAngleL * 180 / PI
      wingR:      @wingAngleR * 180 / PI
      gyroRoll:   @gyro.roll  * 180 / PI
      gyroPitch:  @gyro.pitch * 180 / PI
      gyroYaw:    @gyro.yaw   * 180 / PI
      flapPhase:  @flapPhase
      cadence:    @cadenceHz
      ferStroke:  @liveWaveform.strokeFerocity
      ferReturn:  @liveWaveform.returnFerocity
      ferShape:   @liveWaveform.ferocityShapeMix
      servo1:     @_servoPwm[0]
      servo2:     @_servoPwm[1]
      servo3:     @_servoPwm[2]
      servo4:     @_servoPwm[3]
    tel.waveformHistory.shift() if tel.waveformHistory.length > 200

    @battery.consumed += 0.00002