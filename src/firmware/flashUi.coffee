###
# ORNIFLIGHT STUDIO · The Molt — Flash UI lexicon
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

transportLabel = (transport) ->
  if transport == 'serial' then 'SERIAL'
  else if transport == 'webusb' then 'USB DFU'
  else 'DRY-RUN'

phaseLabel = (phase) -> PHASE_LABELS[phase] || phase

buttonFor = (phase, hasFirmware, pendingBoot = false) ->
  flashing = phase in ['erasing', 'writing', 'verifying']
  variant =
    if flashing then 'flashing'
    else if phase == 'done' then 'done'
    else if phase == 'error' then 'error'
    else if pendingBoot then 'boot'
    else 'idle'
  glyph =
    if phase == 'done' then '🐣'
    else if phase == 'error' then '♻️'
    else if flashing then '⚡'
    else if pendingBoot then '🚪'
    else '🪶'
  label =
    if phase == 'done' then 'REBOOT'
    else if phase == 'error' then 'RESET'
    else if flashing then 'TRANSMIGRATING…'
    else if pendingBoot then 'ENTER BOOTLOADER'
    else 'FLASH FIRMWARE'
  # The bootloader bridge needs no image selected — the image matters
  # only once the port speaks AN3155.
  disabled = flashing or (
    not pendingBoot and (phase == 'idle' or phase == 'ready') and
    not hasFirmware
  )
  { variant, glyph, label, disabled }

###
# The Molt control deck — compact live lexicon for the sticky command
# bar. Pure derivation of deck strings from the flash controller.
###
moltDeck = (ctrl, pendingBoot = false) ->
  sel = ctrl.selectedId
  special =
    local: ctrl.localImage?.name ? 'local'
    cloud: ctrl.cloudImage?.name ? 'cloud'
  specialWord = special[sel]
  catFw = if sel then (ctrl.catalog or []).find (f) -> f.id == sel
  fw =
    if specialWord then specialWord
    else if catFw then "v#{catFw.version}"
    else 'no image'
  flashing = ctrl.phase in ['erasing', 'writing', 'verifying']
  forge =
    if ctrl.forge.checking then 'SCANNING'
    else if ctrl.forge.online then 'ONLINE'
    else 'OFFLINE'
  btn =
    if flashing then 'TRANSMUTING…'
    else if ctrl.phase == 'done' then 'REBOOT'
    else if pendingBoot then 'BOOTLOADER'
    else '⚡ FLASH'
  state =
    if flashing then ctrl.label
    else if ctrl.phase == 'done' then 'hatched'
    else if pendingBoot then 'link live'
    else 'armed'
  {
    target: ctrl.device?.target or 'ORNI-F4'
    fw
    forge
    flashing
    btn
    state
  }

export {
  PHASE_LABELS, FLASH_OPTIONS, phaseLabel, transportLabel, buttonFor,
  moltDeck
}