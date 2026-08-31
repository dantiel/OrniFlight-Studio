###
# ORNIFLIGHT STUDIO — Firmware Flash Service (dispatcher)
#
# Single run()/reboot() surface for the flash controller. Routes to
# WebSerial (USART bootloader) or WebUSB (DFU mode) when detected,
# otherwise falls back to simulation (dry-run). Holds the device
# reference for the session.
###
import {
  run as runSimulation, reboot as rebootSimulation
} from './simulationTransport.coffee'
import * as serial from './serialTransport.coffee'
import * as webusb from './webUsbTransport.coffee'

device = null  # Either WebSerial port or WebUSB device
transport = null  # 'serial', 'webusb', or null

setDevice = (d, t) ->
  device = d
  transport = t

clearDevice = ->
  device = null
  transport = null

getDevice = -> { device, transport }

run = (actor, fw, options = {}, onLog = (->)) ->
  if transport is 'serial' and device
    serial.run actor, fw, options, onLog, device
  else if transport is 'webusb' and device
    webusb.run actor, fw, options, onLog, device
  else
    runSimulation actor, fw, options, onLog

reboot = (actor, onLog = (->)) ->
  if transport is 'serial' and device
    serial.reboot actor, onLog, device
  else if transport is 'webusb' and device
    webusb.reboot actor, onLog, device
  else
    rebootSimulation actor, onLog

# Detect a board over WebSerial (USART bootloader) or WebUSB (DFU mode).
# Preference: WebSerial first, fallback to WebUSB if user selects it.
detectSerial = (onLog = (->)) ->
  p = await serial.requestPort()
  info = await serial.detect p, onLog
  setDevice p, 'serial'
  info

detectWebUsb = (onLog = (->)) ->
  d = await webusb.requestDevice()
  info = await webusb.detect d, onLog
  setDevice d, 'webusb'
  info

detectDevice = (onLog = (->), transportHint = 'serial') ->
  if transportHint is 'webusb'
    await detectWebUsb onLog
  else
    await detectSerial onLog

isSerialSupported = -> serial.isSupported()
isWebUsbSupported = -> webusb.isSupported()

export {
  run, reboot
  detectDevice, detectSerial, detectWebUsb
  isSerialSupported, isWebUsbSupported
  setDevice, clearDevice, getDevice
}