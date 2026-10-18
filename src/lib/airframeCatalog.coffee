###
# ORNIFLIGHT STUDIO — Airframe Catalog (Zelle, Masse, Montage)
#
# The physical document the firmware never sees: span/chord → area +
# aspect ratio, total mass + centre of gravity (longitudinal/vertical/
# lateral), and per-pair servo mounting geometry. PteronautOS carries
# no MSP codes for geometry, mass or CG — the configuration document
# owns them. Mirrored into the engine's setAirframe so the 3D viewport
# renders the true mounting layout.
###

# Dimensionless CG stations (±100, + = nose / right) ride the same σ·100
# convention the engine's arrangement presets already use. mm fields are
# physical millimetres. Mount `station`/`vertical` normalise by /300 to
# the engine's abstract σ station grid (±1 σ ≈ 300 mm).
export AIRFRAME_LIMITS =
  wingSpan:  { min: 400,  max: 3000 }
  chord:     { min: 80,   max: 500  }
  totalMass: { min: 80,   max: 3000 }
  cgX:       { min: -100, max: 100  }
  cgZ:       { min: -100, max: 100  }
  cgLat:     { min: -100, max: 100  }

export MOUNT_LIMITS =
  angle:    { min: -45, max: 45  }
  station:  { min: -300, max: 300 }
  vertical: { min: -100, max: 100 }

export MOUNT_PAIRS = 4

export AIRFRAME_FIELDS = [
  { id: 'wingSpan', label: 'airframe.field.wingSpan.label',
    hermes: 'airframe.field.wingSpan.hermes', unit: 'mm' }
  { id: 'chord', label: 'airframe.field.chord.label',
    hermes: 'airframe.field.chord.hermes', unit: 'mm' }
  { id: 'totalMass', label: 'airframe.field.totalMass.label',
    hermes: 'airframe.field.totalMass.hermes', unit: 'g' }
  { id: 'cgX', label: 'airframe.field.cgX.label',
    hermes: 'airframe.field.cgX.hermes', unit: 'σ' }
  { id: 'cgZ', label: 'airframe.field.cgZ.label',
    hermes: 'airframe.field.cgZ.hermes', unit: 'mm' }
  { id: 'cgLat', label: 'airframe.field.cgLat.label',
    hermes: 'airframe.field.cgLat.hermes', unit: 'σ' }
]

export MOUNT_FIELDS = [
  { id: 'angle', label: 'airframe.mount.angle.label',
    hermes: 'airframe.mount.angle.hermes', unit: '°' }
  { id: 'station', label: 'airframe.mount.station.label',
    hermes: 'airframe.mount.station.hermes', unit: 'mm' }
  { id: 'vertical', label: 'airframe.mount.vertical.label',
    hermes: 'airframe.mount.vertical.hermes', unit: 'mm' }
]

export defaultAirframe = ->
  wingSpan: 1200
  chord: 180
  totalMass: 520
  cgX: 0
  cgZ: 0
  cgLat: 0
  # Four physical mount stations, seeded with the tandem archetype:
  # fore pair dihedral +30° at +120 mm, aft pair −30° at −120 mm.
  mounts: [
    { angle: 30,  station: 120,  vertical: 0 }
    { angle: -30, station: -120, vertical: 0 }
    { angle: 0,   station: 0,    vertical: 0 }
    { angle: 0,   station: 0,    vertical: 0 }
  ]

# Derived geometry — wing area (cm²) and aspect ratio. Kept out of the
# draft so the raw document stays the single source of truth.
export airframeDerived = (airframe = {}) ->
  span = Number(airframe.wingSpan) or 1200
  chord = Number(airframe.chord) or 180
  wingArea: span * chord / 100
  aspectRatio: if chord > 0 then span / chord else 0