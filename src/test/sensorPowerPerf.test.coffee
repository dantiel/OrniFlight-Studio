import { describe, it, expect } from 'vitest'
import {
  decodeSensorConfig, encodeSensorConfig
  decodeSensorAlignment, encodeSensorAlignment
  decodeBatteryConfig, encodeBatteryConfig
  decodeVoltageMeterConfig, encodeVoltageMeterConfig
  decodeCurrentMeterConfig, encodeCurrentMeterConfig
  decodeAdjustmentRanges, encodeAdjustmentRange
} from '../protocol/mspDecoders.coffee'
import {
  sanitizeSensorConfig, sanitizeSensorAlignment
} from '../lib/sensorsCatalog.coffee'
import {
  sanitizeBatteryConfig, sanitizeVoltageMeterConfig
  sanitizeCurrentMeterConfig
} from '../lib/powerCatalog.coffee'
import { sanitizeAdjustmentRange } from '../lib/adjustmentsCatalog.coffee'
import useSensorsStore from '../stores/useSensorsStore.coffee'
import usePowerStore from '../stores/usePowerStore.coffee'
import useAdjustmentsStore from '../stores/useAdjustmentsStore.coffee'

hostilePatch = ->
  JSON.parse '{"__proto__": {"polluted": true}, "constructor": "x"}'

describe 'validatio security probe', ->
  it 'catalog sanitizers discard hostile prototype-pollution keys', ->
    expect({}.polluted).toBeUndefined()
    for sanitize in [
      sanitizeSensorConfig, sanitizeSensorAlignment
      sanitizeBatteryConfig, sanitizeVoltageMeterConfig
      sanitizeCurrentMeterConfig, sanitizeAdjustmentRange
    ]
      clean = sanitize hostilePatch()
      expect(
        Object.getPrototypeOf clean
      ).toBe Object.prototype
      expect(Object.keys(clean).includes('constructor')).toBe false
      expect(clean.polluted).toBeUndefined()
    expect({}.polluted).toBeUndefined()

  it 'sanitizers never alias their input document', ->
    input = sanitizeSensorConfig()
    clone = sanitizeSensorConfig input
    expect(clone).not.toBe input
    clone.accHardware = 99
    expect(input.accHardware).not.toBe 99

  it 'sensor store setters reject hostile patches without dirty churn', ->
    useSensorsStore.getState().reset()
    count = 0
    unsubscribe = useSensorsStore.subscribe -> count += 1
    useSensorsStore.getState().setSensorConfig hostilePatch()
    useSensorsStore.getState().setSensorAlignment hostilePatch()
    expect(count).toBe 0
    expect(useSensorsStore.getState().dirty).toBe false
    expect({}.polluted).toBeUndefined()
    unsubscribe()

  it 'adjustment store setRange rejects hostile patches', ->
    useAdjustmentsStore.getState().reset()
    count = 0
    unsubscribe = useAdjustmentsStore.subscribe -> count += 1
    useAdjustmentsStore.getState().setRange 0, hostilePatch()
    expect(count).toBe 0
    expect(useAdjustmentsStore.getState().dirty).toBe false
    expect({}.polluted).toBeUndefined()
    unsubscribe()

  it 'a real mutation emits exactly one store notification', ->
    useSensorsStore.getState().reset()
    usePowerStore.getState().reset()
    useAdjustmentsStore.getState().reset()
    sensorCount = 0
    powerCount = 0
    adjustmentCount = 0
    unsubscribeSensor = useSensorsStore.subscribe -> sensorCount += 1
    unsubscribePower = usePowerStore.subscribe -> powerCount += 1
    unsubscribeAdjustment = useAdjustmentsStore.subscribe ->
      adjustmentCount += 1
    useSensorsStore.getState().setSensorConfig { accHardware: 8 }
    usePowerStore.getState().setBattery { capacityMah: 1500 }
    useAdjustmentsStore.getState().setRange 3, { startStep: 1350 }
    expect(sensorCount).toBe 1
    expect(powerCount).toBe 1
    expect(adjustmentCount).toBe 1
    unsubscribeSensor()
    unsubscribePower()
    unsubscribeAdjustment()

describe 'validatio performance probe', ->
  it 'codec roundtrip hot path: 100k iterations', ->
    sensorConfig = { accHardware: 3, baroHardware: 4, magHardware: 5 }
    alignment = {
      gyroAlign: 1, accAlign: 1, magAlign: 2, gyroDetectionFlags: 0
      gyroToUse: 0, gyro1Align: 1, gyro2Align: 0
    }
    battery = {
      minCellVoltage: 330, maxCellVoltage: 435
      warningCellVoltage: 350, capacityMah: 1500
      voltageMeterSource: 10, currentMeterSource: 80
    }
    voltage = {
      id: 10, type: 0, scale: 110, dividerValue: 10
      dividerMultiplier: 1
    }
    current = { id: 80, type: 2, scale: 250, offset: 0 }
    range = {
      adjustmentIndex: 5, auxChannelIndex: 2, startStep: 1300
      endStep: 1700, adjustmentConfig: 100, auxSwitchChannelIndex: 1
    }
    start = performance.now()
    for i in [0...100000]
      decodeSensorConfig encodeSensorConfig sensorConfig
      decodeSensorAlignment encodeSensorAlignment alignment
      decodeBatteryConfig encodeBatteryConfig battery
      decodeVoltageMeterConfig encodeVoltageMeterConfig voltage
      decodeCurrentMeterConfig encodeCurrentMeterConfig current
      decodeAdjustmentRanges encodeAdjustmentRange 0, range
    elapsed = performance.now() - start
    opsPerSec = Math.round 600000 / (elapsed / 1000)
    console.log(
      "CODEC BENCH: 600k ops in #{elapsed.toFixed 1}ms = #{opsPerSec} ops/s"
    )
    # Wall-clock microbenchmark: tolerate parallel-suite load noise (baseline
    # ~900ms); 5000ms still catches order-of-magnitude codec regressions.
    expect(elapsed).toBeLessThan 5000

  it 'store mutation throughput: 6k range + 25k config ops', ->
    useAdjustmentsStore.getState().reset()
    useSensorsStore.getState().reset()
    usePowerStore.getState().reset()
    start = performance.now()
    for round in [0...200]
      for slot in [0...30]
        useAdjustmentsStore.getState().setRange slot, {
          startStep: 1300 + (slot % 7) + round % 3
        }
    for i in [0...5000]
      useSensorsStore.getState().setSensorConfig { accHardware: i % 16 }
      useSensorsStore.getState().setSensorAlignment { gyroAlign: i % 6 }
      usePowerStore.getState().setBattery { capacityMah: i % 4000 }
      usePowerStore.getState().setVoltageMeter { scale: 100 + i % 30 }
      usePowerStore.getState().setCurrentMeter { offset: i % 500 }
    elapsed = performance.now() - start
    console.log "STORE BENCH: 31k mutations in #{elapsed.toFixed 1}ms"
    expect(elapsed).toBeLessThan 5000