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

# Icons are registry keys (src/lib/icons.coffee) — one SVG vocabulary
# shared by dock, sub-menu, palette and page headlines.
MODULES = [
  ['/basic',    'Grundkonfiguration', 'wing']
  ['/profiles', 'Flugprofile',        'layers']
  ['/servos',   'Servos',             'gear']
  ['/control',  'Steuerung',          'sliders']
  ['/sensors',  'Sensorik',           'radar']
  ['/system',   'System',             'grid']
  ['/safety',   'Sicherheit',         'shield']
  ['/cli',      'CLI',                'terminal']
]

SUBTABS =
  basic: [
    ['/basic/body',     'Körperplan', 'body']
    ['/basic/airframe', 'Flugwerk',   'airframe']
    ['/basic/wave',     'Schlagkurve', 'waves']
  ]
  profiles: [['/profiles', 'Profile', 'layers']]
  servos:   [['/servos', 'Servos', 'gear']]
  control: [
    ['/control/pid',         'PID',        'gauge']
    ['/control/math',        'Math',       'function']
    ['/control/modes',       'Modi',       'toggle']
    ['/control/receiver',    'Empfänger',  'antenna']
    ['/control/adjustments', 'Justierung', 'wrench']
  ]
  sensors: [
    ['/sensors/hardware', 'Sensoren', 'chip']
    ['/sensors/gyro',     'Gyro',     'gyro']
  ]
  system: [
    ['/system/device', 'Gerät',    'device']
    ['/system/ports',  'Ports',    'ports']
    ['/system/power',  'Power',    'battery']
    ['/system/vtx',    'VTX',      'broadcast']
    ['/system/osd',    'OSD',      'overlay']
    ['/system/voice',  'Sprache',  'voice']
    ['/system/memory', 'Speicher', 'memory']
    ['/system/flash',  'The Molt', 'bolt']
    ['/system/data',   'Daten',    'data']
  ]
  safety: [['/safety', 'Failsafe', 'shield']]
  cli:    [['/cli', 'CLI', 'terminal']]

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

# Module metadata by id — icon/label/path for contextual headers.
MODULE_BY_ID = {}
for [modPath, label, icon] in MODULES
  MODULE_BY_ID[modPath.slice 1] = { path: modPath, label, icon }

# Active module descriptor for the given path (drives the top-menu header).
activeModuleForPath = (path) ->
  id = moduleIdForPath path
  mod = MODULE_BY_ID[id]
  { id, path: mod.path, label: mod.label, icon: mod.icon }

# Active sub-view descriptor for the given path. Each sub-view carries its
# own icon — a headline shows the sub-view's glyph, not the parent module's.
# Falls back to the module descriptor when the path is a module root.
activeSubtabForPath = (path) ->
  id = moduleIdForPath path
  p = path or '/'
  p = p.slice 0, -1 if p.length > 1 and p.endsWith '/'
  for [subPath, label, icon] in (SUBTABS[id] ? [])
    return { id, path: subPath, label, icon } if subPath is p
  activeModuleForPath p

export {
  MODULES, SUBTABS, moduleIdForPath, subtabsForPath,
  activeModuleForPath, activeSubtabForPath
}