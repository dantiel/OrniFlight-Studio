###
# ORNIFLIGHT STUDIO — Mode catalog
#
# Static ornithopter-filtered index of flight-mode boxes by permanent
# ID. In device mode the firmware box list (MSP 119) merges over this
# catalog: permanent IDs stay authoritative, display names refresh.
# Acro is implicit — the default when no range is active — and never
# appears as a range row.
###

box = (name, letter, category) ->
  Object.freeze { name, letter, category }

MODE_CATALOG = Object.freeze {
  0: box 'Arm', 'ARM', 'state'
  1: box 'Angle', 'ANGLE', 'flight'
  2: box 'Horizon', 'HORIZON', 'flight'
  4: box 'Anti Gravity', 'ANTIGRAV', 'assist'
  5: box 'Magnetometer', 'MAG', 'assist'
  6: box 'Headfree', 'HEADFREE', 'flight'
  7: box 'Head Adj', 'HEADADJ', 'assist'
  8: box 'Camera Stab', 'CAMSTAB', 'camera'
  12: box 'Passthru', 'PASSTHRU', 'flight'
  13: box 'Beeper', 'BEEPER', 'utility'
  15: box 'LED Low', 'LEDLOW', 'utility'
  17: box 'Calibrate', 'CALIB', 'utility'
  19: box 'OSD Disable', 'OSD', 'utility'
  20: box 'Telemetry', 'TELEMETRY', 'utility'
  26: box 'Blackbox', 'BLACKBOX', 'utility'
  27: box 'Failsafe', 'FAILSAFE', 'state'
  28: box 'Air Mode', 'AIRMODE', 'assist'
  30: box 'FPV Angle Mix', 'FPVANGLEMIX', 'assist'
  31: box 'Blackbox Erase', 'BLACKBOXERASE', 'utility'
  36: box 'Prearm', 'PREARM', 'state'
  40: box 'User 1', 'USER1', 'user'
  41: box 'User 2', 'USER2', 'user'
  42: box 'User 3', 'USER3', 'user'
  43: box 'User 4', 'USER4', 'user'
  45: box 'Paralyze', 'PARALYZE', 'assist'
  46: box 'GPS Rescue', 'GPSRESCUE', 'flight'
  47: box 'Acro Trainer', 'ACROTRAINER', 'flight'
  50: box 'Ornithopter Independent', 'ORNI_INDEP', 'ornithopter'
  51: box 'Ornithopter Glide', 'ORNI_GLIDE', 'ornithopter'
  52: box 'Ornithopter Profile', 'ORNI_PROFILE', 'ornithopter'
}

# Dropdown order: safety-critical and ornithopter-specific boxes first.
MODE_PRIORITY = Object.freeze [0, 1, 2, 27, 28, 36, 50, 51, 52]

modePriority = (permanentId) ->
  index = MODE_PRIORITY.indexOf Number permanentId
  if index < 0 then 100 + Number(permanentId) else index

# Catalog entries as { permanentId, name, letter, category } in
# priority order — the shape dropdowns consume.
modeCatalogEntries = ->
  Object.keys(MODE_CATALOG)
    .map((id) -> Number id)
    .sort((a, b) -> modePriority(a) - modePriority(b))
    .map (id) -> { permanentId: id, MODE_CATALOG[id]... }

isModePermId = (id) ->
  Number.isInteger(id) and MODE_CATALOG[Number(id)]?

ACRO_HINT = Object.freeze { name: 'Acro', letter: 'ACRO', permanentId: null }

export default MODE_CATALOG
export {
  MODE_CATALOG, MODE_PRIORITY, modeCatalogEntries, isModePermId, ACRO_HINT
}
