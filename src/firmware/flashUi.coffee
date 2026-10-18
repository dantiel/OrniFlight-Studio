###
# ORNIFLIGHT STUDIO · The Molt — Flash UI lexicon
#
# Pure presentation data: phase labels, option list and the
# contextual flash button descriptor. No state, no side effects.
# Strings resolve through the i18n catalog at call time so the
# Molt speaks the active language.
###
import { getT } from '../i18n/index.coffee'

PHASE_KEYS =
  idle:      'flash.ready'
  scanning:  'flash.scanning'
  ready:     'flash.readyImage'
  erasing:   'flash.erasing'
  writing:   'flash.writing'
  verifying: 'flash.verifying'
  done:      'flash.done'
  error:     'flash.error'
  reboot:    'flash.reboot'

flashOptions = (t = getT()) -> [
  ['verify', t('flash.verify'), t('flash.verifyHint')]
  ['fullErase', t('flash.fullErase'), t('flash.fullEraseHint')]
  ['reboot', t('flash.rebootAfter'), t('flash.rebootAfterHint')]
]

transportLabel = (transport) ->
  t = getT()
  if transport == 'serial' then t('flash.serial')
  else if transport == 'webusb' then t('flash.usbDfu')
  else t('flash.dryRun')

phaseLabel = (phase) ->
  t = getT()
  t(PHASE_KEYS[phase]) or phase

buttonFor = (phase, hasFirmware, pendingBoot = false) ->
  t = getT()
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
    if phase == 'done' then t('flash.rebootBtn')
    else if phase == 'error' then t('flash.resetBtn')
    else if flashing then t('flash.transmigrating')
    else if pendingBoot then t('flash.enterBootloader')
    else t('flash.flashFirmware')
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
  t = getT()
  sel = ctrl.selectedId
  special =
    local: ctrl.localImage?.name ? t('flash.local')
    cloud: ctrl.cloudImage?.name ? t('flash.cloud')
  specialWord = special[sel]
  catFw = if sel then (ctrl.catalog or []).find (f) -> f.id == sel
  fw =
    if specialWord then specialWord
    else if catFw then "v#{catFw.version}"
    else t('flash.noImage')
  flashing = ctrl.phase in ['erasing', 'writing', 'verifying']
  forge =
    if ctrl.forge.checking then t('flash.scanningForge')
    else if ctrl.forge.online then t('flash.online')
    else t('flash.offline')
  btn =
    if flashing then t('flash.transmuting')
    else if ctrl.phase == 'done' then t('flash.rebootBtn')
    else if pendingBoot then t('flash.bootloader')
    else t('flash.flashBtn')
  state =
    if flashing then ctrl.label
    else if ctrl.phase == 'done' then t('flash.hatched')
    else if pendingBoot then t('flash.linkLive')
    else t('flash.armed')
  {
    target: ctrl.device?.target or 'ORNI-F4'
    fw
    forge
    flashing
    btn
    state
  }

export {
  PHASE_KEYS, flashOptions, phaseLabel, transportLabel, buttonFor,
  moltDeck
}
