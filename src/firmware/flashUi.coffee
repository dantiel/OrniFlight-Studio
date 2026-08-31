###
# ORNIFLIGHT STUDIO — Flash UI lexicon
#
# Pure presentation data: phase labels, option list and the
# contextual flash button descriptor. No state, no side effects.
###
PHASE_LABELS =
  idle:      'Ready to molt — select an image'
  scanning:  'Scanning the nest for images…'
  ready:     'Image selected — the egg awaits'
  erasing:   'Stripping old plumage…'
  writing:   'Weaving new feathers…'
  verifying: 'Reading the omens (checksum)…'
  done:      'The bird sings anew'
  error:     'The transmigration failed'
  reboot:    'Hatching…'

FLASH_OPTIONS = [
  ['verify', 'Verify after write', 'checksum the new soul']
  ['fullErase', 'Full chip erase', 'strip every feather']
  ['reboot', 'Reboot after flash', 'hatch immediately']
]

phaseLabel = (phase) -> PHASE_LABELS[phase] || phase

buttonFor = (phase, hasFirmware) ->
  flashing = phase in ['erasing', 'writing', 'verifying']
  variant =
    if flashing then 'flashing'
    else if phase == 'done' then 'done'
    else if phase == 'error' then 'error'
    else 'idle'
  glyph =
    if phase == 'done' then '🐣'
    else if phase == 'error' then '♻️'
    else if flashing then '⚡'
    else '🪶'
  label =
    if phase == 'done' then 'REBOOT'
    else if phase == 'error' then 'RESET'
    else if flashing then 'TRANSMIGRATING…'
    else 'FLASH FIRMWARE'
  disabled = flashing or ((phase == 'idle' or phase == 'ready') and not hasFirmware)
  { variant, glyph, label, disabled }

export { PHASE_LABELS, FLASH_OPTIONS, phaseLabel, buttonFor }
