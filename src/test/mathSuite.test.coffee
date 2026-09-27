import { describe, it, expect } from 'vitest'
import {
  MATH_KEYS, MATH_PARAMS, MATH_LAYERS, MATH_DEFAULTS
  strokePreviewPath, espelhoDiagnostic
} from '../lib/mathSuite.coffee'

describe 'mathSuite registry', ->
  it 'carries the fifteen-parameter suite in layer order', ->
    expect(MATH_KEYS).toHaveLength 15
    expect(MATH_KEYS[0]).toBe 'cadence_gain'
    expect(MATH_KEYS[6]).toBe 'ferocity_upstroke'
    expect(MATH_KEYS[14]).toBe 'saudade_gain'
    expect(MATH_LAYERS).toHaveLength 9

  it 'marks signed params and their ranges', ->
    expect(MATH_PARAMS.cadence_gain.signed).toBe true
    expect(MATH_PARAMS.cadence_gain.min).toBe -100
    expect(MATH_PARAMS.ferocity_p_gain.min).toBe 0
    expect(MATH_PARAMS.ferocity_downstroke.min).toBe 1
    expect(MATH_PARAMS.balance_gain.max).toBe 100

  it 'mirrors firmware reset defaults', ->
    expect(MATH_DEFAULTS.anchor_gain).toBe 10
    expect(MATH_DEFAULTS.cadence_gain).toBe 0
    expect(MATH_DEFAULTS.ferocity_downstroke).toBe 12
    expect(MATH_DEFAULTS.saudade_gain).toBe 0

describe 'strokePreviewPath', ->
  it 'returns a two-stroke path with 96 segments', ->
    path = strokePreviewPath 12, 12
    expect(path.startsWith 'M').toBe true
    expect((path.match(/L/g) or []).length).toBe 96

  it 'reflects the down/up ferocity split', ->
    downHeavy = strokePreviewPath 80, 5
    upHeavy = strokePreviewPath 5, 80
    expect(downHeavy).not.toBe upHeavy

describe 'espelhoDiagnostic', ->
  it 'returns null for silent or short samples', ->
    expect(espelhoDiagnostic [], 5).toBeNull()
    expect(espelhoDiagnostic [{ t: 0, value: 0 }], 5).toBeNull()
    expect(espelhoDiagnostic null, 5).toBeNull()

  it 'finds the second-harmonic ratio of an asymmetric stroke', ->
    samples = for i in [0...300]
      t = i * 0.002
      value = Math.sin(2 * Math.PI * 5 * t) +
        0.4 * Math.sin(4 * Math.PI * 5 * t)
      { t, value }
    diag = espelhoDiagnostic samples, 5
    expect(diag).not.toBeNull()
    expect(diag.ratio).toBeGreaterThan 0.35
    expect(diag.ratio).toBeLessThan 0.45

  it 'reports near-zero skew for a pure sine', ->
    samples = for i in [0...300]
      t = i * 0.002
      { t, value: Math.sin(2 * Math.PI * 5 * t) }
    diag = espelhoDiagnostic samples, 5
    expect(diag.ratio).toBeLessThan 0.01