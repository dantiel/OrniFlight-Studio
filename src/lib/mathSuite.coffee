###
# ORNIFLIGHT STUDIO — Math Suite Registry (ONDAS + ESPELHO)
#
# Single source of truth for the 15-parameter mathematics suite on
# ornithopterProfile_t (firmware settings.c). Nine coupled layers
# transform raw PID terms into the wing's phase-locked motion.
#
# Consumers:
#   - mspDecoders.coffee  → ONDAS_KEYS / ONDAS_DEFAULTS / signed codec
#   - useTuningStore       → per-key clamp ranges (signed-aware)
#   - OrnithopterModel     → setOndasParam clamp ranges
#   - MathView + PidTuning → labels, ranges, units, layer grouping
#
# Defaults mirror pgResetFn_ornithopterProfiles (firmware reset).
###
import { shapeWave, ferocityUnits } from '../simulation/waveform.coffee'

TWO_PI = 2 * Math.PI

# ── Layer order = wire order (one u8 per key, signed as value+128) ──
MATH_LAYERS = [
  { id: 'cadence', name: 'Cadence', glyph: '∿'
    role: 'P-term → phase advance (k₀ scaling)' }
  { id: 'ferocity', name: 'Ferocity', glyph: '🔥'
    role: 'PD blend → dwell & roll/yaw common-mode' }
  { id: 'balance', name: 'Balance', glyph: '⚖'
    role: 'I-term → up/down thrust bias' }
  { id: 'warp', name: 'Warp', glyph: '⟁'
    role: 'L/R ferocity differential' }
  { id: 'anchor', name: 'Anchor', glyph: '⚓'
    role: 'variable k₂ damping' }
  { id: 'resonance', name: 'Resonance', glyph: '〰'
    role: 'phase-locked error filter' }
  { id: 'prescience', name: 'Prescience', glyph: '🔮'
    role: 'stroke-ahead prediction via ω' }
  { id: 'espelho', name: 'Espelho', glyph: '🪞'
    role: 'wing-self-noise cancellation' }
  { id: 'saudade', name: 'Saudade', glyph: '🌘'
    role: 'per-stroke learning → trim bias' }
]

MATH_PARAMS =
  cadence_gain:
    layer: 'cadence', min: -100, max: 100, unit: '%', signed: true
    label: 'Phase advance'
    role: 'Scales the P-term into stroke phase lead.'
  ferocity_p_gain:
    layer: 'ferocity', min: 0, max: 100, unit: '%', signed: false
    label: 'Ferocity P'
    role: 'Pitch demand hardens the downstroke dwell.'
  ferocity_d_gain:
    layer: 'ferocity', min: -100, max: 100, unit: '%', signed: true
    label: 'Ferocity D'
    role: 'Rate damping softens the return stroke.'
  ferocity_roll_gain:
    layer: 'ferocity', min: 0, max: 100, unit: '%', signed: false
    label: 'Ferocity roll'
    role: 'Roll demand shifts the common-mode dwell.'
  ferocity_yaw_gain:
    layer: 'ferocity', min: 0, max: 100, unit: '%', signed: false
    label: 'Ferocity yaw'
    role: 'Yaw demand shifts the common-mode dwell.'
  ferocity_downstroke:
    layer: 'ferocity', min: 1, max: 100, unit: '%', signed: false
    label: 'Downstroke shape'
    role: 'Downstroke sharpness — 1 near-sine, 100 dwell.'
  ferocity_upstroke:
    layer: 'ferocity', min: 1, max: 100, unit: '%', signed: false
    label: 'Upstroke shape'
    role: 'Upstroke sharpness — 1 near-sine, 100 dwell.'
  balance_gain:
    layer: 'balance', min: -100, max: 100, unit: '%', signed: true
    label: 'Thrust bias'
    role: 'I-term → up/down thrust asymmetry.'
  warp_gain:
    layer: 'warp', min: -100, max: 100, unit: '%', signed: true
    label: 'Warp differential'
    role: 'Left/right ferocity split for roll authority.'
  warp_yaw_gain:
    layer: 'warp', min: -100, max: 100, unit: '%', signed: true
    label: 'Warp yaw'
    role: 'Left/right ferocity split for yaw authority.'
  anchor_gain:
    layer: 'anchor', min: 0, max: 100, unit: '%', signed: false
    label: 'Damping anchor'
    role: 'Variable k₂ damping against oscillation.'
  resonance_gain:
    layer: 'resonance', min: 0, max: 100, unit: '%', signed: false
    label: 'Resonance filter'
    role: 'Phase-locked error filter at flap frequency.'
  prescience_gain:
    layer: 'prescience', min: 0, max: 100, unit: '%', signed: false
    label: 'Stroke prediction'
    role: 'Stroke-ahead prediction from flap rate ω.'
  espelho_gain:
    layer: 'espelho', min: 0, max: 100, unit: '%', signed: false
    label: 'Noise cancellation'
    role: 'Wing-self-noise cancellation (lock-in bank).'
  saudade_gain:
    layer: 'saudade', min: 0, max: 100, unit: '%', signed: false
    label: 'Stroke memory'
    role: 'Per-stroke learning → persistent trim bias.'

MATH_KEYS = []
MATH_DEFAULTS = {}
for layer in MATH_LAYERS
  for key, meta of MATH_PARAMS
    if meta.layer is layer.id
      MATH_KEYS.push key
      # Firmware reset values (ornithopter_profile.c).
      MATH_DEFAULTS[key] =
        if key in ['ferocity_downstroke', 'ferocity_upstroke'] then 12
        else if key in ['resonance_gain', 'prescience_gain', 'espelho_gain',
                        'saudade_gain', 'cadence_gain'] then 0
        else 10

mathLayerOf = (key) -> MATH_PARAMS[key]?.layer
mathParamsOf = (layerId) ->
  MATH_KEYS.filter (key) -> MATH_PARAMS[key].layer is layerId

# ── Stroke preview path (down/up ferocity split) ────────────────
# Pure: returns an SVG path string sampling shapeWave over two full
# strokes. down/up are the 1..100 shape params — the split is visible
# as asymmetric dwell between the power and recovery halves.
strokePreviewPath = (down, up, width = 168, height = 56) ->
  ferD = ferocityUnits down
  ferU = ferocityUnits up
  steps = 96
  mid = height / 2
  amp = height / 2 - 3
  parts = []
  for i in [0..steps]
    theta = TWO_PI * i / steps
    v = shapeWave theta, ferD, ferU
    x = (i / steps) * width
    y = mid - v * amp
    parts.push "#{if i is 0 then 'M' else 'L'}#{x.toFixed(2)} #{y.toFixed(2)}"
  parts.join ' '

# ── Espelho skew diagnostic (stroke-asymmetry fingerprint) ──────
# Mirrors the firmware lock-in bank: |2nd harmonic| / |fundamental|
# of a sampled signal plus the 2nd-harmonic phase. Samples are
# { t, value } frames; frequency is the flap frequency in Hz.
# Returns null when the fundamental is silent (clean zeros).
espelhoDiagnostic = (samples = [], frequency = 0) ->
  return null unless samples?.length >= 16 and frequency > 0
  omega = TWO_PI * frequency
  re1 = im1 = re2 = im2 = 0
  for s in samples
    continue unless s? and Number.isFinite(s.t) and Number.isFinite(s.value)
    v = s.value
    w1 = omega * s.t
    w2 = 2 * w1
    re1 += v * Math.cos w1
    im1 += v * Math.sin w1
    re2 += v * Math.cos w2
    im2 += v * Math.sin w2
  mag1 = Math.hypot re1, im1
  return null unless mag1 > 1e-6
  mag2 = Math.hypot re2, im2
  phase = Math.atan2(im2, re2) * 180 / Math.PI
  ratio: mag2 / mag1
  phaseDeg: (phase + 360) % 360

export {
  MATH_LAYERS, MATH_PARAMS, MATH_KEYS, MATH_DEFAULTS
  mathLayerOf, mathParamsOf, strokePreviewPath, espelhoDiagnostic
}