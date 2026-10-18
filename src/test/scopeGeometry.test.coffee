import { describe, it, expect } from 'vitest'
import {
  clamp01, traceChannel, autoRange, buildScopeBands
} from '../components/views/SchlagdynamikView/scopeGeometry.coffee'

describe 'StrokeScope geometry', ->
  hist = for i in [0...10]
    wingL: Math.sin(i / 2)
    wingR: Math.cos(i / 2)
    gyroRoll: i * 0.5
    gyroPitch: 0
    gyroYaw: 0
    ferStroke: 40 + i
    ferReturn: 50 - i * 0.5
    ferShape: 10

  it 'clamp01 pins to the unit interval', ->
    expect(clamp01 -1).toBe 0
    expect(clamp01 2).toBe 1
    expect(clamp01 0.5).toBeCloseTo 0.5

  it 'traceChannel maps a window into monotonic normalised points', ->
    pts = traceChannel hist, 'wingL', -1, 1
    expect(pts).toHaveLength 10
    expect(pts[0][0]).toBeCloseTo 0
    expect(pts[pts.length - 1][0]).toBeCloseTo 1
    for [x, y] in pts
      expect(x).toBeGreaterThanOrEqual 0
      expect(x).toBeLessThanOrEqual 1
      expect(y).toBeGreaterThanOrEqual 0
      expect(y).toBeLessThanOrEqual 1

  it 'autoRange floors a silent channel to ±1', ->
    r = autoRange hist, 'gyroPitch'
    expect(r.hi - r.lo).toBeGreaterThanOrEqual 2

  it 'buildScopeBands emits every live channel', ->
    bands = buildScopeBands hist, 45
    expect(bands.wingL).toHaveLength 10
    expect(bands.wingR).toHaveLength 10
    expect(bands.gyroRoll).toHaveLength 10
    expect(bands.gyroPitch).toHaveLength 10
    expect(bands.gyroYaw).toHaveLength 10
    expect(bands.cadence).toHaveLength 10
    expect(bands.ferStroke).toHaveLength 10
    expect(bands.ferReturn).toHaveLength 10
    expect(bands.ferShape).toHaveLength 10

  it 'returns empty traces for a singleton window', ->
    bands = buildScopeBands [{ wingL: 0, wingR: 0 }], 45
    expect(bands.wingL).toHaveLength 0