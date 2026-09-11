import { describe, it, expect } from 'vitest'
import {
  shapeWave, ferocityUnits, throttleSkewShift, aileronSkewShift
  throttleSkewRateShift, sampleWave, modulateWaveform
} from '../simulation/waveform.coffee'

approx = (a, b, eps = 1e-3) -> Math.abs(a - b) < eps

describe 'waveform kernel (PteronautOS port)', ->

  it 'ferocity slider maps 0–100 to 0–8 units', ->
    expect(ferocityUnits 0).toBe 0
    expect(ferocityUnits 50).toBeCloseTo 4, 5
    expect(ferocityUnits 100).toBe 8
    expect(ferocityUnits 200).toBe 8
    expect(ferocityUnits -10).toBe 0

  it 'emits a bounded pulse in [-1, 1]', ->
    for i in [0...100]
      theta = (i / 100) * 2 * Math.PI
      y = shapeWave theta, 5, 3, -1, 40, 60, -60
      expect(y).toBeGreaterThanOrEqual -1
      expect(y).toBeLessThanOrEqual 1

  it 'ferocity 0 / mix 0 is a pure cosine ramp', ->
    expect(shapeWave 0, 0, 0).toBeCloseTo 1, 4
    expect(shapeWave Math.PI / 2, 0, 0).toBeCloseTo 0, 4
    expect(shapeWave (3 * Math.PI) / 2, 0, 0).toBeCloseTo 0, 4

  it 'positive stroke skew front-loads the downstroke centre', ->
    # Mid-downstroke (t=0.5) with +100 skew → t'=0.75 → cos(0.75π)
    baseline = shapeWave Math.PI / 2, 0, 0, -1, 0, 0, 0
    skewed = shapeWave Math.PI / 2, 0, 0, -1, 0, 100, 0
    expect(baseline).toBeCloseTo 0, 4
    expect(skewed).toBeCloseTo -0.7071, 2

  it 'skew is endpoint-pinned (0→0, 1→1 per half)', ->
    atStart = shapeWave 0.0001, 0, 0, -1, 0, 100, -100
    expect(atStart).toBeCloseTo 1, 2

  it 'throttle skew shift is ±100 at the extremes, 0 at mid', ->
    expect(throttleSkewShift 1, 100).toBeCloseTo 100, 4
    expect(throttleSkewShift 0, 100).toBeCloseTo -100, 4
    expect(throttleSkewShift 0.5, 100).toBeCloseTo 0, 4
    expect(throttleSkewShift 1, 0).toBeCloseTo 0, 4

  it 'aileron skew shift scales by stick and coupling', ->
    expect(aileronSkewShift 1, 50).toBeCloseTo 50, 4
    expect(aileronSkewShift -1, 50).toBeCloseTo -50, 4
    expect(aileronSkewShift 0.5, 100).toBeCloseTo 50, 4

  it 'slew rate shift clamps to the ±100 envelope', ->
    expect(throttleSkewRateShift 1000, 100).toBe 100
    expect(throttleSkewRateShift -1000, 100).toBe -100
    expect(throttleSkewRateShift 5, 100).toBeCloseTo 50, 4
    expect(throttleSkewRateShift 5, 0).toBe 0

  it 'modulateWaveform lets ONDAS breathe into the stroke', ->
    base = { strokeFerocity: 50, returnFerocity: 50, ferocityShapeMix: 0 }
    gains =
      ferocity_p_gain: 0.2, ferocity_d_gain: 0.4
      cadence_gain: 0.3, balance_gain: 0.1
    err = { pitch: 10, roll: -5 }
    mod = modulateWaveform base, gains, err
    expect(mod.strokeFerocity).toBeGreaterThan 50
    expect(mod.returnFerocity).toBeLessThan 50
    expect(mod.ferocityShapeMix).toBeGreaterThan 0
    # Clamped to the envelope, never beyond 0..100
    expect(mod.strokeFerocity).toBeLessThanOrEqual 100
    expect(mod.returnFerocity).toBeGreaterThanOrEqual 0

  it 'sampleWave returns a full cycle with a reversal boundary', ->
    { points, limiarFraction } = sampleWave {}, 128
    expect(points).toHaveLength 128
    expect(points[0].x).toBe 0
    expect(points[127].x).toBe 1
    expect(limiarFraction).toBeGreaterThan 0
    expect(limiarFraction).toBeLessThan 1
    expect(approx points[0].y, 1, 1e-2).toBe true