###
# ORNIFLIGHT STUDIO — Power Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware power wire formats exactly. Ground truth:
#
#   OrniFlight/src/main/sensors/voltage.h — voltageMeterSource_e,
#     MAX_VOLTAGE_SENSOR_ADC = 1 (VBAT only), VOLTAGE_METER_ID_BATTERY_1 = 10
#   OrniFlight/src/main/sensors/current.h — currentMeterSource_e,
#     CURRENT_METER_ID_BATTERY_1 = 10, CURRENT_SENSOR_ADC = 0
#   OrniFlight/src/main/sensors/voltage.c — VBAT_SCALE_DEFAULT 110,
#     VBAT_RESDIVVAL_DEFAULT 10, VBAT_RESDIVMULTIPLIER_DEFAULT 1
#   OrniFlight/src/main/sensors/current.c — CURRENT_METER_SCALE_DEFAULT 400,
#     CURRENT_METER_OFFSET_DEFAULT 0
#   OrniFlight/src/main/sensors/battery.c — batteryConfig_t pgReset:
#     min 330 / max 430 / warning 350 (0.01 V), capacity 0, sources NONE
#   OrniFlight/src/main/msp/msp.c — MSP_BATTERY_CONFIG (13-byte record),
#     MSP_CURRENT_METER_CONFIG (variable frame), MSP_VOLTAGE_METER_CONFIG
#     (variable frame)
#
# Ornithopter-only: the firmware undefines USE_VIRTUAL_CURRENT_METER and
# USE_ESC_SENSOR, so only the onboard ADC meters exist on the wire.
###

clampInt = (lo, hi, value) ->
  value = Math.round Number value
  value = lo unless Number.isFinite value
  Math.max lo, Math.min hi, value

clampU8 = (value) -> clampInt 0, 255, value
clampU16 = (value) -> clampInt 0, 65535, value

# voltageMeterSource_e — order is the wire id. The ornithopter target
# has no ESC sensor, so NONE/ADC are the supported sources.
VOLTAGE_METER_SOURCES = Object.freeze [
  Object.freeze { id: 0, name: 'NONE', label: 'None', supported: true }
  Object.freeze { id: 1, name: 'ADC', label: 'Onboard ADC', supported: true }
  Object.freeze { id: 2, name: 'ESC', label: 'ESC', supported: false }
]

# currentMeterSource_e — order is the wire id. Virtual and ESC meters
# are compiled out of OrniFlight; MSP is not a consumer here.
CURRENT_METER_SOURCES = Object.freeze [
  Object.freeze { id: 0, name: 'NONE', label: 'None', supported: true }
  Object.freeze { id: 1, name: 'ADC', label: 'Onboard ADC', supported: true }
  Object.freeze { id: 2, name: 'VIRTUAL', label: 'Virtual', supported: false }
  Object.freeze { id: 3, name: 'ESC', label: 'ESC', supported: false }
  Object.freeze { id: 4, name: 'MSP', label: 'MSP', supported: false }
]

VOLTAGE_METER_ID_BATTERY_1 = 10
CURRENT_METER_ID_BATTERY_1 = 10
VOLTAGE_SENSOR_TYPE_ADC_RESISTOR_DIVIDER = 0
CURRENT_SENSOR_ADC = 0

# MSP 32 record — batteryConfig_t pgResetTemplate.
DEFAULT_BATTERY_CONFIG = Object.freeze
  minCellVoltage: 330
  maxCellVoltage: 430
  warningCellVoltage: 350
  capacityMah: 0
  voltageMeterSource: 0
  currentMeterSource: 0

# MSP 56 frame — the lone VBAT ADC meter (id 10, resistor divider).
DEFAULT_VOLTAGE_METER_CONFIG = Object.freeze
  id: VOLTAGE_METER_ID_BATTERY_1
  type: VOLTAGE_SENSOR_TYPE_ADC_RESISTOR_DIVIDER
  scale: 110
  dividerValue: 10
  dividerMultiplier: 1

# MSP 40 frame — the lone onboard ADC current meter.
DEFAULT_CURRENT_METER_CONFIG = Object.freeze
  id: CURRENT_METER_ID_BATTERY_1
  type: CURRENT_SENSOR_ADC
  scale: 400
  offset: 0

sanitizeBatteryConfig = (config = {}) ->
  {
    minCellVoltage: clampU16(
      config.minCellVoltage ? DEFAULT_BATTERY_CONFIG.minCellVoltage
    )
    maxCellVoltage: clampU16(
      config.maxCellVoltage ? DEFAULT_BATTERY_CONFIG.maxCellVoltage
    )
    warningCellVoltage: clampU16(
      config.warningCellVoltage ? DEFAULT_BATTERY_CONFIG.warningCellVoltage
    )
    capacityMah: clampU16(config.capacityMah ? DEFAULT_BATTERY_CONFIG.capacityMah)
    voltageMeterSource: clampU8(
      config.voltageMeterSource ? DEFAULT_BATTERY_CONFIG.voltageMeterSource
    )
    currentMeterSource: clampU8(
      config.currentMeterSource ? DEFAULT_BATTERY_CONFIG.currentMeterSource
    )
  }

sanitizeVoltageMeterConfig = (config = {}) ->
  {
    id: clampU8(config.id ? DEFAULT_VOLTAGE_METER_CONFIG.id)
    type: clampU8(config.type ? DEFAULT_VOLTAGE_METER_CONFIG.type)
    scale: clampU8(config.scale ? DEFAULT_VOLTAGE_METER_CONFIG.scale)
    dividerValue: clampU8(
      config.dividerValue ? DEFAULT_VOLTAGE_METER_CONFIG.dividerValue
    )
    dividerMultiplier: clampU8(
      config.dividerMultiplier ? DEFAULT_VOLTAGE_METER_CONFIG.dividerMultiplier
    )
  }

sanitizeCurrentMeterConfig = (config = {}) ->
  {
    id: clampU8(config.id ? DEFAULT_CURRENT_METER_CONFIG.id)
    type: clampU8(config.type ? DEFAULT_CURRENT_METER_CONFIG.type)
    scale: clampU16(config.scale ? DEFAULT_CURRENT_METER_CONFIG.scale)
    offset: clampU16(config.offset ? DEFAULT_CURRENT_METER_CONFIG.offset)
  }

export {
  VOLTAGE_METER_SOURCES, CURRENT_METER_SOURCES
  VOLTAGE_METER_ID_BATTERY_1, CURRENT_METER_ID_BATTERY_1
  VOLTAGE_SENSOR_TYPE_ADC_RESISTOR_DIVIDER, CURRENT_SENSOR_ADC
  DEFAULT_BATTERY_CONFIG
  DEFAULT_VOLTAGE_METER_CONFIG, DEFAULT_CURRENT_METER_CONFIG
  sanitizeBatteryConfig, sanitizeVoltageMeterConfig
  sanitizeCurrentMeterConfig
}
