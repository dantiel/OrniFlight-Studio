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
  FILTER_CONFIG: 92
  PID_ADVANCED: 94
  RC_TUNING: 111
  PID: 112
  ONDAS: 114
  SET_PID_ADVANCED: 95
  SET_FILTER_CONFIG: 193
  SET_PID: 202
  SET_RC_TUNING: 204
  SET_ONDAS: 206
  SET_SERVO_CONFIGURATION: 212
  SERVO_MIX_RULES: 241
  SET_SERVO_MIX_RULE: 242
  ORNITHOPTER_GLIDE_DEGREE: 244
  OSD_CONFIG: 84
  SET_OSD_CONFIG: 85
  EEPROM_WRITE: 250

export default MSP_CODES
export { MSP_CODES }