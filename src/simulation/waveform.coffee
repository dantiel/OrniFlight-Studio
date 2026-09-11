###
# ORNIFLIGHT STUDIO — Waveform Kernel
#
# Faithful port of PteronautOS FlappingOscillator::shapeWave +
# the centre-skew / slew helpers from OrnithopterConfig.h. One
# pure module: no React, no DOM, no instance state.
#
# The wave is the soul of the stroke. Two halves — descida
# (downstroke, the power stroke) and subida (upstroke, the
# recovery) — each with its own ferocity (dwell), its own centre
# skew, and a continuous transmutation from the dwell/plateau
# family (square) to the rounded pyramidal family (triangle).
#
#   shapeMixPercent 0 → plateau (square/dwell)
#   shapeMixPercent 100 → pointed (rounded triangle)
#   strokeSkew +100 → thrust front-loaded, −100 → late thrust
#   (quadratic bias t' = t + s·t·(1−t), endpoint-pinned)
###

TWO_PI = 2 * Math.PI
PI = Math.PI

clamp = (lo, hi, x) -> Math.max lo, Math.min hi, x
clamp01 = (x) -> clamp 0, 1, x

# 0–100 ferocity slider → 0–8 ferocity units (GralhaAzul range).
export ferocityUnits = (percent) ->
  clamp 0, 8, (clamp 0, 100, percent) * 0.08

# ── The core wave ───────────────────────────────────────────
# Returns a pulse in [-1, +1]. Faithful to the C++: dwell plateau
# (cosine ramp between the half-dwell extremes) transmuted toward
# the pyramidal family via shapeMix, then centre-skewed per half.
export shapeWave = (
  theta
  strokeFerocity
  returnFerocity
  limiarShared = -1
  shapeMixPercent = 0
  strokeSkewPercent = 0
  returnSkewPercent = 0
) ->
  kMaxDwell = 0.98
  kMaxPoint = 0.98

  theta = theta % TWO_PI
  theta += TWO_PI if theta < 0

  fD = clamp 0, 8, strokeFerocity
  fS = clamp 0, 8, returnFerocity
  shapeMix = clamp01 shapeMixPercent * 0.01

  limiar = if limiarShared >= 0
    limiarShared
  else
    wD = Math.max 0.01, 8 - fD
    wS = Math.max 0.01, 8 - fS
    TWO_PI * wD / (wD + wS)

  descida = theta < limiar
  if descida
    t = theta / limiar
    f = fD
  else
    t = (theta - limiar) / (TWO_PI - limiar)
    f = fS

  skew01 = clamp -1, 1,
    (if descida then strokeSkewPercent else returnSkewPercent) * 0.01
  if skew01 isnt 0
    t = t + skew01 * t * (1 - t)

  ferocity01 = f * 0.125
  d = ferocity01 * kMaxDwell
  dh = d * 0.5

  plateau =
    if t < dh then 1
    else if t > 1 - dh then -1
    else Math.cos PI * (t - dh) / (1 - d)

  pointK = kMaxPoint * (2 * ferocity01 - ferocity01 * ferocity01)
  pointed =
    if pointK < 0.0001 then Math.cos PI * t
    else Math.asin(pointK * Math.cos PI * t) / Math.asin pointK

  halfWave = plateau + (pointed - plateau) * shapeMix
  if descida then halfWave else -halfWave

# ── ONDAS live modulation ──────────────────────────────────
# The PID/ONDAS soul breathes into the wave. The scaled gains
# (0..1) + rate errors (rad/s) reshape the base stroke live, so
# the widget and the physics share one breath: P hardens the
# downstroke with pitch demand, D softens the return, cadence
# rounds the dwell toward a point, balance answers roll.
export modulateWaveform = (base = {}, gains = {}, rateError = {}) ->
  p = gains.ferocity_p_gain ? 0
  d = gains.ferocity_d_gain ? 0
  cadence = gains.cadence_gain ? 0
  balance = gains.balance_gain ? 0

  demand = rateError.pitch ? 0
  roll = rateError.roll ? 0

  strokeFer = clamp 0, 100,
    (base.strokeFerocity ? 50) + demand * p * 1.2
  returnFer = clamp 0, 100,
    (base.returnFerocity ? 50) - demand * d * 0.8
  shapeMix = clamp 0, 100,
    (base.ferocityShapeMix ? 0) +
      Math.abs(demand) * cadence * 0.6 +
      Math.abs(roll) * balance * 0.4

  strokeFerocity: strokeFer
  returnFerocity: returnFer
  ferocityShapeMix: shapeMix

# ── Skew coupling (asymmetric steering) ─────────────────────
# Throttle steers the thrust vector between the two half-strokes.
# Returns a signed shift (±100) to ADD to strokeSkew and SUBTRACT
# from returnSkew. 0 at mid-throttle, ±coupling at the extremes.
export throttleSkewShift = (throttle01, couplingPercent) ->
  mix = clamp01 couplingPercent * 0.01
  t = clamp01 throttle01
  signedThrottle = 2 * t - 1
  signedThrottle * mix * 100

# Aileron → differential skew (roll steering). ±100 to ADD to the
# LEFT wing and SUBTRACT from the RIGHT.
export aileronSkewShift = (aileronNorm, couplingPercent) ->
  mix = clamp01 couplingPercent * 0.01
  a = clamp -1, 1, aileronNorm
  a * mix * 100

# ── Slew (rate transients) ──────────────────────────────────
# A full stick slam (≈5/s) at 100% mix yields ±50 skew units;
# the caller's LPF τ decays the kick once the stick rests.
SKEW_RATE_GAIN = 10

skewRateShift = (ratePerSec, rateMixPercent) ->
  mix = clamp01 rateMixPercent * 0.01
  clamp -100, 100, ratePerSec * SKEW_RATE_GAIN * mix

export throttleSkewRateShift = skewRateShift
export aileronSkewRateShift = skewRateShift

# ── Catalog (limits + hermetic labels) ──────────────────────
export WAVEFORM_DEFAULTS =
  strokeFerocity: 50
  returnFerocity: 50
  ferocityShapeMix: 0
  strokeSkew: 0
  returnSkew: 0
  throttleSkewMix: 0
  aileronSkewMix: 0
  throttleSkewRateMix: 0
  aileronSkewRateMix: 0

export WAVEFORM_LIMITS =
  strokeFerocity:      { min: 0,   max: 100 }
  returnFerocity:      { min: 0,   max: 100 }
  ferocityShapeMix:    { min: 0,   max: 100 }
  strokeSkew:          { min: -100, max: 100 }
  returnSkew:          { min: -100, max: 100 }
  throttleSkewMix:     { min: 0,   max: 100 }
  aileronSkewMix:      { min: 0,   max: 100 }
  throttleSkewRateMix: { min: 0,   max: 100 }
  aileronSkewRateMix:  { min: 0,   max: 100 }

# Hermetic: each field is a facet of the stroke, not a setting.
export WAVEFORM_FIELDS = [
  {
    id: 'strokeFerocity', label: 'Schlag-Härte'
    hermes: 'Wie kantig der Abwärtsschlag — Dwell gegen Sinus.'
  }
  {
    id: 'returnFerocity', label: 'Rückzug-Härte'
    hermes: 'Wie kantig der Aufwärtsschlag — die Erholung.'
  }
  {
    id: 'ferocityShapeMix', label: 'Form-Mix'
    hermes: 'Platte (Quadrat) wird Spitze (Pyramide).'
  }
  {
    id: 'strokeSkew', label: 'Schlag-Skew'
    hermes: 'Schwerpunkt vorziehen (+) oder verzögern (−).'
  }
  {
    id: 'returnSkew', label: 'Rückzug-Skew'
    hermes: 'Dasselbe für den Aufwärtsschlag.'
  }
  {
    id: 'throttleSkewMix', label: 'Gas→Skew'
    hermes: 'Gas verlagert den Schwerpunkt asymmetrisch.'
  }
  {
    id: 'aileronSkewMix', label: 'Quer→Skew'
    hermes: 'Roll verlagert links/rechts gegenläufig.'
  }
  {
    id: 'throttleSkewRateMix', label: 'Gas-Slew'
    hermes: 'Gaswechsel kickt kurz den Schwerpunkt.'
  }
  {
    id: 'aileronSkewRateMix', label: 'Quer-Slew'
    hermes: 'Rollwechsel kickt kurz gegenläufig.'
  }
]

# ── Preview sampling ────────────────────────────────────────
# Samples the wave across [0, 2π) for the SVG widget. Returns
# {x: 0..1, y: -1..1, half: 'stroke'|'return'} points plus the
# shared reversal boundary (limiar fraction) for the divider.
export sampleWave = (params = {}, n = 128) ->
  strokeFer = ferocityUnits params.strokeFerocity ? 50
  returnFer = ferocityUnits params.returnFerocity ? 50
  shapeMix = params.ferocityShapeMix ? 0
  strokeSkew = params.strokeSkew ? 0
  returnSkew = params.returnSkew ? 0

  wD = Math.max 0.01, 8 - strokeFer
  wS = Math.max 0.01, 8 - returnFer
  limiar = TWO_PI * wD / (wD + wS)

  points = for i in [0...n]
    theta = (i / (n - 1)) * TWO_PI
    y = shapeWave theta, strokeFer, returnFer,
      limiar, shapeMix, strokeSkew, returnSkew
    {
      x: i / (n - 1)
      y: y
      half: if theta < limiar then 'stroke' else 'return'
    }

  { points, limiarFraction: limiar / TWO_PI }