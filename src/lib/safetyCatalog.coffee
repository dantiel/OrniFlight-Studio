###
# ORNIFLIGHT STUDIO — Safety Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware safety wire formats exactly. Ground truth:
#
#   OrniFlight/src/main/flight/failsafe.h/.c — failsafeConfig_t,
#     pgResetTemplate: throttle 1000, throttleLowDelay 100,
#     delay 4, offDelay 10, switchMode 0, procedure 1 (DROP);
#     failsafeProcedureNames: AUTO-LAND=0, DROP=1, GPS-RESCUE=2
#   OrniFlight/src/main/fc/rc_controls.c — armingConfig_t:
#     auto_disarm_delay 5, gyro_cal_on_first_arm 0
#   OrniFlight/src/main/flight/imu.c — imuConfig.small_angle 25
#   OrniFlight/src/main/config/feature.h — features_e bit table,
#     DEFAULT_FEATURES 0, DEFAULT_RX_FEATURE RX_PARALLEL_PWM
#   OrniFlight/src/main/io/beeper.h + pg/beeper.c — beeperMode_e,
#     BEEPER_GET_FLAG(mode) = 1 << (mode - 1), dshotBeaconTone 1,
#     DSHOT_BEACON_ALLOWED_MODES = RX_LOST | RX_SET
#
# All four documents are independent flat wire records — the firmware
# performs no arbitration between them, so neither does this catalog.
###

# ── Failsafe (MSP 75/76, 8-byte wire record) ──────────────────
FAILSAFE_THROTTLE_MIN = 1000
FAILSAFE_THROTTLE_MAX = 2000
FAILSAFE_DEFAULT_THROTTLE_LOW_DELAY_MS = 100

# failsafeProcedureNames — order is the wire id.
FAILSAFE_PROCEDURES = Object.freeze [
  Object.freeze { id: 0, name: 'AUTO-LAND' }
  Object.freeze { id: 1, name: 'DROP' }
  Object.freeze { id: 2, name: 'GPS-RESCUE' }
]
FAILSAFE_PROCEDURE_COUNT = FAILSAFE_PROCEDURES.length

# failsafe_switch_mode: 0 stage1 (= link loss), 1 kill (instant
# disarm), 2 stage2 — firmware comment in failsafe.h.
FAILSAFE_SWITCH_MODES = Object.freeze [
  Object.freeze { id: 0, name: 'STAGE 1', note: 'identical to link loss' }
  Object.freeze { id: 1, name: 'KILL', note: 'disarms instantly' }
  Object.freeze { id: 2, name: 'STAGE 2', note: 'full procedure' }
]
FAILSAFE_SWITCH_MODE_COUNT = FAILSAFE_SWITCH_MODES.length

# pgResetTemplate(failsafeConfig) — the firmware defaults.
DEFAULT_FAILSAFE_CONFIG = Object.freeze
  delay: 4
  offDelay: 10
  throttle: 1000
  switchMode: 0
  throttleLowDelay: FAILSAFE_DEFAULT_THROTTLE_LOW_DELAY_MS
  procedure: 1

# ── Arming (MSP 61/62, 3-byte wire record) ────────────────────
# gyro_cal_on_first_arm is presentational: it rides the firmware
# default (0) and is not part of the wire document.
ARMING_SMALL_ANGLE_MAX = 180
GYRO_CAL_ON_FIRST_ARM_DEFAULT = 0

DEFAULT_ARMING_CONFIG = Object.freeze
  autoDisarmDelay: 5
  smallAngle: 25

# ── Features (MSP 36/37, absolute u32 mask) ───────────────────
# features_e (config/feature.h) — bit = 1 << wireBit. The mask rides
# the wire absolute; SET_FEATURE_CONFIG only stages the value and
# EEPROM_WRITE materializes it (writeEEPROMWithFeatures).
FEATURE_BITS = Object.freeze [
  Object.freeze { bit: 0, name: 'RX_PPM', group: 'receiver', label: 'PPM receiver' }
  Object.freeze { bit: 2, name: 'INFLIGHT_ACC_CAL', group: 'system', label: 'Inflight acc calibration' }
  Object.freeze { bit: 3, name: 'RX_SERIAL', group: 'receiver', label: 'Serial-based receiver' }
  Object.freeze { bit: 4, name: 'MOTOR_STOP', group: 'system', label: "Don't spin motors when armed" }
  Object.freeze { bit: 5, name: 'SERVO_TILT', group: 'system', label: 'Servo tilt' }
  Object.freeze { bit: 6, name: 'SOFTSERIAL', group: 'system', label: 'SoftSerial ports' }
  Object.freeze { bit: 7, name: 'GPS', group: 'system', label: 'GPS' }
  Object.freeze { bit: 9, name: 'RANGEFINDER', group: 'system', label: 'Rangefinder' }
  Object.freeze { bit: 10, name: 'TELEMETRY', group: 'system', label: 'Telemetry' }
  Object.freeze { bit: 12, name: '3D', group: 'system', label: '3D mode' }
  Object.freeze { bit: 13, name: 'RX_PARALLEL_PWM', group: 'receiver', label: 'Parallel PWM receiver' }
  Object.freeze { bit: 14, name: 'RX_MSP', group: 'receiver', label: 'MSP receiver' }
  Object.freeze { bit: 15, name: 'RSSI_ADC', group: 'system', label: 'RSSI via ADC' }
  Object.freeze { bit: 16, name: 'LED_STRIP', group: 'system', label: 'LED strip' }
  Object.freeze { bit: 17, name: 'DASHBOARD', group: 'system', label: 'Dashboard' }
  Object.freeze { bit: 18, name: 'OSD', group: 'system', label: 'OSD' }
  Object.freeze { bit: 20, name: 'CHANNEL_FORWARDING', group: 'system', label: 'Channel forwarding' }
  Object.freeze { bit: 21, name: 'TRANSPONDER', group: 'system', label: 'Transponder' }
  Object.freeze { bit: 22, name: 'AIRMODE', group: 'system', label: 'Airmode' }
  Object.freeze { bit: 25, name: 'RX_SPI', group: 'receiver', label: 'SPI receiver' }
  Object.freeze { bit: 26, name: 'SOFTSPI', group: 'system', label: 'SoftSPI' }
  Object.freeze { bit: 27, name: 'ESC_SENSOR', group: 'system', label: 'ESC sensor' }
  Object.freeze { bit: 28, name: 'ANTI_GRAVITY', group: 'system', label: 'Anti-gravity' }
  Object.freeze { bit: 29, name: 'DYNAMIC_FILTER', group: 'system', label: 'Dynamic filter' }
]

# Computed with a do-block — the compiler rejects multi-line
# parenthesised arrow arguments, and the helpers below are assigned
# later in module order anyway.
FEATURE_SUPPORTED_MASK = do ->
  mask = 0
  for feature in FEATURE_BITS
    mask |= 1 << feature.bit
  mask

# DEFAULT_FEATURES 0 | DEFAULT_RX_FEATURE RX_PARALLEL_PWM.
DEFAULT_FEATURE_MASK = 1 << 13

# ── Beeper (MSP 184/185, 9-byte wire record) ──────────────────
# beeperMode_e — order preserved for configurator compatibility;
# flag = BEEPER_GET_FLAG(mode) = 1 << (mode - 1).
BEEPER_MODES = Object.freeze [
  Object.freeze { id: 1, name: 'GYRO_CALIBRATED', label: 'Gyro calibrated' }
  Object.freeze { id: 2, name: 'RX_LOST', label: 'Receiver link lost' }
  Object.freeze { id: 3, name: 'RX_LOST_LANDING', label: 'Link loss landing SOS' }
  Object.freeze { id: 4, name: 'DISARMING', label: 'Disarming' }
  Object.freeze { id: 5, name: 'ARMING', label: 'Arming' }
  Object.freeze { id: 6, name: 'ARMING_GPS_FIX', label: 'Arming with GPS fix' }
  Object.freeze { id: 7, name: 'BAT_CRIT_LOW', label: 'Battery critical' }
  Object.freeze { id: 8, name: 'BAT_LOW', label: 'Battery low' }
  Object.freeze { id: 9, name: 'GPS_STATUS', label: 'GPS satellite count' }
  Object.freeze { id: 10, name: 'RX_SET', label: 'Aux channel beep' }
  Object.freeze { id: 11, name: 'ACC_CALIBRATION', label: 'Acc calibration done' }
  Object.freeze { id: 12, name: 'ACC_CALIBRATION_FAIL', label: 'Acc calibration failed' }
  Object.freeze { id: 13, name: 'READY_BEEP', label: 'GPS locked and ready' }
  Object.freeze { id: 14, name: 'MULTI_BEEPS', label: 'Multi beeps' }
  Object.freeze { id: 15, name: 'DISARM_REPEAT', label: 'Disarm stick held' }
  Object.freeze { id: 16, name: 'ARMED', label: 'Armed idle warning' }
  Object.freeze { id: 17, name: 'SYSTEM_INIT', label: 'System init' }
  Object.freeze { id: 18, name: 'USB', label: 'USB connected' }
  Object.freeze { id: 19, name: 'BLACKBOX_ERASE', label: 'Blackbox erase done' }
  Object.freeze { id: 20, name: 'CRASH_FLIP_MODE', label: 'Crash flip active' }
  Object.freeze { id: 21, name: 'CAM_CONNECTION_OPEN', label: 'Camera link open' }
  Object.freeze { id: 22, name: 'CAM_CONNECTION_CLOSE', label: 'Camera link closed' }
  Object.freeze { id: 23, name: 'RC_SMOOTHING_INIT_FAIL', label: 'RC smoothing init failed' }
  Object.freeze { id: 24, name: 'ARMING_GPS_NO_FIX', label: 'Arming without GPS fix' }
]

# BEEPER_ALL stays at the bottom of the enum — id 25, flag bit 24.
BEEPER_ALL = Object.freeze { id: 25, name: 'ALL', label: 'Silence all conditions' }
BEEPER_ALL_FLAG = 1 << 24
# offFlags bits 0..23 = modes 1..24, bit 24 = the ALL sentinel.
BEEPER_OFF_FLAGS_MASK = (BEEPER_ALL_FLAG << 1) - 1

# DSHOT_BEACON_ALLOWED_MODES = RX_LOST | RX_SET.
DSHOT_BEACON_ALLOWED_FLAGS = (1 << 1) | (1 << 9)

# pgResetTemplate(beeperConfig) — the firmware defaults.
DEFAULT_BEEPER_CONFIG = Object.freeze
  offFlags: 0
  dshotBeaconTone: 1
  dshotBeaconOffFlags: DSHOT_BEACON_ALLOWED_FLAGS

# ── Domain helpers ────────────────────────────────────────────
clampInt = (lo, hi, value) ->
  value = Math.round Number value
  value = lo unless Number.isFinite value
  Math.max lo, Math.min hi, value

clampU8 = (value) -> clampInt 0, 255, value
clampU16 = (value) -> clampInt 0, 65535, value

clampU32 = (value) ->
  value = Math.trunc Number value
  value = 0 unless Number.isFinite value
  value >>> 0

sanitizeFailsafe = (config = {}) ->
  {
    delay: clampU8 config.delay ? DEFAULT_FAILSAFE_CONFIG.delay
    offDelay: clampU8 config.offDelay ? DEFAULT_FAILSAFE_CONFIG.offDelay
    throttle: clampInt(
      FAILSAFE_THROTTLE_MIN, FAILSAFE_THROTTLE_MAX
      config.throttle ? DEFAULT_FAILSAFE_CONFIG.throttle
    )
    switchMode: clampInt(
      0, FAILSAFE_SWITCH_MODE_COUNT - 1
      config.switchMode ? DEFAULT_FAILSAFE_CONFIG.switchMode
    )
    throttleLowDelay: clampU16(
      config.throttleLowDelay ? DEFAULT_FAILSAFE_CONFIG.throttleLowDelay
    )
    procedure: clampInt(
      0, FAILSAFE_PROCEDURE_COUNT - 1
      config.procedure ? DEFAULT_FAILSAFE_CONFIG.procedure
    )
  }

sanitizeArming = (config = {}) ->
  {
    autoDisarmDelay: clampU8(
      config.autoDisarmDelay ? DEFAULT_ARMING_CONFIG.autoDisarmDelay
    )
    smallAngle: clampInt(
      0, ARMING_SMALL_ANGLE_MAX
      config.smallAngle ? DEFAULT_ARMING_CONFIG.smallAngle
    )
  }

sanitizeFeatures = (mask) ->
  clampU32(mask) & FEATURE_SUPPORTED_MASK

sanitizeBeeper = (config = {}) ->
  {
    offFlags: clampU32(config.offFlags ? 0) & BEEPER_OFF_FLAGS_MASK
    dshotBeaconTone: clampU8(
      config.dshotBeaconTone ? DEFAULT_BEEPER_CONFIG.dshotBeaconTone
    )
    dshotBeaconOffFlags: clampU32(
      config.dshotBeaconOffFlags ? DEFAULT_BEEPER_CONFIG.dshotBeaconOffFlags
    ) & DSHOT_BEACON_ALLOWED_FLAGS
  }

featureBit = (feature) -> 1 << feature.bit

featureIsSet = (mask, bit) -> Boolean(clampU32(mask) & bit)

featureSetBit = (mask, bit) -> clampU32(mask) | bit

featureClearBit = (mask, bit) -> clampU32(mask) & ~bit

beeperFlagFor = (mode) -> 1 << (mode - 1)

# True when the condition is muted — an off-mask flag silences it.
beeperModeSilenced = (offFlags, mode) ->
  Boolean(clampU32(offFlags) & beeperFlagFor mode)

# The two modes the DShot beacon honours (beeper.h).
DSHOT_BEACON_MODES = BEEPER_MODES.filter (mode) ->
  DSHOT_BEACON_ALLOWED_FLAGS & beeperFlagFor(mode.id)

export {
  FAILSAFE_THROTTLE_MIN, FAILSAFE_THROTTLE_MAX
  FAILSAFE_DEFAULT_THROTTLE_LOW_DELAY_MS
  FAILSAFE_PROCEDURES, FAILSAFE_PROCEDURE_COUNT
  FAILSAFE_SWITCH_MODES, FAILSAFE_SWITCH_MODE_COUNT
  DEFAULT_FAILSAFE_CONFIG
  ARMING_SMALL_ANGLE_MAX, GYRO_CAL_ON_FIRST_ARM_DEFAULT
  DEFAULT_ARMING_CONFIG
  FEATURE_BITS, FEATURE_SUPPORTED_MASK, DEFAULT_FEATURE_MASK
  BEEPER_MODES, BEEPER_ALL, BEEPER_ALL_FLAG, BEEPER_OFF_FLAGS_MASK
  DSHOT_BEACON_ALLOWED_FLAGS, DSHOT_BEACON_MODES
  DEFAULT_BEEPER_CONFIG
  sanitizeFailsafe, sanitizeArming, sanitizeFeatures, sanitizeBeeper
  featureBit, featureIsSet, featureSetBit, featureClearBit
  beeperFlagFor, beeperModeSilenced
}