###
# ORNIFLIGHT STUDIO — Firmware Store (Zustand)
#
# UI state for the flashing page: discovered catalog, selection,
# flash options, log buffer, detected device and transport mode.
###
import { create } from 'zustand'
import {
  fetchCatalog, sha256Hex, localFirmware
} from '../firmware/firmwareCatalog.coffee'
import {
  detectDevice, detectSerial, detectWebUsb
  clearDevice, isSerialSupported, isWebUsbSupported
} from '../firmware/flashService.coffee'

MANIFEST_URL = '/firmware/manifest.json'

DEFAULT_DEVICE =
  name: 'OrniFlight F4'
  target: 'ORNI-F4'
  mcu: 'STM32F405RGT6'
  flash: '1 MB'
  uid: '0x33 0x0F 0x2A 0x88'
  firmware: '2.0.0'
  bootloader: 'STM32 DFU'

stamp = ->
  d = new Date()
  hh = String(d.getHours()).padStart 2, '0'
  mm = String(d.getMinutes()).padStart 2, '0'
  ss = String(d.getSeconds()).padStart 2, '0'
  "#{hh}:#{mm}:#{ss}"

useFirmwareStore = create (set, get) ->
  catalog: []
  loading: false
  selectedId: null
  localImage: null
  options: { verify: true, fullErase: false, reboot: true }
  log: []
  device: DEFAULT_DEVICE
  lastError: null
  detecting: false
  transport: 'sim'                  # 'sim' | 'serial' | 'webusb'
  serialSupported: isSerialSupported()
  webUsbSupported: isWebUsbSupported()

  setLoading: (loading) -> set { loading }
  setCatalog: (catalog) -> set { catalog }
  selectFirmware: (selectedId) -> set { selectedId }
  setOption: (key, value) ->
    next = { get().options... }
    next[key] = value
    set { options: next }
  appendLog: (level, text) ->
    entry = { level, text, t: stamp() }
    set { log: [...get().log, entry].slice(-200) }
  clearLog: -> set { log: [] }
  setError: (lastError) -> set { lastError }
  setDevice: (device) -> set { device }
  setTransport: (transport) -> set { transport }

  loadCatalog: (url = MANIFEST_URL) ->
    set { loading: true }
    fetchCatalog(url).then (result) ->
      result.match(
        (catalog) -> set { catalog, loading: false, lastError: null }
        (err) -> set { loading: false, lastError: err }
      )

  loadLocalFile: (file) ->
    buf = await file.arrayBuffer()
    bytes = new Uint8Array buf
    digest = await sha256Hex bytes
    fw = localFirmware file, bytes, digest
    set { localImage: fw, selectedId: 'local', lastError: null }
    fw

  # Detect with transport hint: 'serial' (default) or 'webusb'
  detectDevice: (onLog = (->), transportHint = 'serial') ->
    set { detecting: true, lastError: null }
    try
      device = await detectDevice onLog, transportHint
      set { device, transport: transportHint, detecting: false }
      device
    catch e
      set { detecting: false, lastError: e.message }
      throw e

  disconnect: ->
    clearDevice()
    set { transport: 'sim', device: DEFAULT_DEVICE }

export default useFirmwareStore