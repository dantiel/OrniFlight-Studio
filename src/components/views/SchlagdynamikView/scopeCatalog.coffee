###
# ORNIFLIGHT STUDIO — StrokeScope curve catalog
#
# Single source of truth for the scope's plottable bands and curves:
# band layout fractions, curve→band membership, the theme CSS variable
# per curve, and dash patterns. The renderer (StrokeScope), the legend
# and the config menu all read from here so a swatch always matches
# the ink drawn on the canvas.
###

SCOPE_BANDS = [
  { id: 'wing',     label: 'Wing motion', frac: 0.34 }
  { id: 'servo',    label: 'Servo outputs', frac: 0.16 }
  { id: 'gyro',     label: 'Gyroscope', frac: 0.16 }
  { id: 'ferocity', label: 'Ferocity', frac: 0.18 }
  { id: 'cadence',  label: 'Tempo', frac: 0.12 }
]

SCOPE_CURVES = [
  { id: 'wingL', band: 'wing', label: 'Left wing', shortLabel: 'Wing L', theme: '--orgone-a', dash: [] }
  { id: 'wingR', band: 'wing', label: 'Right wing', shortLabel: 'Wing R', theme: '--of-accent-purple', dash: [5, 4] }
  { id: 'servo1', band: 'servo', label: 'Servo 1', shortLabel: 'S1', theme: '--of-accent-amber', dash: [] }
  { id: 'servo2', band: 'servo', label: 'Servo 2', shortLabel: 'S2', theme: '--of-accent-pink', dash: [5, 4] }
  { id: 'servo3', band: 'servo', label: 'Servo 3', shortLabel: 'S3', theme: '--of-accent-green', dash: [1, 3] }
  { id: 'servo4', band: 'servo', label: 'Servo 4', shortLabel: 'S4', theme: '--of-accent-cyan', dash: [2, 4] }
  { id: 'gyroRoll', band: 'gyro', label: 'Gyro roll', shortLabel: 'Roll', theme: '--of-accent-amber', dash: [] }
  { id: 'gyroPitch', band: 'gyro', label: 'Gyro pitch', shortLabel: 'Pitch', theme: '--of-accent-green', dash: [3, 3] }
  { id: 'gyroYaw', band: 'gyro', label: 'Gyro yaw', shortLabel: 'Yaw', theme: '--of-accent-purple', dash: [1, 3] }
  { id: 'ferStroke', band: 'ferocity', label: 'Stroke ferocity', shortLabel: 'Stroke', theme: '--orgone-b', dash: [] }
  { id: 'ferReturn', band: 'ferocity', label: 'Return ferocity', shortLabel: 'Return', theme: '--of-accent-blue', dash: [5, 4] }
  { id: 'ferShape', band: 'ferocity', label: 'Shape mix', shortLabel: 'Shape', theme: '--of-accent-cyan', dash: [1, 3] }
  { id: 'cadence', band: 'cadence', label: 'Flap cadence', shortLabel: 'Hz', theme: '--orgone-c', dash: [] }
]

scopeCurve = (id) -> SCOPE_CURVES.find (curve) -> curve.id is id

curvesInBand = (bandId) -> SCOPE_CURVES.filter (curve) -> curve.band is bandId

export { SCOPE_BANDS, SCOPE_CURVES, scopeCurve, curvesInBand }
