###
# ORNIFLIGHT STUDIO — Math Suite Registry (ONDAS + ESPELHO)
#
# Single source of truth for the 18-parameter mathematics suite on
# ornithopterProfile_t (firmware settings.c). Ten coupled layers
# transform raw PID terms into the wing's phase-locked motion.
#
# Consumers:
#   - mspDecoders.coffee      → ONDAS_KEYS / ONDAS_DEFAULTS / codec
#   - useOrnithopterStore     → per-profile ONDAS + clamp ranges
#   - OrnithopterModel        → setOndasParam clamp ranges
#   - SchlagdynamikView       → labels, ranges, units, layer grouping
#
# Human-facing fields (name/label/role) are i18n keys resolved through
# t(); numeric metadata (min/max/unit/signed) stays wire-truth.
#
# Defaults mirror pgResetFn_ornithopterProfiles (firmware reset).
###
import { shapeWave, ferocityUnits } from '../simulation/waveform.coffee'

TWO_PI = 2 * Math.PI

# ── Layer order = wire order (one u8 per key, signed as value+128) ──
MATH_LAYERS = [
  { id: 'cadence', name: 'math.layer.cadence.name', glyph: '∿'
    role: 'math.layer.cadence.role' }
  { id: 'ferocity', name: 'math.layer.ferocity.name', glyph: '🔥'
    role: 'math.layer.ferocity.role' }
  { id: 'balance', name: 'math.layer.balance.name', glyph: '⚖'
    role: 'math.layer.balance.role' }
  { id: 'warp', name: 'math.layer.warp.name', glyph: '⟁'
    role: 'math.layer.warp.role' }
  { id: 'anchor', name: 'math.layer.anchor.name', glyph: '⚓'
    role: 'math.layer.anchor.role' }
  { id: 'resonance', name: 'math.layer.resonance.name', glyph: '〰'
    role: 'math.layer.resonance.role' }
  { id: 'prescience', name: 'math.layer.prescience.name', glyph: '🔮'
    role: 'math.layer.prescience.role' }
  { id: 'espelho', name: 'math.layer.espelho.name', glyph: '🪞'
    role: 'math.layer.espelho.role' }
  { id: 'saudade', name: 'math.layer.saudade.name', glyph: '🌘'
    role: 'math.layer.saudade.role' }
  { id: 'aeroelastic', name: 'math.layer.aeroelastic.name', glyph: '🌬'
    role: 'math.layer.aeroelastic.role' }
]

MATH_PARAMS =
  cadence_gain:
    layer: 'cadence', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.cadence_gain.label'
    role: 'math.param.cadence_gain.role'
  ferocity_p_gain:
    layer: 'ferocity', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.ferocity_p_gain.label'
    role: 'math.param.ferocity_p_gain.role'
  ferocity_d_gain:
    layer: 'ferocity', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.ferocity_d_gain.label'
    role: 'math.param.ferocity_d_gain.role'
  ferocity_roll_gain:
    layer: 'ferocity', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.ferocity_roll_gain.label'
    role: 'math.param.ferocity_roll_gain.role'
  ferocity_yaw_gain:
    layer: 'ferocity', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.ferocity_yaw_gain.label'
    role: 'math.param.ferocity_yaw_gain.role'
  ferocity_downstroke:
    layer: 'ferocity', min: 1, max: 100, unit: '%', signed: false
    label: 'math.param.ferocity_downstroke.label'
    role: 'math.param.ferocity_downstroke.role'
  ferocity_upstroke:
    layer: 'ferocity', min: 1, max: 100, unit: '%', signed: false
    label: 'math.param.ferocity_upstroke.label'
    role: 'math.param.ferocity_upstroke.role'
  balance_gain:
    layer: 'balance', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.balance_gain.label'
    role: 'math.param.balance_gain.role'
  warp_gain:
    layer: 'warp', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.warp_gain.label'
    role: 'math.param.warp_gain.role'
  warp_yaw_gain:
    layer: 'warp', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.warp_yaw_gain.label'
    role: 'math.param.warp_yaw_gain.role'
  anchor_gain:
    layer: 'anchor', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.anchor_gain.label'
    role: 'math.param.anchor_gain.role'
  resonance_gain:
    layer: 'resonance', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.resonance_gain.label'
    role: 'math.param.resonance_gain.role'
  prescience_gain:
    layer: 'prescience', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.prescience_gain.label'
    role: 'math.param.prescience_gain.role'
  espelho_gain:
    layer: 'espelho', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.espelho_gain.label'
    role: 'math.param.espelho_gain.role'
  saudade_gain:
    layer: 'saudade', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.saudade_gain.label'
    role: 'math.param.saudade_gain.role'
  ssff_gain:
    layer: 'prescience', min: 0, max: 100, unit: '%', signed: false
    label: 'math.param.ssff_gain.label'
    role: 'math.param.ssff_gain.role'
  aeroelastic_glide_coefficient:
    layer: 'aeroelastic', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.aeroelastic_glide_coefficient.label'
    role: 'math.param.aeroelastic_glide_coefficient.role'
  aeroelastic_flap_coefficient:
    layer: 'aeroelastic', min: -100, max: 100, unit: '%', signed: true
    label: 'math.param.aeroelastic_flap_coefficient.label'
    role: 'math.param.aeroelastic_flap_coefficient.role'

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
                        'saudade_gain', 'ssff_gain', 'cadence_gain'] then 0
        else if key is 'aeroelastic_glide_coefficient' then 20
        else if key is 'aeroelastic_flap_coefficient' then 40
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
