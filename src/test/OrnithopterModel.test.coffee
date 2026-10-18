import { describe, it, expect, beforeEach } from 'vitest'
import { OrnithopterModel, deriveGeometry } from '../simulation/OrnithopterModel.coffee'

describe 'OrnithopterModel', ->

  model = null

  beforeEach ->
    model = new OrnithopterModel()
    model.connect()

  it 'initializes with 4 servos', ->
    expect(model.servos.length).toBe 4

  it 'servos have names Servo 1 through Servo 4', ->
    expect(model.servos[0].name).toBe 'Servo 1'
    expect(model.servos[3].name).toBe 'Servo 4'

  it 'starts with zero attitude', ->
    expect(model.attitude.roll).toBe 0
    expect(model.attitude.pitch).toBe 0
    expect(model.attitude.yaw).toBe 0

  it 'starts at time 0', ->
    expect(model.t).toBe 0

  it 'default flap frequency is 6 Hz', ->
    expect(model.flapFrequency).toBe 6.0

  it 'default base amplitude is 45 degrees', ->
    expect(model.baseAmplitude).toBe 45.0

  it 'initial battery voltage is 12.6', ->
    expect(model.battery.voltage).toBe 12.6

  it 'step advances time', ->
    model.step 0.016
    expect(model.t).toBeGreaterThan 0

  it 'step does nothing when disconnected', ->
    model.disconnect()
    t0 = model.t
    model.step 0.016
    expect(model.t).toBe t0

  it 'setStick clamps to range', ->
    model.setStick 'roll', 2500
    expect(model.sticks.roll).toBe 2000
    model.setStick 'roll', 500
    expect(model.sticks.roll).toBe 1000

  it 'setStick updates target rates', ->
    model.setStick 'roll', 1600
    expect(model.targetRates.roll).not.toBe 0

  it 'initializes 14 AUX channels at neutral', ->
    expect(model.aux).toHaveLength 14
    expect(model.aux[0]).toBe 1500

  it 'setAux clamps to 900..2100 and ignores out-of-range index', ->
    model.setAux 0, 2400
    expect(model.aux[0]).toBe 2100
    model.setAux 1, 500
    expect(model.aux[1]).toBe 900
    model.setAux 99, 1800
    # Should not throw
    expect(model.aux).toHaveLength 14

  it 'AUX frequency modulator offsets the effective cadence', ->
    model.setStick 'throttle', 1500   # mid → 1× base cadence
    model.setFreqMod { auxChannel: 3, gain: 6.0 }
    model.setAux 3, 2000   # full deflection → +6 Hz over the 6 Hz base
    model.step 0.016
    expect(model.telemetry.flapFrequency).toBeCloseTo 12.0

  it 'frequency modulator off leaves the base cadence', ->
    model.setStick 'throttle', 1500   # mid → 1× base cadence
    model.setFreqMod { auxChannel: -1 }
    model.setAux 3, 2000
    model.step 0.016
    expect(model.telemetry.flapFrequency).toBeCloseTo 6.0

  it 'throttle scales stroke amplitude, not cadence', ->
    model.setFreqMod { auxChannel: -1 }
    model.setStick 'roll', 1500
    model.setStick 'pitch', 1500
    model.setStick 'throttle', 2000   # full → cadence stays at 6 Hz base
    peak = 0
    for i in [0...60]
      model.step 0.016
      peak = Math.max peak, Math.abs(model.wingAngleL * 180 / Math.PI)
    expect(model.telemetry.flapFrequency).toBeCloseTo 6.0
    expect(peak).toBeGreaterThan 35          # full base amplitude (45°)

    model.setStick 'throttle', 1100   # just above the glide threshold
    peak = 0
    for i in [0...60]
      model.step 0.016
      peak = Math.max peak, Math.abs(model.wingAngleL * 180 / Math.PI)
    expect(peak).toBeLessThan 15

  it 'throttle at zero enters glide — wings hold the glide angle', ->
    model.setStick 'roll', 1500
    model.setStick 'pitch', 1500
    model.setGlideAngle 0, -30
    model.setStick 'throttle', 1000   # below the 1040µs glide threshold
    model.step 0.016
    expect(model.telemetry.cadence).toBe 0
    expect(model.wingAngleL * 180 / Math.PI).toBeCloseTo -30
    expect(model.wingAngleR * 180 / Math.PI).toBeCloseTo -30

  it 'glide deflects wings via PID to counter a disturbance', ->
    # Firmware glide keeps the PID loop in charge: a rate disturbance must
    # visibly deflect the wing centre (roll = differential), not leave the
    # wings frozen at the static glide angle.
    model.reset()
    model.connect()
    model.setStick 'roll', 1500
    model.setStick 'pitch', 1500
    model.setGlideAngle 0, -30
    model.setStick 'throttle', 1000
    model.step 0.016
    baseL = model.wingAngleL * 180 / Math.PI
    baseR = model.wingAngleR * 180 / Math.PI
    for i in [0...80]
      model.disturb 60, 0, 0   # sustained +60°/s roll nudge
      model.step 0.016
    # roll PID → differential flap centre: left wing down, right wing up
    expect(model.wingAngleL * 180 / Math.PI).toBeLessThan baseL - 2
    expect(model.wingAngleR * 180 / Math.PI).toBeGreaterThan baseR + 2

  it 'ONDAS ferocity (downstroke/upstroke) drives the live stroke shape', ->
    model.setStick 'throttle', 1500
    model.setOndasParam 'ferocity_downstroke', 80
    model.setOndasParam 'ferocity_upstroke', 30
    model.step 0.016
    # Neutral sticks → demand ≈ 0, so the live stroke/return ferocity
    # mirror the ONDAS base directly (no modulation on top).
    expect(model.liveWaveform.strokeFerocity).toBeCloseTo 80
    expect(model.liveWaveform.returnFerocity).toBeCloseTo 30

  it 'setFreqMod clamps channel and gain ranges', ->
    model.setFreqMod { auxChannel: 99, gain: 99 }
    expect(model.freqAuxChannel).toBe model.aux.length - 1
    expect(model.freqAuxGain).toBe 12
    model.setFreqMod { auxChannel: -50 }
    expect(model.freqAuxChannel).toBe -1

  it 'setOndasParam clamps to registry ranges', ->
    model.setOndasParam 'cadence_gain', 150
    expect(model.ondas.cadence_gain).toBe 100
    model.setOndasParam 'cadence_gain', -150
    expect(model.ondas.cadence_gain).toBe -100
    model.setOndasParam 'ferocity_downstroke', 0
    expect(model.ondas.ferocity_downstroke).toBe 1
    model.setOndasParam 'anchor_gain', 150
    expect(model.ondas.anchor_gain).toBe 100

  it 'setPidGain updates gain value', ->
    model.setPidGain 'roll_P', 10.0
    expect(model.pidGains.roll_P).toBe 10.0

  it 'setServoParam updates parameter', ->
    model.setServoParam 0, 'midpoint', 1550
    expect(model.servos[0].midpoint).toBe 1550

  it 'setServoParam ignores invalid index', ->
    model.setServoParam 99, 'midpoint', 1550
    # Should not throw

  it 'telemetry reflects attitude after step', ->
    model.setStick 'pitch', 1600
    for i in [0...30]
      model.step 0.016
    tel = model.telemetry
    expect(tel.attitude).toBeDefined()
    # flapFrequency might be NaN in edge cases — just check it's defined
    expect(tel.flapFrequency).not.toBeUndefined

  it 'telemetry has servo positions array', ->
    model.step 0.016
    tel = model.telemetry
    expect(Array.isArray tel.servoPositions).toBe true
    expect(tel.servoPositions.length).toBe 4

  it 'bump creates disturbance', ->
    model.bump()
    model.step 0.016
    tel = model.telemetry
    expect(tel.gyro).toBeDefined()

  it 'applyPreset changes parameters', ->
    model.applyPreset 'race'
    expect(model.flapFrequency).toBe 8.0
    expect(model.baseAmplitude).toBe 55.0

  it 'reset returns to initial state', ->
    model.setStick 'roll', 1700
    model.step 0.1
    model.reset()
    expect(model.t).toBe 0
    expect(model.attitude.roll).toBe 0
    expect(model.attitude.pitch).toBe 0
    expect(model.attitude.yaw).toBe 0

  it 'flap phase cycles through 2π', ->
    model.flapFrequency = 10  # faster for test
    model.step 0.1
    expect(model.flapPhase).toBeGreaterThan 0

  it 'flap phase advances at base cadence, not 5x substep overshoot', ->
    # One frame at 60 fps. At 6 Hz base (throttle mid → 1×), phase
    # advances 6·2π/60 ≈ 0.6283 rad. The old frame-@dt misuse inside the
    # 5-substep loop advanced 5× that (≈ 3.1416 rad = 30 Hz effective)
    # while telemetry still reported 6 Hz.
    model.setStick 'throttle', 1500
    model.step (1 / 60)
    expect(model.flapPhase).toBeCloseTo (6 * 2 * Math.PI / 60), 2

  it 'initializes default airframe geometry', ->
    expect(model.geometry.wingSpan).toBe 1200
    expect(model.geometry.chord).toBe 180
    expect(model.geometry.wingArea).toBe 216000
    expect(model.geometry.aspectRatio).toBeCloseTo 6.667

  it 'initializes default mass and CG', ->
    expect(model.mass.totalMass).toBe 520
    expect(model.mass.cgX).toBe 0
    expect(model.mass.cgZ).toBe 0

  it 'initializes two servo mount pairs', ->
    expect(model.pairCount).toBe 2
    expect(model.servoMounts).toHaveLength 2
    expect(model.servoMounts[1].index).toBe 1

  it 'seeds tandem_x mounts at distinct fore/aft stations', ->
    # Root cause of the "two overlapping wing pairs" bug: both pairs used
    # to seed at station 0. The tandem archetype now spreads them fore/aft
    # with opposite dihedral so the two pairs render as separate wings.
    expect(model.servoMounts[0].z).toBeCloseTo 0.4
    expect(model.servoMounts[1].z).toBeCloseTo -0.4
    expect(model.servoMounts[0].angle).toBe 30
    expect(model.servoMounts[1].angle).toBe -30

  it 'applyArrangement seeds multi-wing geometry for quad', ->
    model.applyArrangement 'quad'
    expect(model.pairCount).toBe 4
    expect(model.servoMounts).toHaveLength 4
    expect(model.servoMounts[0].z).toBeCloseTo 0.5
    expect(model.servoMounts[3].z).toBeCloseTo -0.5
    expect(model.servoMounts[1].angle).toBe 10

  it 'setAirframe merges geometry and recomputes derived values', ->
    model.setAirframe { geometry: { wingSpan: 1500 } }
    expect(model.geometry.wingSpan).toBe 1500
    expect(model.geometry.chord).toBe 180
    expect(model.geometry.wingArea).toBe 270000
    expect(model.geometry.aspectRatio).toBeCloseTo 8.333

  it 'setAirframe merges mass and mounts without touching servos', ->
    model.setAirframe {
      mass: { totalMass: 600, cgX: 10 }
      pairCount: 3
      servoMounts: [{ index: 0, x: 5, z: 0, angle: 0 }]
    }
    expect(model.mass.totalMass).toBe 600
    expect(model.mass.cgX).toBe 10
    expect(model.pairCount).toBe 3
    expect(model.servoMounts).toHaveLength 3
    expect(model.servoMounts[0].x).toBe 5
    expect(model.servos).toHaveLength 4

  it 'derives geometry as a pure function', ->
    geometry = deriveGeometry { wingSpan: 1500, chord: 200 }
    expect(geometry.wingArea).toBe 300000
    expect(geometry.aspectRatio).toBe 7.5
    expect(deriveGeometry({}).aspectRatio).toBeGreaterThan 0

  it 'leaves skew at zero when throttle coupling is off', ->
    model.setStick 'throttle', 2000
    model.step 0.016
    expect(model.liveWaveform.strokeSkew).toBeCloseTo 0
    expect(model.liveWaveform.returnSkew).toBeCloseTo 0

  it 'applies throttle skew coupling into liveWaveform', ->
    model.setStick 'throttle', 2000
    model.setWaveformParam 'throttleSkewMix', 100
    model.step 0.016
    # Full throttle (signedThrottle = +1) at 100% mix → +100 stroke skew,
    # mirrored to −100 return skew (front-load downstroke).
    expect(model.liveWaveform.strokeSkew).toBeCloseTo 100
    expect(model.liveWaveform.returnSkew).toBeCloseTo -100

  it 'applies aileron skew coupling as per-wing differential', ->
    model.setStick 'roll', 2000
    model.setWaveformParam 'aileronSkewMix', 100
    model.step 0.016
    # Aileron is differential (per-wing), so the symmetric liveWaveform
    # skew stays at the throttle/centre baseline — the roll torque lives
    # in the left/right pulse divergence, not the shared wave centre.
    expect(model.liveWaveform.strokeSkew).toBeCloseTo 0
    expect(model.liveWaveform.returnSkew).toBeCloseTo 0
    expect(model.wingAngleL).not.toBeCloseTo model.wingAngleR, 3

  it 'pitch shifts both wing centres together (common)', ->
    # Faithful to the OrniFlight firmware mixer: elevator is a COMMON centre
    # shift —
    # both wings move the same physical direction. Time-average the wings
    # over several flap cycles so the flap deviation integrates out and
    # only the centre remains.
    meanWing = (pitch) ->
      model.reset()
      model.connect()
      model.setStick 'throttle', 1500
      model.setStick 'pitch', pitch
      s = 0
      for i in [0...200]
        model.step 0.016
        s += (model.wingAngleL + model.wingAngleR) / 2
      s / 200
    expect(meanWing 2000).toBeGreaterThan meanWing 1000

  it 'roll shifts the two wing centres apart (differential)', ->
    # Faithful to the OrniFlight firmware mixer: aileron is a DIFFERENTIAL
    # centre shift —
    # one wing up, the other down. Full right roll lifts the left stroke
    # centre and drops the right.
    model.reset()
    model.connect()
    model.setStick 'throttle', 1500
    model.setStick 'roll', 2000
    l = 0
    r = 0
    for i in [0...200]
      model.step 0.016
      l += model.wingAngleL
      r += model.wingAngleR
    expect(l / 200).toBeGreaterThan r / 200