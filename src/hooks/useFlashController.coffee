###
# ORNIFLIGHT STUDIO · The Molt — useFlashController Hook
#
# Orchestrates the flashing page: catalog discovery, board detection,
# flash machine events and the contextual button descriptor.
# Components receive a plain derived object — no state scattered.
###
import { useEffect } from 'react'
import useFlasher, { getFlashActor } from './useFlasher.coffee'
import useFirmwareStore from '../stores/useFirmwareStore.coffee'
import useCloudForgeStore from '../stores/useCloudForgeStore.coffee'
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
  forge = useCloudForgeStore()

  useEffect ->
    forge.checkHealth()
    undefined
  , []

  catalog = fwStore.catalog
  selectedFw =
    if fwStore.selectedId == 'local'
      fwStore.localImage
    else if fwStore.selectedId == 'cloud'
      fwStore.cloudImage
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
    cloudImage: fwStore.cloudImage
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
    forge:
      online: forge.online
      configured: forge.configured
      checking: forge.checking
      targets: forge.targets
      history: forge.history
      current: forge.current
      building: forge.building
      built: forge.built
      loading: forge.loading
      error: forge.error
      features: forge.features
      onToggleFeature: forge.toggleFeature
      onCheckHealth: forge.checkHealth
      onLoadHistory: forge.loadHistory
      onBuild: forge.startBuild
      onLoad: forge.loadBuild
      onCancel: forge.cancel
      onReset: forge.reset
  }

export default useFlashController