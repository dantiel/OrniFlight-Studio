###
# ORNIFLIGHT STUDIO — Adjustments Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware in-flight-adjustment wire format exactly. Ground truth:
#
#   OrniFlight/src/main/fc/rc_adjustments.h — adjustmentRange_t,
#     MAX_ADJUSTMENT_RANGE_COUNT 30, MAX_SIMULTANEOUS_ADJUSTMENT_COUNT 4
#   OrniFlight/src/main/fc/rc_adjustments.c — defaultAdjustmentConfigs
#     (the wire byte is the table index + 1; 0 = none)
#   OrniFlight/src/main/fc/rc_modes.c — isRangeActive:
#     channel value in [900 + startStep × 25, 900 + endStep × 25),
#     aux channels are NON_AUX_CHANNEL_COUNT-relative (AUX1 = 0)
#   OrniFlight/src/main/msp/msp.c — MSP_ADJUSTMENT_RANGES (30 × 6-byte
#     slots), MSP_SET_ADJUSTMENT_RANGE (7-byte record)
###

clampInt = (lo, hi, value) ->
  value = Math.round Number value
  value = lo unless Number.isFinite value
  Math.max lo, Math.min hi, value

MAX_ADJUSTMENT_RANGE_COUNT = 30
MAX_SIMULTANEOUS_ADJUSTMENT_COUNT = 4
AUX_CHANNEL_COUNT = 14
ADJUSTMENT_CHANNEL_MIN_USEC = 900
ADJUSTMENT_CHANNEL_STEP_USEC = 25
ADJUSTMENT_CHANNEL_STEP_MAX = 48

# The wire stores adjustmentConfig as the 1-based index into the
# firmware defaultAdjustmentConfigs table; 0 disables the slot.
ADJUSTMENT_FUNCTIONS = Object.freeze [
  Object.freeze { id: 0, name: 'None', label: '— None —' }
  Object.freeze { id: 1, name: 'RC Rate', label: 'RC Rate' }
  Object.freeze { id: 2, name: 'RC Expo', label: 'RC Expo' }
  Object.freeze { id: 3, name: 'Throttle Expo', label: 'Throttle Expo' }
  Object.freeze { id: 4, name: 'Pitch/Roll Rate', label: 'Pitch/Roll Rate' }
  Object.freeze { id: 5, name: 'Yaw Rate', label: 'Yaw Rate' }
  Object.freeze { id: 6, name: 'Pitch/Roll P', label: 'Pitch/Roll P' }
  Object.freeze { id: 7, name: 'Pitch/Roll I', label: 'Pitch/Roll I' }
  Object.freeze { id: 8, name: 'Pitch/Roll D', label: 'Pitch/Roll D' }
  Object.freeze { id: 9, name: 'Yaw P', label: 'Yaw P' }
  Object.freeze { id: 10, name: 'Yaw I', label: 'Yaw I' }
  Object.freeze { id: 11, name: 'Yaw D', label: 'Yaw D' }
  Object.freeze { id: 12, name: 'Rate Profile Selection', label: 'Rate Profile' }
  Object.freeze { id: 13, name: 'Pitch Rate', label: 'Pitch Rate' }
  Object.freeze { id: 14, name: 'Roll Rate', label: 'Roll Rate' }
  Object.freeze { id: 15, name: 'Pitch P', label: 'Pitch P' }
  Object.freeze { id: 16, name: 'Pitch I', label: 'Pitch I' }
  Object.freeze { id: 17, name: 'Pitch D', label: 'Pitch D' }
  Object.freeze { id: 18, name: 'Roll P', label: 'Roll P' }
  Object.freeze { id: 19, name: 'Roll I', label: 'Roll I' }
  Object.freeze { id: 20, name: 'Roll D', label: 'Roll D' }
  Object.freeze { id: 21, name: 'RC Rate Yaw', label: 'RC Rate Yaw' }
  Object.freeze { id: 22, name: 'Pitch/Roll F', label: 'Pitch/Roll F' }
  Object.freeze { id: 23, name: 'Feedforward Transition', label: 'Feedforward Transition' }
  Object.freeze { id: 24, name: 'Horizon Strength', label: 'Horizon Strength' }
  Object.freeze { id: 25, name: 'PID Audio', label: 'PID Audio' }
  Object.freeze { id: 26, name: 'Pitch F', label: 'Pitch F' }
  Object.freeze { id: 27, name: 'Roll F', label: 'Roll F' }
  Object.freeze { id: 28, name: 'Yaw F', label: 'Yaw F' }
  Object.freeze { id: 29, name: 'OSD Profile Selection', label: 'OSD Profile' }
  Object.freeze { id: 30, name: 'LED Profile Selection', label: 'LED Profile' }
]
ADJUSTMENT_FUNCTION_MAX = ADJUSTMENT_FUNCTIONS.length - 1

ADJUSTMENT_SLOTS = Object.freeze [
  Object.freeze { id: 0, name: 'Slot 1' }
  Object.freeze { id: 1, name: 'Slot 2' }
  Object.freeze { id: 2, name: 'Slot 3' }
  Object.freeze { id: 3, name: 'Slot 4' }
]

# All-zero slot — the firmware treats it as unused.
DEFAULT_ADJUSTMENT_RANGE = Object.freeze
  adjustmentIndex: 0
  auxChannelIndex: 0
  startStep: 0
  endStep: 0
  adjustmentConfig: 0
  auxSwitchChannelIndex: 0

adjustmentStepToUsec = (step) ->
  ADJUSTMENT_CHANNEL_MIN_USEC + clampInt(0, ADJUSTMENT_CHANNEL_STEP_MAX, step) *
    ADJUSTMENT_CHANNEL_STEP_USEC

adjustmentUsecToStep = (usec) ->
  clampInt 0, ADJUSTMENT_CHANNEL_STEP_MAX,
    (usec - ADJUSTMENT_CHANNEL_MIN_USEC) / ADJUSTMENT_CHANNEL_STEP_USEC

sanitizeAdjustmentRange = (range = {}) ->
  {
    adjustmentIndex: clampInt(
      0, MAX_SIMULTANEOUS_ADJUSTMENT_COUNT - 1,
      range.adjustmentIndex ? DEFAULT_ADJUSTMENT_RANGE.adjustmentIndex
    )
    auxChannelIndex: clampInt(
      0, AUX_CHANNEL_COUNT - 1,
      range.auxChannelIndex ? DEFAULT_ADJUSTMENT_RANGE.auxChannelIndex
    )
    startStep: clampInt(
      0, ADJUSTMENT_CHANNEL_STEP_MAX,
      range.startStep ? DEFAULT_ADJUSTMENT_RANGE.startStep
    )
    endStep: clampInt(
      0, ADJUSTMENT_CHANNEL_STEP_MAX,
      range.endStep ? DEFAULT_ADJUSTMENT_RANGE.endStep
    )
    adjustmentConfig: clampInt(
      0, ADJUSTMENT_FUNCTION_MAX,
      range.adjustmentConfig ? DEFAULT_ADJUSTMENT_RANGE.adjustmentConfig
    )
    auxSwitchChannelIndex: clampInt(
      0, AUX_CHANNEL_COUNT - 1,
      range.auxSwitchChannelIndex ?
        DEFAULT_ADJUSTMENT_RANGE.auxSwitchChannelIndex
    )
  }

export {
  MAX_ADJUSTMENT_RANGE_COUNT, MAX_SIMULTANEOUS_ADJUSTMENT_COUNT
  AUX_CHANNEL_COUNT
  ADJUSTMENT_CHANNEL_MIN_USEC, ADJUSTMENT_CHANNEL_STEP_USEC
  ADJUSTMENT_CHANNEL_STEP_MAX
  ADJUSTMENT_FUNCTIONS, ADJUSTMENT_FUNCTION_MAX, ADJUSTMENT_SLOTS
  DEFAULT_ADJUSTMENT_RANGE
  adjustmentStepToUsec, adjustmentUsecToStep, sanitizeAdjustmentRange
}
