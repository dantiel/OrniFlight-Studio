###
# ORNIFLIGHT STUDIO — Navigation
#
# Single source of truth for the two-tier navigation:
#   Dock (bottom)   = top-level modules — the bird's-eye path
#   ConfigTabs (top)= sub-views of the active module
#
# The dock is coarse; the top menu is the current module's sub-views.
# Every sub-view path lives under its module path so the dock item
# stays highlighted across the whole module and the top menu mirrors
# it naturally.
###

MODULES = [
  ['/basic',    'Grundkonfiguration', '🪽']
  ['/profiles', 'Flugprofile',        '🎭']
  ['/servos',   'Servos',             '⚙']
  ['/control',  'Steuerung',          '△']
  ['/sensors',  'Sensorik',           '◎']
  ['/system',   'System',             '◫']
  ['/safety',   'Sicherheit',         '◇']
  ['/cli',      'CLI',                '❯']
]

SUBTABS =
  basic: [
    ['/basic/body',     'Körperplan']
    ['/basic/airframe', 'Flugwerk']
    ['/basic/wave',     'Schlagkurve']
  ]
  profiles: [['/profiles', 'Profile']]
  servos:   [['/servos', 'Servos']]
  control: [
    ['/control/pid',         'PID']
    ['/control/modes',       'Modi']
    ['/control/receiver',    'Empfänger']
    ['/control/adjustments', 'Justierung']
  ]
  sensors: [
    ['/sensors/hardware', 'Sensoren']
    ['/sensors/gyro',     'Gyro']
  ]
  system: [
    ['/system/device', 'Gerät']
    ['/system/ports',  'Ports']
    ['/system/power',  'Power']
    ['/system/vtx',    'VTX']
    ['/system/osd',    'OSD']
    ['/system/voice',  'Sprache']
    ['/system/memory', 'Speicher']
    ['/system/flash',  'Firmware']
    ['/system/data',   'Daten']
  ]
  safety: [['/safety', 'Failsafe']]
  cli:    [['/cli', 'CLI']]

# Canonical path (module root or sub-view) → module id.
PATH_TO_MODULE = {}
for [modPath, label, glyph] in MODULES
  PATH_TO_MODULE[modPath] = modPath.slice 1
for id, tabs of SUBTABS
  for [subPath, label] in tabs
    PATH_TO_MODULE[subPath] = id

moduleIdForPath = (path) ->
  p = path or '/'
  p = p.slice 0, -1 if p.length > 1 and p.endsWith '/'
  best = 'basic'
  bestLen = -1
  for key, id of PATH_TO_MODULE
    if (p is key or p.startsWith "#{key}/") and key.length > bestLen
      best = id
      bestLen = key.length
  best

subtabsForPath = (path) ->
  return [] if not path or path is '/'
  SUBTABS[moduleIdForPath path] ? []

# Module metadata by id — glyph/label/path for contextual headers.
MODULE_BY_ID = {}
for [modPath, label, glyph] in MODULES
  MODULE_BY_ID[modPath.slice 1] = { path: modPath, label, glyph }

# Active module descriptor for the given path (drives the top-menu header).
activeModuleForPath = (path) ->
  id = moduleIdForPath path
  mod = MODULE_BY_ID[id]
  { id, path: mod.path, label: mod.label, glyph: mod.glyph }

export { MODULES, SUBTABS, moduleIdForPath, subtabsForPath, activeModuleForPath }