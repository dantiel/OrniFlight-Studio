###
# ORNIFLIGHT STUDIO — Servo Efficiency Catalog
#
# Curated micro-servo presets for the ornithopter PWM chain. A preset
# is NOT a firmware-bound profile: it only carries the physical pulse
# envelope (min / middle / max µs) plus an efficiency score. Applying
# one copies its values into a servo slot and never writes a name —
# the firmware stays name-agnostic, the draft stays honest.
#
# `efficiency` is a 0–100 figure of merit (torque per gram per ampere),
# not a wire field — it ranks the presets in the selector. Extend this
# table freely; the values are the editable ground truth.
###
export SERVO_PRESETS = [
  {
    id: 'kst-x06'
    name: 'KST X06'
    min: 880
    max: 2160
    middle: 1520
    efficiency: 92
    weight: '5.8 g'
  }
  {
    id: 'kst-x08'
    name: 'KST X08'
    min: 880
    max: 2160
    middle: 1520
    efficiency: 90
    weight: '8.0 g'
  }
  {
    id: 'bluearrow-d0474'
    name: 'BlueArrow D0474'
    min: 880
    max: 2160
    middle: 1520
    efficiency: 88
    weight: '4.7 g'
  }
  {
    id: 'corona-ds843mg'
    name: 'Corona DS843MG'
    min: 880
    max: 2160
    middle: 1520
    efficiency: 85
    weight: '4.5 g'
  }
  {
    id: 'emax-es9051'
    name: 'EMAX ES9051'
    min: 900
    max: 2100
    middle: 1500
    efficiency: 80
    weight: '4.1 g'
  }
  {
    id: 'turnigy-tgy1370a'
    name: 'Turnigy TGY-1370A'
    min: 880
    max: 2160
    middle: 1520
    efficiency: 76
    weight: '3.7 g'
  }
]

export servoPresetById = (id) ->
  SERVO_PRESETS.find((preset) -> preset.id is id)
