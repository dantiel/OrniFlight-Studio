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
#
# Labels are i18n keys (src/i18n/{de,en}.coffee) — resolve them at
# render time through t(). Icons stay registry keys (src/lib/icons.coffee).
###

MODULES = [
  ['/basic',    'nav.modules.basic',    'wing']
  ['/profiles', 'nav.modules.profiles', 'layers']
  ['/servos',   'nav.modules.servos',   'gear']
  ['/control',  'nav.modules.control',  'sliders']
  ['/sensors',  'nav.modules.sensors',  'radar']
  ['/system',   'nav.modules.system',   'grid']
  ['/safety',   'nav.modules.safety',   'shield']
  ['/cli',      'nav.modules.cli',      'terminal']
]

SUBTABS =
  basic: [
    ['/basic/body',     'nav.subtabs.basic.body',     'body']
    ['/basic/airframe', 'nav.subtabs.basic.airframe', 'airframe']
  ]
  profiles: [['/profiles', 'nav.subtabs.profiles.profiles', 'layers']]
  servos:   [['/servos', 'nav.subtabs.servos.servos', 'gear']]
  control: [
    ['/control/pid',            'nav.subtabs.control.pid',           'gauge']
    ['/control/strokedynamics',  'nav.subtabs.control.schlagdynamik', 'function']
    ['/control/modes',          'nav.subtabs.control.modes',         'toggle']
    ['/control/receiver',    'nav.subtabs.control.receiver',    'antenna']
    ['/control/adjustments', 'nav.subtabs.control.adjustments', 'wrench']
  ]
  sensors: [
    ['/sensors/hardware', 'nav.subtabs.sensors.hardware', 'chip']
    ['/sensors/gyro',     'nav.subtabs.sensors.gyro',     'gyro']
  ]
  system: [
    ['/system/device', 'nav.subtabs.system.device', 'device']
    ['/system/ports',  'nav.subtabs.system.ports',  'ports']
    ['/system/power',  'nav.subtabs.system.power',  'battery']
    ['/system/vtx',    'nav.subtabs.system.vtx',    'broadcast']
    ['/system/osd',    'nav.subtabs.system.osd',    'overlay']
    ['/system/voice',  'nav.subtabs.system.voice',  'voice']
    ['/system/memory', 'nav.subtabs.system.memory', 'memory']
    ['/system/flash',  'nav.subtabs.system.flash',  'bolt']
    ['/system/data',   'nav.subtabs.system.data',   'data']
    ['/system/app',    'nav.subtabs.system.app',    'sliders']
  ]
  safety: [['/safety', 'nav.subtabs.safety.failsafe', 'shield']]
  cli:    [['/cli', 'nav.subtabs.cli.cli', 'terminal']]

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

# Module metadata by id — icon/label-key/path for contextual headers.
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