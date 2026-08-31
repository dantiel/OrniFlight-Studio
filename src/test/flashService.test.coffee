import { describe, it, expect, vi, beforeEach } from 'vitest'

vi.mock '../firmware/simulationTransport.coffee', ->
  {
    run: vi.fn -> Promise.resolve 'sim-run'
    reboot: vi.fn -> Promise.resolve 'sim-reboot'
  }

vi.mock '../firmware/serialTransport.coffee', ->
  {
    run: vi.fn -> Promise.resolve 'serial-run'
    reboot: vi.fn -> Promise.resolve 'serial-reboot'
    requestPort: vi.fn -> Promise.resolve { fake: true }
    detect: vi.fn -> Promise.resolve { mcu: 'STM32F405RGT6' }
    isSupported: -> true
  }

vi.mock '../firmware/webUsbTransport.coffee', ->
  {
    run: vi.fn -> Promise.resolve 'webusb-run'
    reboot: vi.fn -> Promise.resolve 'webusb-reboot'
    requestDevice: vi.fn -> Promise.resolve { usb: true }
    detect: vi.fn -> Promise.resolve { mcu: 'STM32F303' }
    isSupported: -> true
  }

import {
  run, reboot, detectDevice, detectSerial, detectWebUsb
  setDevice, clearDevice, getDevice
  isSerialSupported, isWebUsbSupported
} from '../firmware/flashService.coffee'

describe 'flashService dispatcher', ->
  beforeEach ->
    clearDevice()

  it 'routes to simulation when no device is set', ->
    expect(await run({}, { name: 'fw' })).toBe 'sim-run'
    expect(await reboot({})).toBe 'sim-reboot'

  it 'routes to serial when a serial port has been detected', ->
    setDevice { fake: true }, 'serial'
    expect(await run({}, { name: 'fw' })).toBe 'serial-run'
    expect(await reboot({})).toBe 'serial-reboot'

  it 'routes to webusb when a USB device has been detected', ->
    setDevice { usb: true }, 'webusb'
    expect(await run({}, { name: 'fw' })).toBe 'webusb-run'
    expect(await reboot({})).toBe 'webusb-reboot'

  it 'detectSerial stores the device and returns device info', ->
    info = await detectSerial()
    expect(info.mcu).toBe 'STM32F405RGT6'
    { device, transport } = getDevice()
    expect(device).toEqual { fake: true }
    expect(transport).toBe 'serial'

  it 'detectWebUsb stores the device and returns device info', ->
    info = await detectWebUsb()
    expect(info.mcu).toBe 'STM32F303'
    { device, transport } = getDevice()
    expect(device).toEqual { usb: true }
    expect(transport).toBe 'webusb'

  it 'reports WebSerial support from the transport', ->
    expect(isSerialSupported()).toBe true

  it 'reports WebUSB support from the transport', ->
    expect(isWebUsbSupported()).toBe true
