###
# ORNIFLIGHT STUDIO — Sensors Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware sensor wire formats exactly. Ground truth:
#
#   OrniFlight/src/main/sensors/acceleration.h — accelerationSensor_e
#   OrniFlight/src/main/sensors/barometer.h — baroSensor_e
#   OrniFlight/src/main/sensors/compass.h — magSensor_e
#   OrniFlight/src/main/drivers/sensor.h — sensor_align_e
#   OrniFlight/src/main/msp/msp.c — MSP_SENSOR_CONFIG (3-byte record),
#     MSP_SENSOR_ALIGNMENT (7-byte read / 6-byte write)
#
# Both documents are independent flat wire records — the firmware
# performs no arbitration between them, so neither does this catalog.
###

clampInt = (lo, hi, value) ->
  value = Math.round Number value
  value = lo unless Number.isFinite value
  Math.max lo, Math.min hi, value

clampU8 = (value) -> clampInt 0, 255, value

# accelerationSensor_e — order is the wire id.
ACC_HARDWARE = Object.freeze [
  Object.freeze { id: 0, name: 'ACC_DEFAULT', label: 'Default (auto-detect)' }
  Object.freeze { id: 1, name: 'ACC_NONE', label: 'None' }
  Object.freeze { id: 2, name: 'ACC_ADXL345', label: 'ADXL345' }
  Object.freeze { id: 3, name: 'ACC_MPU6050', label: 'MPU6050' }
  Object.freeze { id: 4, name: 'ACC_MMA8452', label: 'MMA8452' }
  Object.freeze { id: 5, name: 'ACC_BMA280', label: 'BMA280' }
  Object.freeze { id: 6, name: 'ACC_LSM303DLHC', label: 'LSM303DLHC' }
  Object.freeze { id: 7, name: 'ACC_MPU6000', label: 'MPU6000' }
  Object.freeze { id: 8, name: 'ACC_MPU6500', label: 'MPU6500' }
  Object.freeze { id: 9, name: 'ACC_MPU9250', label: 'MPU9250' }
  Object.freeze { id: 10, name: 'ACC_ICM20601', label: 'ICM20601' }
  Object.freeze { id: 11, name: 'ACC_ICM20602', label: 'ICM20602' }
  Object.freeze { id: 12, name: 'ACC_ICM20608G', label: 'ICM20608G' }
  Object.freeze { id: 13, name: 'ACC_ICM20649', label: 'ICM20649' }
  Object.freeze { id: 14, name: 'ACC_ICM20689', label: 'ICM20689' }
  Object.freeze { id: 15, name: 'ACC_BMI160', label: 'BMI160' }
  Object.freeze { id: 16, name: 'ACC_FAKE', label: 'Fake (test rig)' }
]

# baroSensor_e — order is the wire id.
BARO_HARDWARE = Object.freeze [
  Object.freeze { id: 0, name: 'BARO_DEFAULT', label: 'Default (auto-detect)' }
  Object.freeze { id: 1, name: 'BARO_NONE', label: 'None' }
  Object.freeze { id: 2, name: 'BARO_BMP085', label: 'BMP085' }
  Object.freeze { id: 3, name: 'BARO_MS5611', label: 'MS5611' }
  Object.freeze { id: 4, name: 'BARO_BMP280', label: 'BMP280' }
  Object.freeze { id: 5, name: 'BARO_LPS', label: 'LPS' }
  Object.freeze { id: 6, name: 'BARO_QMP6988', label: 'QMP6988' }
]

# magSensor_e — order is the wire id.
MAG_HARDWARE = Object.freeze [
  Object.freeze { id: 0, name: 'MAG_DEFAULT', label: 'Default (auto-detect)' }
  Object.freeze { id: 1, name: 'MAG_NONE', label: 'None' }
  Object.freeze { id: 2, name: 'MAG_HMC5883', label: 'HMC5883' }
  Object.freeze { id: 3, name: 'MAG_AK8975', label: 'AK8975' }
  Object.freeze { id: 4, name: 'MAG_AK8963', label: 'AK8963' }
  Object.freeze { id: 5, name: 'MAG_QMC5883', label: 'QMC5883' }
  Object.freeze { id: 6, name: 'MAG_LIS3MDL', label: 'LIS3MDL' }
]

# sensor_align_e — order is the wire id. Gyro and acc share one
# alignment since firmware 4.0; mag keeps its own.
SENSOR_ALIGNMENTS = Object.freeze [
  Object.freeze { id: 0, name: 'ALIGN_DEFAULT', label: 'Default (driver-provided)' }
  Object.freeze { id: 1, name: 'CW0_DEG', label: 'CW 0°' }
  Object.freeze { id: 2, name: 'CW90_DEG', label: 'CW 90°' }
  Object.freeze { id: 3, name: 'CW180_DEG', label: 'CW 180°' }
  Object.freeze { id: 4, name: 'CW270_DEG', label: 'CW 270°' }
  Object.freeze { id: 5, name: 'CW0_DEG_FLIP', label: 'CW 0° Flip' }
  Object.freeze { id: 6, name: 'CW90_DEG_FLIP', label: 'CW 90° Flip' }
  Object.freeze { id: 7, name: 'CW180_DEG_FLIP', label: 'CW 180° Flip' }
  Object.freeze { id: 8, name: 'CW270_DEG_FLIP', label: 'CW 270° Flip' }
]

# MSP 96 record — firmware defaults (0 = auto-detect everywhere).
DEFAULT_SENSOR_CONFIG = Object.freeze
  accHardware: 0
  baroHardware: 0
  magHardware: 0

# MSP 126 record — firmware defaults (all ALIGN_DEFAULT).
DEFAULT_SENSOR_ALIGNMENT = Object.freeze
  gyroAlign: 0
  accAlign: 0
  magAlign: 0
  gyroDetectionFlags: 0
  gyroToUse: 0
  gyro1Align: 0
  gyro2Align: 0

sanitizeSensorConfig = (config = {}) ->
  {
    accHardware: clampU8(config.accHardware ? DEFAULT_SENSOR_CONFIG.accHardware)
    baroHardware: clampU8(config.baroHardware ? DEFAULT_SENSOR_CONFIG.baroHardware)
    magHardware: clampU8(config.magHardware ? DEFAULT_SENSOR_CONFIG.magHardware)
  }

sanitizeSensorAlignment = (alignment = {}) ->
  {
    gyroAlign: clampU8(alignment.gyroAlign ? DEFAULT_SENSOR_ALIGNMENT.gyroAlign)
    accAlign: clampU8(alignment.accAlign ? DEFAULT_SENSOR_ALIGNMENT.accAlign)
    magAlign: clampU8(alignment.magAlign ? DEFAULT_SENSOR_ALIGNMENT.magAlign)
    gyroDetectionFlags: clampU8(
      alignment.gyroDetectionFlags ? DEFAULT_SENSOR_ALIGNMENT.gyroDetectionFlags
    )
    gyroToUse: clampU8(alignment.gyroToUse ? DEFAULT_SENSOR_ALIGNMENT.gyroToUse)
    gyro1Align: clampU8(alignment.gyro1Align ? DEFAULT_SENSOR_ALIGNMENT.gyro1Align)
    gyro2Align: clampU8(alignment.gyro2Align ? DEFAULT_SENSOR_ALIGNMENT.gyro2Align)
  }

export {
  ACC_HARDWARE, BARO_HARDWARE, MAG_HARDWARE, SENSOR_ALIGNMENTS
  DEFAULT_SENSOR_CONFIG, DEFAULT_SENSOR_ALIGNMENT
  sanitizeSensorConfig, sanitizeSensorAlignment
}
