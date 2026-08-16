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

TWO_PI = 2 * Math.PI
PI     = Math.PI

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

scaleGains = (gains) ->
  scaled = {}
  for own k, d of ONDAS_DEFAULTS
    scaled[k] = (gains[k] ? d) * 0.01
  scaled

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

    @flapPhase     = 0.0
    @flapFrequency = 6.0
    @baseAmplitude = 45.0

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
      cadence_gain:        30
      ferocity_d_gain:     40
      ferocity_p_gain:     20
      balance_gain:        10
      ferocity_roll_gain:  30
      ferocity_yaw_gain:   25
      warp_gain:           20
      warp_yaw_gain:       15
      anchor_gain:         50
      resonance_gain:      10
      prescience:          5
      espelho:             0
      saudade:             0
      ssff:                20

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

    @battery =
      voltage:  12.6
      current:  0.8
      capacity: 1500
      consumed: 0.0

    @connected        = false
    @disturbancePulse = 0.0

    @_servoAngles = [0, 0, 0, 0]
    @_servoPwm    = [1500, 1500, 1500, 1500]

    @telemetry =
      attitude:        { roll: 0, pitch: 0, yaw: 0 }
      gyro:            { roll: 0, pitch: 0, yaw: 0 }
      wingAngleL:      0
      wingAngleR:      0
      flapFrequency:   6.0
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
    @flapPhase  = 0.0
    @

  # ── Setters — mutation helpers, return @ for chaining ──────

  setStick: (axis, value) ->
    @sticks[axis] = clamp 1000, 2000, value
    @_updateTargetRates()
    @throttle = (@sticks.throttle - 1000) / 1000
    @

  setOndasParam: (name, value) ->
    @ondas[name] = clamp 0, 100, value
    @

  setPidGain: (name, value) ->
    @pidGains[name] = value
    @

  setServoParam: (index, param, value) ->
    return @ unless @servos[index]
    @servos[index][param] = value
    @

  # ── Simulation step ────────────────────────────────────────

  step: (frameDt = @dt) ->
    return @ unless @connected

    @dt = frameDt
    subSteps = 5
    subDt    = @dt / subSteps

    for [0...subSteps]
      @_physicsStep subDt
      @_pidStep subDt
      @_ondasStep()

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
    @disturbancePulse = 5.0
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

  _physicsStep: (subDt) ->
    thrustFactor =
      @throttle * @baseAmplitude *
        @flapFrequency * @flapFrequency * 0.00015

    wingRoll  = (@wingAngleL - @wingAngleR) * 0.02
    wingPitch = (@wingAngleL + @wingAngleR) * 0.02

    @gyro.roll  = wingRoll  * thrustFactor
    @gyro.pitch = wingPitch * thrustFactor
    @gyro.yaw   = (@wingAngleR - @wingAngleL) * 0.005 * thrustFactor

    gyroDamp = 0.92
    @gyro.roll  *= gyroDamp
    @gyro.pitch *= gyroDamp
    @gyro.yaw   *= gyroDamp

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
      dOut  = if subDt > 0 then -(dMeas / subDt) * D else 0
      @prevGyro[axis] = current

      correction = pOut + iOut + dOut
      @gyro[axis] += correction * subDt

  _ondasStep: ->
    g = scaleGains @ondas

    rateError =
      roll:  @targetRates.roll  - @gyro.roll
      pitch: @targetRates.pitch - @gyro.pitch
      yaw:   @targetRates.yaw   - @gyro.yaw

    cadenceFreq =
      @flapFrequency * (1.0 + rateError.pitch * g.cadence_gain * 0.01)
    cadenceFreq = clamp 1.0, 20.0, cadenceFreq

    @flapPhase += cadenceFreq * TWO_PI * @dt
    @flapPhase %= TWO_PI

    sinPhi = Math.sin @flapPhase
    cosPhi = Math.cos @flapPhase
    amp    = @baseAmplitude * (PI / 180)

    rollDiff  = rateError.roll * g.warp_gain * 0.3
    rollDiff += rateError.roll * g.ferocity_roll_gain * 0.1 *
      (if sinPhi > 0 then 1.0 else 0.6)

    yawDiff  = rateError.yaw * g.warp_yaw_gain * 0.2
    yawDiff += rateError.yaw * g.ferocity_yaw_gain * 0.08 * Math.abs sinPhi

    # rateError is in rad/s (±12.57 at full stick). A 0.4 factor here
    # drove pitchMod to ±1.5 — amplitude swung 0.5×…2.5×, pegging the
    # servos on the way up and reversing wing phase on the way down.
    # 0.1 keeps pitchMod ≈ ±0.4 (amplitude 0.6×…1.4×) at full stick.
    pitchMod     = rateError.pitch * g.cadence_gain * 0.1
    resonanceMod = (rateError.roll * sinPhi) * g.resonance_gain * 0.1
    balanceMod   = @pidI.pitch * g.balance_gain * 0.2

    totalRate =
      Math.abs(@gyro.roll) + Math.abs(@gyro.pitch) +
        Math.abs(@gyro.yaw)
    anchorMod = 1.0 / (1.0 + totalRate * g.anchor_gain * 0.5)

    # Left wing
    ampL  = amp * (1.0 + pitchMod + resonanceMod) * anchorMod
    ampL += rollDiff
    ampL += yawDiff
    ampL += balanceMod * (if sinPhi < 0 then 1.0 else 0.0)
    @wingAngleL = sinPhi * ampL

    # Right wing
    ampR  = amp * (1.0 + pitchMod + resonanceMod) * anchorMod
    ampR -= rollDiff
    ampR += yawDiff * 0.3
    ampR += balanceMod * (if sinPhi < 0 then 1.0 else 0.0)
    @wingAngleR = sinPhi * ampR

    # Wing velocities
    @wingVelocityL = cosPhi * ampL * cadenceFreq * TWO_PI
    @wingVelocityR = cosPhi * ampR * cadenceFreq * TWO_PI

    # cadenceFreq is the *instantaneous* modulated cadence — it drives
    # phase advance and wing velocity only. Writing it back to
    # @flapFrequency would compound the pitch modulation every substep
    # and rocket the base cadence to the 20 Hz clamp (positive feedback).
    # @flapFrequency stays the base, set by preset/thrust physics.

    @_computeServoSignals sinPhi, ampL, ampR

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
    tel.flapFrequency  = @flapFrequency
    tel.amplitude      =
      Math.max(Math.abs(@wingAngleL), Math.abs(@wingAngleR)) *
        180 / PI
    tel.batteryVoltage =
      @battery.voltage - (@battery.consumed * 0.001)
    tel.servoPositions =
      @_servoPwm or [1500, 1500, 1500, 1500]

    tel.waveformHistory.push
      t:         @t
      wingL:     @wingAngleL * 180 / PI
      wingR:     @wingAngleR * 180 / PI
      gyroRoll:  @gyro.roll  * 180 / PI
      gyroPitch: @gyro.pitch * 180 / PI
      gyroYaw:   @gyro.yaw   * 180 / PI
    tel.waveformHistory.shift() if tel.waveformHistory.length > 200

    @battery.consumed += 0.00002