# MSP commands used by the runtime compatibility layer. Keep this module small:
# domains add commands when they gain a typed codec rather than importing the
# legacy configurator's entire mutable command surface.
MSP_CODES =
  API_VERSION: 1
  FC_VARIANT: 2
  FC_VERSION: 3
  BOARD_INFO: 4
  BUILD_INFO: 5
  NAME: 10
  SET_NAME: 11
  RX_MAP: 64
  STATUS: 101
  RAW_IMU: 102
  SERVO: 103
  RC: 105
  ATTITUDE: 108
  ANALOG: 110
  SERVO_CONFIGURATIONS: 120
  BATTERY_STATE: 130
  STATUS_EX: 150
  UID: 160
  SET_SERVO_CONFIGURATION: 212
  EEPROM_WRITE: 250

export default MSP_CODES
export { MSP_CODES }
