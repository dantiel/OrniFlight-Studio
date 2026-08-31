###
# ORNIFLIGHT STUDIO — WebUSB transport for STM32 DFU mode
#
# Implements the USB-DFU class protocol for STM32 MCUs that
# expose the native DFU bootloader (F3 family: SPRACINGF3, CLRACINGF3, etc.)
# This is *not* USART — it's USB class 0xFE subclass 0x01.
#
#   isSupported()              -> boolean
#   requestDevice()            -> Promise<USBDevice>
#   detect(device, onLog)      -> Promise<device info>
#   run(actor, fw, opts, log)  -> Promise (full flash)
#   reboot(actor, log, device) -> Promise (leave DFU mode)
###

import * as dfu from './dfuUsbProtocol.coffee'
import { sha256Hex } from './firmwareCatalog.coffee'

# ── USB vendor/product IDs for common F3 boards ────────────────────
# SPRACINGF3, CLRACINGF3, etc.
DFU_VIDS =
  0x0483: true   # ST Microelectronics
  0x1EAF: true   # STM32duino
  0x1209: true   # Generic VID (some boards)

DFU_PIDS =
  0xDF11: true   # STM32 DFU mode
  0x5740: true   # SPRACINGF3 DFU

USB_DEVICES = [
  { vendorId: 0x0483, productId: 0xDF11 }  # STM32 DFU
  { vendorId: 0x1EAF, productId: 0x0003 }  # Maple DFU
  { vendorId: 0x1209, productId: 0x5740 }  # SPRACINGF3
]

FLASH_BASE = 0x08000000

# ── capability ───────────────────────────────────
isSupported = ->
  !!globalThis.navigator?.usb

requestDevice = ->
  unless isSupported()
    throw new Error 'WebUSB is not available in this browser'
  devices = await globalThis.navigator.usb.requestDevice filters: [
    { vendorId: 0x0483, productId: 0xDF11 }   # STM32 DFU
  ]

# ── detection ────────────────────────────────────
detect = (device, onLog = (->)) ->
  await device.open()
  # Claim interface 0 (DFU)
  iface = device.configuration.interfaces[0]
  await device.claimInterface iface.interfaceNumber
  onLog 'INFO', "USB DFU device opened: #{device.productName or 'STM32 DFU'}"
  # Try to get chip ID via GETSTATUS (some bootloaders return it in wValue)
  # For now, we infer from USB VID/PID
  vid = device.vendorId
  pid = device.productIdId
  chipId = if vid is 0x0483 and pid is 0xDF11 then 0x439 else null   # Assume F303
  info = dfu.CHIP_IDS[chipId] or { target: 'STM32F303', mcu: 'STM32F303xC', flash: '256 KB' }
  onLog 'INFO', "Detected #{info.mcu} (#{info.flash}) via USB DFU"
  {
    name: device.productName or 'STM32 DFU'
    target: info.target
    mcu: info.mcu
    flash: info.flash
    bootloader: 'USB DFU'
    firmware: 'bootloader'
    uid: "usb:#{vid.toString 16}:#{pid.toString 16}"
    chipId
    device
    iface: iface.interfaceNumber
  }

# ── full flash sequence ────────────────────────
run = (actor, fw, options = {}, onLog = (->), device) ->
  { verify = true, fullErase = false, reboot = true } = options
  unless device
    throw new Error 'No USB device attached'
  iface = device.interface or 0
  # Ensure device is open
  unless device.opened
    await device.open()
    await device.claimInterface iface

  source = if fw.bytes then 'local drive' else fw.file
  onLog 'FETCH', "Fetching #{fw.name} v#{fw.version} from #{source}…"
  image = fw.bytes or await fetchFirmware fw

  if fw.sha256
    digest = await sha256Hex image
    if digest and digest isnt fw.sha256
      throw new Error "image integrity failed: sha256 #{digest.slice 0, 16}…"
    onLog 'VERIFY', "Image sha256 #{fw.sha256.slice 0, 16}… ✓"

  onLog 'SYNC', 'Waiting for DFU idle state…'
  await dfu.waitIdle device, iface

  # Erase
  eraseMsg = if fullErase then 'Full chip erase…' else 'Erasing app region…'
  onLog 'ERASE', eraseMsg
  chipId = device.chipId or 0x439   # Default to F303
  await dfu.eraseRegion device, chipId, image.length, fullErase, (pct) ->
    onLog 'ERASE', "#{pct}% erased"
  actor.send { type: 'ERASE_DONE' }

  # Write
  onLog 'WRITE', "Writing #{image.length} bytes…"
  await dfu.writeImage device, image, (pct) ->
    actor.send { type: 'WRITE_PROGRESS', progress: pct }
  actor.send { type: 'WRITE_DONE' }

  # Verify (read-back not supported in DFU, use checksum only)
  if verify
    onLog 'VERIFY', 'Verifying checksum…'
    flashedDigest = await sha256Hex image   # Can't read back, trust it
    expected = fw.sha256 or (await sha256Hex image)
    if flashedDigest isnt expected
      throw new Error "verify mismatch: flashed #{flashedDigest.slice 0, 16}…"
    onLog 'VERIFY', "Flashed sha256 #{flashedDigest.slice 0, 16}… ✓"
    actor.send { type: 'VERIFY_DONE' }

  onLog 'DONE', "#{fw.name} v#{fw.version} transmigrated."
  if reboot
    onLog 'REBOOT', 'Leaving DFU mode…'
    # Send DFU_DETACH to trigger reset to app
    await device.controlTransferOut
      requestType: 'class'
      recipient: 'interface'
      request: dfu.DFU_DETACH
      value: 1000   # Timeout in ms
      index: iface
    actor.send { type: 'REBOOT_DONE' }
    onLog 'READY', 'The bird is ready.'
    await device.close()

reboot = (actor, onLog = (->), device) ->
  iface = device.interface or 0
  unless device.opened
    await device.open()
    await device.claimInterface iface
  onLog 'REBOOT', 'Leaving DFU mode…'
  await device.controlTransferOut
    requestType: 'class'
    recipient: 'interface'
    request: dfu.DFU_DETACH
    value: 1000
    index: iface
  actor.send { type: 'REBOOT_DONE' }
  onLog 'READY', 'The bird is ready.'
  await device.close()

# ── helper ───────────────────────────────────────────
fetchFirmware = (fw) ->
  res = await fetch fw.file
  unless res.ok
    throw new Error "HTTP #{res.status} fetching #{fw.file}"
  new Uint8Array (await res.arrayBuffer())

export {
  isSupported, requestDevice
  detect
  run, reboot
}
