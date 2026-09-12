###
# ORNIFLIGHT STUDIO — Mixer Catalog (kernel ↔ mixer ↔ servo map)
#
# Derived from the PteronautOS ornithopter panel UI — the most
# advanced servo/mixer surface of the three worlds — and mapped
# onto the OrniFlight firmware MixerProfile enum (8 entries,
# ids 0…7). Every entry carries the kernel it belongs to, the
# servo count, its morphological flags and the GPIO map string.
###
export KERNELS = [
  { id: 'servo', label: 'Direktantrieb', glyph: '🪽' }
  { id: 'gearbox', label: 'Getriebe', glyph: '⚙️' }
]

# Hermetic: each profile is a body plan, not a setting.
export MIXER_PROFILES = [
  { id: 0, name: 'SERVO_2WING', kernel: 'servo', servos: 2,
    rudder: false, vtail: false, motor: false,
    map: 'L Wing GPIO9 ↔ R Wing GPIO10' }
  { id: 1, name: 'SERVO_2WING_1RUD', kernel: 'servo', servos: 3,
    rudder: true, vtail: false, motor: false,
    map: 'L Wing GPIO9 ↔ R Wing GPIO10 ↔ Rudder GPIO5' }
  { id: 2, name: 'SERVO_4WING', kernel: 'servo', servos: 4,
    rudder: false, vtail: false, motor: false,
    map: 'L GPIO9 ↔ R GPIO10 ↔ Back-L GPIO5 ↔ Back-R GPIO16' }
  { id: 3, name: 'GEARBOX_2VTAIL_1RUD', kernel: 'gearbox', servos: 3,
    rudder: true, vtail: true, motor: false,
    map: 'Rudder GPIO9 ↔ V-Tail L GPIO10 ↔ V-Tail R GPIO5' }
  { id: 4, name: 'GEARBOX_1MOT_2VTAIL', kernel: 'gearbox', servos: 3,
    rudder: false, vtail: true, motor: true,
    map: 'Motor GPIO9 ↔ V-Tail L GPIO10 ↔ V-Tail R GPIO5' }
  { id: 5, name: 'GEARBOX_1MOT_2VTAIL_1RUD', kernel: 'gearbox', servos: 4,
    rudder: true, vtail: true, motor: true,
    map: 'Rudder GPIO9 ↔ Motor GPIO10 ↔ V-Tail L GPIO5 ↔ V-Tail R GPIO16' }
  { id: 6, name: 'GEARBOX_1ELE_1RUD', kernel: 'gearbox', servos: 2,
    rudder: true, vtail: false, motor: false,
    map: 'Rudder GPIO9 ↔ Elevator GPIO10' }
  { id: 7, name: 'GEARBOX_1MOT_1ELE_1RUD', kernel: 'gearbox', servos: 3,
    rudder: true, vtail: false, motor: true,
    map: 'Rudder GPIO9 ↔ Motor GPIO10 ↔ Elevator GPIO5' }
]

# Servo speed presets — speed + pulse pairs (µs pulsewidth).
export SERVO_SPEED_PRESETS = [
  { id: 'smooth', label: '0.28 s/60°', speed: 280 }
  { id: 'tuned', label: '0.22 s/60°', speed: 220 }
  { id: 'direct', label: '0.15 s/60°', speed: 150 }
  { id: 'swift', label: '0.10 s/60°', speed: 100 }
  { id: 'violent', label: '0.06 s/60°', speed: 60 }
]

export profilesForKernel = (kernel) ->
  MIXER_PROFILES.filter (p) -> p.kernel is kernel

export profileById = (id) ->
  MIXER_PROFILES.find((p) -> p.id is id) or MIXER_PROFILES[0]

export firstForKernel = (kernel) ->
  profilesForKernel(kernel)[0]?.id ? 0

# Trim fields per profile morphology — what the body plan can bend.
export trimsForProfile = (profile) ->
  out = []
  if profile.kernel is 'servo'
    out.push { prop: 'leftWing', label: 'Flügel L' }
    out.push { prop: 'rightWing', label: 'Flügel R' }
    out.push { prop: 'rudder', label: 'Seitenruder' } if profile.rudder
    if profile.servos >= 4
      out.push { prop: 'backLeftWing', label: 'Flügel L hinten' }
  else
    out.push { prop: 'rudder', label: 'Seitenruder' } if profile.rudder
    if profile.vtail
      out.push { prop: 'vtailLeft', label: 'V-Leitwerk L' }
      out.push { prop: 'vtailRight', label: 'V-Leitwerk R' }
    else
      out.push { prop: 'elevator', label: 'Höhenruder' } if profile.servos <= 3
  out