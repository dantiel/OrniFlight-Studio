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

# ── Control-surface vocabulary ──────────────────────────────────
# The surfaces a gearbox craft can carry. /servos renders only the
# ones the active mixer declares (mixerCatalog.controlSurfacesForProfile).

# Named input sources — the Betaflight inputSource_e subset that drives
# ornithopter control surfaces. `code` is the wire u8 for the mix rule.
export INPUT_SOURCES = [
  { id: 'none',         label: 'Keine',           code: 0 }
  { id: 'stabRoll',     label: 'Stab. Roll',      code: 1 }
  { id: 'stabPitch',    label: 'Stab. Nick',      code: 2 }
  { id: 'stabYaw',      label: 'Stab. Gier',      code: 3 }
  { id: 'stabThrottle', label: 'Stab. Gas',       code: 4 }
  { id: 'rcRoll',       label: 'RC Roll',         code: 5 }
  { id: 'rcPitch',      label: 'RC Nick',         code: 6 }
  { id: 'rcYaw',        label: 'RC Gier',         code: 7 }
  { id: 'rcThrottle',   label: 'RC Gas',          code: 8 }
  { id: 'aux1',         label: 'AUX 1 (Kanal 5)', code: 9 }
  { id: 'aux2',         label: 'AUX 2 (Kanal 6)', code: 10 }
  { id: 'aux3',         label: 'AUX 3 (Kanal 7)', code: 11 }
  { id: 'aux4',         label: 'AUX 4 (Kanal 8)', code: 12 }
]

export inputSourceById = (id) ->
  INPUT_SOURCES.find((source) -> source.id is id)

# Stable surface order — the mix-rule slot each surface occupies on the
# wire (rudder first, then v-tail/elevator, then motor).
export CONTROL_SURFACE_IDS = [
  'rudder', 'elevator', 'vtailLeft', 'vtailRight', 'motor'
]