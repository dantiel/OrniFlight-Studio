###
# ORNIFLIGHT STUDIO — StrokeScope geometry
#
# Pure projection of a waveform history window into scope bands.
# No DOM, no canvas — returns plain [x, y] point arrays (both 0..1)
# so the canvas renderer and the tests share one truth.
#
# A band is a horizontal strip of the scope. Each channel is traced
# across the rolling time window; y maps a FIXED physical range into
# [0,1] so real reactions stay readable — auto-normalising each band to
# its own envelope hides exactly the amplitude/gyro/cadence changes the
# scope exists to reveal.
###

clamp01 = (x) -> Math.max 0, Math.min 1, x

# Trace one channel across the window. Returns [[x, y], ...] with
# x in [0,1] (time) and y in [0,1] (top → bottom of the band).
traceChannel = (history, field, lo, hi) ->
  n = history.length
  return [] unless n > 1
  span = hi - lo
  return [] unless span > 0
  for i in [0...n]
    v = Number(history[i]?[field]) or 0
    y = 1 - clamp01((v - lo) / span)
    x = i / (n - 1)
    [x, y]

# Auto-scaled range from the window with a floor so a silent channel
# (all zeros) doesn't explode to full scale or collapse to NaN.
autoRange = (history, field, floor = 1) ->
  lo = Infinity
  hi = -Infinity
  for s in history
    v = Number(s?[field]) or 0
    lo = Math.min lo, v if v < lo
    hi = Math.max hi, v if v > hi
  lo = 0 unless isFinite lo
  hi = 0 unless isFinite hi
  mid = (lo + hi) / 2
  half = Math.max floor, (hi - lo) / 2
  { lo: mid - half, hi: mid + half }

# Fixed physical scales. The scope must NOT auto-normalise: every band
# filling its own envelope hides amplitude/gyro/cadence changes, because
# a reaction IS a change in envelope. Each band pins to an absolute
# engineering range (wing °, servo µs, gyro °/s, cadence Hz) so real
# reactions — pitch centre shift, roll differential, throttle cadence,
# gyro response — are readable at a glance. Faithful to the firmware's
# own units (OrnithopterConfig.h).
WING_DEG   = 90     # ±90° physical wing angle
SERVO_LO   = 1000   # µs (matches angleToPwm floor)
SERVO_HI   = 2000   # µs (matches angleToPwm ceiling)
GYRO_DEGS  = 720    # ±720°/s — full-stick rate target
CADENCE_HI = 20     # Hz (matches MAX_FLAP_HZ)

buildScopeBands = (history = [], amplitude = 45) ->
  wingL:     traceChannel history, 'wingL',     -WING_DEG,   WING_DEG
  wingR:     traceChannel history, 'wingR',     -WING_DEG,   WING_DEG
  servo1:    traceChannel history, 'servo1',    SERVO_LO,    SERVO_HI
  servo2:    traceChannel history, 'servo2',    SERVO_LO,    SERVO_HI
  servo3:    traceChannel history, 'servo3',    SERVO_LO,    SERVO_HI
  servo4:    traceChannel history, 'servo4',    SERVO_LO,    SERVO_HI
  gyroRoll:  traceChannel history, 'gyroRoll',  -GYRO_DEGS,  GYRO_DEGS
  gyroPitch: traceChannel history, 'gyroPitch', -GYRO_DEGS,  GYRO_DEGS
  gyroYaw:   traceChannel history, 'gyroYaw',   -GYRO_DEGS,  GYRO_DEGS
  cadence:   traceChannel history, 'cadence',   0,           CADENCE_HI
  ferStroke: traceChannel history, 'ferStroke', 0, 100
  ferReturn: traceChannel history, 'ferReturn', 0, 100
  ferShape:  traceChannel history, 'ferShape',  0, 100
  wingRange: { lo: -WING_DEG, hi: WING_DEG }

export { clamp01, traceChannel, autoRange, buildScopeBands }