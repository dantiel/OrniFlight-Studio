###
# ORNIFLIGHT STUDIO — useFlashController Hook
#
# Orchestrates the flashing page: catalog discovery, board detection,
# flash machine events and the contextual button descriptor.
# Components receive a plain derived object — no state scattered.
###
import { useEffect } from 'react'
import useFlasher, { getFlashActor } from './useFlasher.coffee'
import useFirmwareStore from '../stores/useFirmwareStore.coffee'
import { run, reboot } from '../firmware/flashService.coffee'
import { phaseLabel, buttonFor } from '../firmware/flashUi.coffee'

useFlashController = ->
  loadCatalog = useFirmwareStore (s) -> s.loadCatalog
  useEffect ->
    loadCatalog()
    undefined
  , []

  flash = useFlasher()
  fwStore = useFirmwareStore()

  catalog = fwStore.catalog
  selectedFw =
    if fwStore.selectedId == 'local'
      fwStore.localImage
    else
      catalog.find (f) -> f.id == fwStore.selectedId
  phase = flash.state

  onLog = (level, text) -> fwStore.appendLog level, text

  handleError = (e) ->
    msg = e?.message or String(e or 'unknown error')
    fwStore.appendLog 'ERROR', msg
    flash.send { type: 'ERROR', error: msg }

  onFlash = ->
    return unless selectedFw
    flash.send { type: 'START', firmware: selectedFw, options: fwStore.options }
    run(getFlashActor(), selectedFw, fwStore.options, onLog).catch handleError

  onReboot = ->
    flash.send { type: 'REBOOT' }
    reboot(getFlashActor(), onLog).catch handleError

  onLoadLocal = (file) ->
    return unless file
    fwStore.loadLocalFile(file)
      .then (fw) ->
        fwStore.appendLog 'INFO',
          "Local image loaded: #{fw.name} (#{fw.size} bytes)."
      .catch handleError

  onDetectSerial = ->
    fwStore.detectDevice(onLog, 'serial').catch handleError

  onDetectWebUsb = ->
    fwStore.detectDevice(onLog, 'webusb').catch handleError

  onDetect = onDetectSerial  # Legacy compatibility

  onDisconnect = ->
    fwStore.disconnect()
    fwStore.appendLog 'INFO', 'Device released — back to dry-run.'

  onReset = ->
    flash.send { type: 'RESET' }
    fwStore.clearLog()
    fwStore.appendLog 'INFO', 'Console cleared — ready to transmigrate.'

  btn = buttonFor phase, selectedFw?

  {
    phase
    label:      phaseLabel phase
    progress:   flash.progress
    error:      flash.error
    connected:  fwStore.transport in ['serial', 'webusb']
    serialSupported: fwStore.serialSupported
    webUsbSupported: fwStore.webUsbSupported
    detecting:  fwStore.detecting
    transport:  fwStore.transport
    catalog
    loading:    fwStore.loading
    selectedId: fwStore.selectedId
    localImage: fwStore.localImage
    options:    fwStore.options
    device:     fwStore.device
    log:        fwStore.log
    btn
    onSelect:   (id) -> fwStore.selectFirmware id
    onLoadLocal
    onOption:   (key, value) -> fwStore.setOption key, value
    onDetectSerial
    onDetectWebUsb
    onDetect     # Legacy: alias for onDetectSerial
    onDisconnect
    onClick:
      if phase == 'done' then onReboot
      else if phase == 'error' then onReset
      else onFlash
    onClearLog: ->
      fwStore.clearLog()
      fwStore.appendLog 'INFO', 'Console cleared.'
  }

export default useFlashController