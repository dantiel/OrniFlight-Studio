import { render, act } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import FailsafeView from '../components/views/FailsafeView/FailsafeView.coffee'
import useSafetyStore from '../stores/useSafetyStore.coffee'
import {
  encodeFailsafeConfig, decodeFailsafeConfig
  encodeArmingConfig, decodeArmingConfig
  encodeFeatureConfig, decodeFeatureConfig
  encodeBeeperConfig, decodeBeeperConfig
} from '../protocol/mspDecoders.coffee'

panelCounts = { failsafe: 0, arming: 0, features: 0, beeper: 0 }

countPanel = (key) ->
  panelCounts[key] += 1
  h 'div', { 'data-panel': key }

vi.mock '../components/panels/FailsafePanel/FailsafePanel.chaml', ->
  default: -> countPanel 'failsafe'
vi.mock '../components/panels/ArmingPanel/ArmingPanel.chaml', ->
  default: -> countPanel 'arming'
vi.mock '../components/panels/FeaturePanel/FeaturePanel.chaml', ->
  default: -> countPanel 'features'
vi.mock '../components/panels/BeeperPanel/BeeperPanel.chaml', ->
  default: -> countPanel 'beeper'

describe 'safety perf probe', ->
  beforeEach ->
    panelCounts.failsafe = 0
    panelCounts.arming = 0
    panelCounts.features = 0
    panelCounts.beeper = 0
    useSafetyStore.getState().reset()

  afterEach ->
    vi.restoreAllMocks()

  it 'quantifies render amplification per mutation', ->
    render h(FailsafeView, null)
    expect(panelCounts.failsafe).toBe 1
    expect(panelCounts.arming).toBe 1
    expect(panelCounts.features).toBe 1
    expect(panelCounts.beeper).toBe 1
    act -> useSafetyStore.getState().setFailsafe { delay: 9 }
    expect(panelCounts.failsafe).toBe 2
    expect(panelCounts.arming).toBe 2
    expect(panelCounts.features).toBe 2
    expect(panelCounts.beeper).toBe 2

  it 'codec roundtrip hot path: 100k iterations', ->
    failsafe = { delay: 4, offDelay: 10, throttle: 1000, switchMode: 0, throttleLowDelay: 100, procedure: 1 }
    arming = { autoDisarmDelay: 5, smallAngle: 25 }
    features = 0x0001
    beeper = { offFlags: 0, dshotBeaconTone: 0, dshotBeaconOffFlags: 0 }
    start = performance.now()
    for i in [0...100000]
      decodeFailsafeConfig encodeFailsafeConfig failsafe
      decodeArmingConfig encodeArmingConfig arming
      decodeFeatureConfig encodeFeatureConfig features
      decodeBeeperConfig encodeBeeperConfig beeper
    elapsed = performance.now() - start
    opsPerSec = Math.round 400000 / (elapsed / 1000)
    console.log "CODEC BENCH: 400k codec ops in #{elapsed.toFixed 1}ms = #{opsPerSec} ops/s"
    # Wall-clock microbenchmark: tolerate parallel-suite load noise (baseline
    # ~615ms); 5000ms still catches order-of-magnitude codec regressions.
    expect(elapsed).toBeLessThan 5000
