import { describe, it, expect } from 'vitest'
import {
  decodeSensorConfig, encodeSensorConfig, SENSOR_CONFIG_BYTES
  decodeSensorAlignment, encodeSensorAlignment, SENSOR_ALIGNMENT_BYTES
  decodeBatteryConfig, encodeBatteryConfig, BATTERY_CONFIG_BYTES
  decodeVoltageMeterConfig, encodeVoltageMeterConfig
  VOLTAGE_METER_CONFIG_BYTES
  decodeCurrentMeterConfig, encodeCurrentMeterConfig
  CURRENT_METER_CONFIG_BYTES
  decodeAdjustmentRanges, encodeAdjustmentRange
  ADJUSTMENT_RANGE_WRITE_BYTES, MAX_ADJUSTMENT_RANGE_COUNT
} from '../protocol/mspDecoders.coffee'
import {
  DEFAULT_SENSOR_CONFIG, DEFAULT_SENSOR_ALIGNMENT
} from '../lib/sensorsCatalog.coffee'
import {
  DEFAULT_BATTERY_CONFIG, DEFAULT_VOLTAGE_METER_CONFIG
} from '../lib/powerCatalog.coffee'

bytesOf = (view) -> Array.from view

describe 'sensor, power & adjustment codecs', ->
  it 'decodes the 3-byte SENSOR_CONFIG record', ->
    config = decodeSensorConfig new Uint8Array [2, 4, 4]
    expect(config).toEqual { accHardware: 2, baroHardware: 4, magHardware: 4 }

  it 'falls back to defaults when SENSOR_CONFIG is truncated', ->
    partial = decodeSensorConfig new Uint8Array [2]
    expect(partial.accHardware).toBe 2
    expect(partial.baroHardware).toBe DEFAULT_SENSOR_CONFIG.baroHardware
    expect(partial.magHardware).toBe DEFAULT_SENSOR_CONFIG.magHardware

  it 'encodes SENSOR_CONFIG byte-exact and clamps', ->
    wire = encodeSensorConfig {
      accHardware: 2, baroHardware: 4, magHardware: 4
    }
    expect(wire.length).toBe SENSOR_CONFIG_BYTES
    expect(bytesOf wire).toEqual [2, 4, 4]
    clamped = encodeSensorConfig { accHardware: 999, baroHardware: -1 }
    expect(bytesOf clamped).toEqual [
      255, 0, DEFAULT_SENSOR_CONFIG.magHardware
    ]

  it 'round-trips SENSOR_CONFIG through encode and decode', ->
    config = { accHardware: 5, baroHardware: 6, magHardware: 1 }
    decoded = decodeSensorConfig encodeSensorConfig config
    expect(decoded).toEqual config

  it 'decodes the 7-byte SENSOR_ALIGNMENT read record', ->
    alignment = decodeSensorAlignment new Uint8Array [1, 1, 2, 3, 0, 4, 5]
    expect(alignment).toEqual {
      gyroAlign: 1, accAlign: 1, magAlign: 2, gyroDetectionFlags: 3
      gyroToUse: 0, gyro1Align: 4, gyro2Align: 5
    }

  it 'encodes the 6-byte SET_SENSOR_ALIGNMENT record (acc discarded)', ->
    wire = encodeSensorAlignment {
      gyroAlign: 1, magAlign: 2, gyroToUse: 0, gyro1Align: 4, gyro2Align: 5
    }
    expect(wire.length).toBe SENSOR_ALIGNMENT_BYTES
    expect(bytesOf wire).toEqual [1, 0, 2, 0, 4, 5]

  it 'round-trips the writable SENSOR_ALIGNMENT fields', ->
    alignment =
      gyroAlign: 2
      magAlign: 4
      gyroToUse: 0
      gyro1Align: 2
      gyro2Align: 0
    decoded = decodeSensorAlignment encodeSensorAlignment alignment
    expect(decoded.gyroAlign).toBe 2
    expect(decoded.magAlign).toBe 4
    expect(decoded.gyroToUse).toBe 0
    expect(decoded.gyro1Align).toBe 2
    expect(decoded.gyro2Align).toBe 0
    defaultFlags = DEFAULT_SENSOR_ALIGNMENT.gyroDetectionFlags
    expect(decoded.gyroDetectionFlags).toBe defaultFlags

  it 'decodes the legacy 3-byte BATTERY_CONFIG prefix', ->
    config = decodeBatteryConfig(new Uint8Array [33, 43, 35])
    expect(config.minCellVoltage).toBe 330
    expect(config.maxCellVoltage).toBe 430
    expect(config.warningCellVoltage).toBe 350
    expect(config.capacityMah).toBe DEFAULT_BATTERY_CONFIG.capacityMah

  it 'decodes the full 13-byte BATTERY_CONFIG record', ->
    wire = [33, 43, 35, 0xe8, 0x03, 0, 0, 0x4a, 0x01, 0xae, 0x01, 0x5e, 0x01]
    config = decodeBatteryConfig new Uint8Array wire
    expect(config.minCellVoltage).toBe 330
    expect(config.maxCellVoltage).toBe 430
    expect(config.warningCellVoltage).toBe 350
    expect(config.capacityMah).toBe 1000
    expect(config.voltageMeterSource).toBe 0
    expect(config.currentMeterSource).toBe 0

  it 'encodes BATTERY_CONFIG byte-exact', ->
    wire = encodeBatteryConfig {
      minCellVoltage: 330, maxCellVoltage: 430, warningCellVoltage: 350
      capacityMah: 1000, voltageMeterSource: 0, currentMeterSource: 0
    }
    expect(wire.length).toBe BATTERY_CONFIG_BYTES
    expect(bytesOf wire).toEqual [
      33, 43, 35, 0xe8, 0x03, 0, 0, 0x4a, 0x01, 0xae, 0x01, 0x5e, 0x01
    ]

  it 'round-trips BATTERY_CONFIG through encode and decode', ->
    config = {
      minCellVoltage: 341, maxCellVoltage: 425, warningCellVoltage: 355
      capacityMah: 4500, voltageMeterSource: 1, currentMeterSource: 0
    }
    decoded = decodeBatteryConfig encodeBatteryConfig config
    expect(decoded).toEqual config

  it 'decodes the 7-byte VOLTAGE_METER_CONFIG frame', ->
    meter = decodeVoltageMeterConfig new Uint8Array [1, 5, 10, 0, 110, 10, 1]
    expect(meter).toEqual {
      id: 10, type: 0, scale: 110, dividerValue: 10, dividerMultiplier: 1
    }

  it 'falls back to the default voltage meter on an empty frame', ->
    meter = decodeVoltageMeterConfig new Uint8Array []
    expect(meter).toEqual DEFAULT_VOLTAGE_METER_CONFIG

  it 'encodes the bare 4-byte SET_VOLTAGE_METER_CONFIG record', ->
    wire = encodeVoltageMeterConfig {
      id: 10, scale: 110, dividerValue: 10, dividerMultiplier: 1
    }
    expect(wire.length).toBe VOLTAGE_METER_CONFIG_BYTES
    expect(bytesOf wire).toEqual [10, 110, 10, 1]

  it 'decodes the 8-byte CURRENT_METER_CONFIG frame', ->
    meter = decodeCurrentMeterConfig new Uint8Array [
      1, 6, 10, 1, 0x90, 0x01, 0x00, 0x00
    ]
    expect(meter).toEqual { id: 10, type: 1, scale: 400, offset: 0 }

  it 'encodes the bare 5-byte SET_CURRENT_METER_CONFIG record', ->
    wire = encodeCurrentMeterConfig { id: 10, scale: 400, offset: 25 }
    expect(wire.length).toBe CURRENT_METER_CONFIG_BYTES
    expect(bytesOf wire).toEqual [10, 0x90, 0x01, 25, 0]

  it 'decodes ADJUSTMENT_RANGES records with implicit slot indices', ->
    recordA = [0, 2, 10, 20, 1, 0]
    recordB = [1, 3, 0, 0, 7, 0]
    ranges = decodeAdjustmentRanges new Uint8Array recordA.concat recordB
    expect(ranges.length).toBe 2
    expect(ranges[0]).toEqual {
      index: 0, adjustmentIndex: 0, auxChannelIndex: 2, startStep: 10
      endStep: 20, adjustmentConfig: 1, auxSwitchChannelIndex: 0
    }
    expect(ranges[1].index).toBe 1
    expect(ranges[1].adjustmentConfig).toBe 7

  it 'caps ADJUSTMENT_RANGES at 30 slots', ->
    records = []
    records.push 0, 0, 0, 0, 0, 0 for _ in [0...35]
    ranges = decodeAdjustmentRanges new Uint8Array records
    expect(ranges.length).toBe MAX_ADJUSTMENT_RANGE_COUNT

  it 'encodes SET_ADJUSTMENT_RANGE as the 7-byte indexed record', ->
    wire = encodeAdjustmentRange 4, {
      adjustmentIndex: 1, auxChannelIndex: 2, startStep: 10, endStep: 20
      adjustmentConfig: 7, auxSwitchChannelIndex: 3
    }
    expect(wire.length).toBe ADJUSTMENT_RANGE_WRITE_BYTES
    expect(bytesOf wire).toEqual [4, 1, 2, 10, 20, 7, 3]