# ServoInspector helpers

export pidDefs = [
  { id: 'roll_P',  label: 'Roll P' }
  { id: 'roll_I',  label: 'Roll I' }
  { id: 'roll_D',  label: 'Roll D' }
  { id: 'pitch_P', label: 'Pitch P' }
  { id: 'pitch_I', label: 'Pitch I' }
  { id: 'pitch_D', label: 'Pitch D' }
  { id: 'yaw_P',   label: 'Yaw P' }
  { id: 'yaw_I',   label: 'Yaw I' }
  { id: 'yaw_D',   label: 'Yaw D' }
]

export ondasDefs = [
  { id: 'cadence_gain',     label: 'Cadence' }
  { id: 'ferocity_p_gain',  label: 'Ferocity P' }
  { id: 'ferocity_d_gain',  label: 'Ferocity D' }
  { id: 'balance_gain',     label: 'Balance' }
  { id: 'warp_gain',        label: 'Warp' }
  { id: 'anchor_gain',      label: 'Anchor' }
  { id: 'resonance_gain',   label: 'Resonance' }
]

export servoDefs = [
  { id: 'midpoint',       label: 'Midpoint',   min: '500',  max: '2500', step: '1' }
  { id: 'min',            label: 'Min PWM',    min: '500',  max: '2500', step: '1' }
  { id: 'max',            label: 'Max PWM',    min: '500',  max: '2500', step: '1' }
  { id: 'rate',           label: 'Rate',       min: '-100', max: '100',  step: '1' }
  { id: 'amplitudeScale', label: 'Amplitude',  min: '0',    max: '2',    step: '0.1' }
]

export servoDisplay = (servo, s) ->
  v = servo[s.id] || 0
  if s.id == 'rate' then "#{v}%"
  else if s.id == 'amplitudeScale' then v.toFixed(1)
  else String(v)

export servoParse = (s) ->
  if s.id == 'amplitudeScale' then parseFloat else parseInt
