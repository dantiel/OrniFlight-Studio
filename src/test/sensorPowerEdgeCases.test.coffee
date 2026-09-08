import { describe, it, expect, vi, beforeEach } from 'vitest'
import {
  decodeSensorConfig, encodeSensorConfig
  decodeSensorAlignment
  decodeBatteryConfig, encodeBatteryConfig
  decodeVoltageMeterConfig
  decodeCurrentMeterConfig
  decodeAdjustmentRanges
} from '../protocol/mspDecoders.coffee'
import {
  DEFAULT_SENSOR_CONFIG, DEFAULT_SENSOR_ALIGNMENT
  sanitizeSensorConfig, sanitizeSensorAlignment
} from '../lib/sensorsCatalog.coffee'
import {
  DEFAULT_BATTERY_CONFIG, DEFAULT_VOLTAGE_METER_CONFIG
  DEFAULT_CURRENT_METER_CONFIG
  sanitizeBatteryConfig, sanitizeVoltageMeterConfig
  sanitizeCurrentMeterConfig
} from '../lib/powerCatalog.coffee'
import {
  DEFAULT_ADJUSTMENT_RANGE, MAX_ADJUSTMENT_RANGE_COUNT
  sanitizeAdjustmentRange, adjustmentStepToUsec, adjustmentUsecToStep
} from '../lib/adjustmentsCatalog.coffee'
import useSensorsStore from '../stores/useSensorsStore.coffee'
import usePowerStore from '../stores/usePowerStore.coffee'
import useAdjustmentsStore from '../stores/useAdjustmentsStore.coffee'

sensorState = -> useSensorsStore.getState()
powerState = -> usePowerStore.getState()
adjustmentState = -> useAdjustmentsStore.getState()

emptySensorSession = ->
  {
    readSensorConfig: vi.fn -> Promise.resolve null
    readSensorAlignment: vi.fn -> Promise.resolve null
    writeSensorConfig: vi.fn (config) -> Promise.resolve { config... }
    writeSensorAlignment: vi.fn (alignment) -> Promise.resolve { alignment... }
    calibrateAccelerometer: vi.fn -> Promise.resolve true
    calibrateMagnetometer: vi.fn -> Promise.resolve true
  }

describe 'sensor, power & adjustment edge cases', ->
  beforeEach ->
    sensorState().reset()
    powerState().reset()
    adjustmentState().reset()

  describe 'sanitizer non-finite handling', ->
    it 'maps NaN/Infinity to the wire-min bound (never leaks NaN)', ->
      expect(sanitizeSensorConfig(accHardware: NaN).accHardware).toBe 0
      expect(sanitizeSensorConfig(accHardware: Infinity).accHardware).toBe 0
      expect(sanitizeSensorAlignment(gyroAlign: NaN).gyroAlign).toBe 0
      expect(sanitizeSensorAlignment(magAlign: -Infinity).magAlign).toBe 0

    it 'clamps battery and meter fields against non-finite input', ->
      expect(sanitizeBatteryConfig(minCellVoltage: NaN).minCellVoltage).toBe 0
      expect(sanitizeBatteryConfig(capacityMah: Infinity).capacityMah).toBe 0
      expect(sanitizeBatteryConfig(maxCellVoltage: -Infinity).maxCellVoltage)
        .toBe 0
      expect(sanitizeVoltageMeterConfig(scale: NaN).scale).toBe 0
      expect(sanitizeCurrentMeterConfig(offset: -Infinity).offset).toBe 0

    it 'collapses non-finite adjustment ranges to their lower bound', ->
      range = sanitizeAdjustmentRange startStep: NaN, adjustmentConfig: NaN
      expect(range.startStep).toBe 0
      expect(range.adjustmentConfig).toBe 0
      slot = sanitizeAdjustmentRange adjustmentIndex: 99
      expect(slot.adjustmentIndex).toBe 3
      aux = sanitizeAdjustmentRange auxChannelIndex: -1
      expect(aux.auxChannelIndex).toBe 0

    it 'keeps usec/step conversion finite', ->
      expect(adjustmentStepToUsec NaN).toBe 900
      expect(adjustmentStepToUsec Infinity).toBe 900
      expect(adjustmentUsecToStep NaN).toBe 0
      expect(adjustmentUsecToStep Infinity).toBe 0

  describe 'codec truncation degradation', ->
    it 'degrades an empty SENSOR_CONFIG payload to firmware defaults', ->
      expect(decodeSensorConfig new Uint8Array []).toEqual DEFAULT_SENSOR_CONFIG

    it 'degrades an empty SENSOR_ALIGNMENT payload to firmware defaults', ->
      expect(decodeSensorAlignment new Uint8Array [])
        .toEqual DEFAULT_SENSOR_ALIGNMENT

    it 'degrades short BATTERY_CONFIG payloads to firmware defaults', ->
      empty = decodeBatteryConfig new Uint8Array []
      expect(empty.minCellVoltage).toBe DEFAULT_BATTERY_CONFIG.minCellVoltage
      expect(empty.maxCellVoltage).toBe DEFAULT_BATTERY_CONFIG.maxCellVoltage
      expect(empty.warningCellVoltage)
        .toBe DEFAULT_BATTERY_CONFIG.warningCellVoltage
      single = decodeBatteryConfig new Uint8Array [33]
      expect(single.minCellVoltage).toBe 330
      expect(single.maxCellVoltage).toBe DEFAULT_BATTERY_CONFIG.maxCellVoltage
      pair = decodeBatteryConfig new Uint8Array [33, 43]
      expect(pair.minCellVoltage).toBe 330
      expect(pair.maxCellVoltage).toBe 430
      expect(pair.warningCellVoltage)
        .toBe DEFAULT_BATTERY_CONFIG.warningCellVoltage

    it 'degrades empty variable-frame meter payloads to defaults', ->
      expect(decodeVoltageMeterConfig new Uint8Array [])
        .toEqual DEFAULT_VOLTAGE_METER_CONFIG
      expect(decodeCurrentMeterConfig new Uint8Array [])
        .toEqual DEFAULT_CURRENT_METER_CONFIG

    it 'returns an empty range list for an empty ADJUSTMENT_RANGES payload', ->
      expect(decodeAdjustmentRanges new Uint8Array []).toEqual []

  describe 'encoder NaN safety at the wire boundary', ->
    it 'emits defaults instead of NaN in the sensor record', ->
      wire = encodeSensorConfig { accHardware: NaN, magHardware: 4 }
      expect(Array.from wire).toEqual [0, 0, 4]

    it 'emits defaults instead of NaN in the battery record', ->
      wire = encodeBatteryConfig {
        minCellVoltage: NaN, maxCellVoltage: 430, warningCellVoltage: 350
      }
      expect(Array.from wire[..2]).toEqual [0, 43, 35]

  describe 'store error scenarios', ->
    it 'rejects unknown modes', ->
      expect(-> sensorState().setMode 'bogus').toThrow 'Unknown sensor mode'
      expect(-> powerState().setMode 'bogus').toThrow 'Unknown power mode'
      expect(-> adjustmentState().setMode 'bogus').toThrow(
        'Unknown adjustments mode'
      )

    it 'attaching a null session returns to sim mode', ->
      sensorState().attachSession emptySensorSession()
      expect(sensorState().mode).toBe 'device'
      sensorState().attachSession null
      expect(sensorState().mode).toBe 'sim'
      expect(sensorState().session).toBeNull()

    it 'refuses to load without a device session', ->
      error = await sensorState().loadFromDevice().catch (error) -> error
      expect(error.message).toContain 'No device session'

    it 'refuses to save in device mode before loading', ->
      sensorState().attachSession emptySensorSession()
      error = await sensorState().save().catch (error) -> error
      expect(error.message).toContain 'Read device sensor configuration'

    it 'rejects non-integer, negative and NaN adjustment slots', ->
      expect(-> adjustmentState().setRange -1, {}).toThrow 'out of range'
      expect(-> adjustmentState().setRange 29.5, {}).toThrow 'out of range'
      expect(-> adjustmentState().setRange NaN, {}).toThrow 'out of range'
      expect(adjustmentState().dirty).toBe false

    it 'pads to defaults when the device returns null ranges', ->
      session =
        readAdjustmentRanges: vi.fn -> Promise.resolve null
        writeAdjustmentRange: vi.fn -> Promise.resolve null
      adjustmentState().attachSession session
      draft = await adjustmentState().loadFromDevice()
      expect(draft.ranges).toHaveLength MAX_ADJUSTMENT_RANGE_COUNT
      expect(draft.ranges[0]).toEqual { DEFAULT_ADJUSTMENT_RANGE..., index: 0 }
      expect(draft.ranges[29].index).toBe 29