import { describe, it, expect, afterEach, vi } from 'vitest'
import {
  readConnectedServoConfigurations
  writeConnectedServoConfiguration
  handFirmwarePortToFlasher
  enterCli, leaveCli, writeCliBytes
} from '../hooks/useFirmwareConnection.coffee'

makeFakeSerialPort = ->
  writer = { write: vi.fn ->, close: vi.fn -> }
  {
    getInfo: -> { usbVendorId: 0x0483, usbProductId: 0x5740 }
    open: vi.fn -> Promise.resolve()
    readable:
      getReader: -> { read: vi.fn -> new Promise (->), cancel: vi.fn ->, releaseLock: vi.fn -> }
    writable: getWriter: -> writer
    close: vi.fn -> Promise.resolve()
  }

openDirectCli = (port) ->
  navigator.serial = {
    requestPort: vi.fn -> Promise.resolve port
    addEventListener: vi.fn ->
    removeEventListener: vi.fn ->
  }
  await enterCli (->), null

describe 'useFirmwareConnection — servo configuration guards', ->
  it 'refuses to read servo configurations without a connection', ->
    await expect(readConnectedServoConfigurations()).rejects.toThrow(
      'No flight controller is connected'
    )

  it 'refuses to write a servo configuration without a connection', ->
    await expect(writeConnectedServoConfiguration 0, {}).rejects.toThrow(
      'No flight controller is connected'
    )

  it 'refuses to hand the port to the flasher without a connection', ->
    await expect(handFirmwarePortToFlasher()).rejects.toThrow(
      'No flight controller is connected'
    )

describe 'useFirmwareConnection — direct CLI channel', ->
  afterEach ->
    vi.useRealTimers()
    await leaveCli()

  it 'opens a dedicated port and sends the CLI # without an MSP session', ->
    port = makeFakeSerialPort()
    await openDirectCli port
    writer = port.writable.getWriter()
    expect(port.open).toHaveBeenCalledWith
      baudRate: 115200
      dataBits: 8
      stopBits: 1
      parity: 'none'
      flowControl: 'none'
    expect(writer.write).toHaveBeenCalledWith new Uint8Array [0x23]

  it 'routes CLI writes to the direct port', ->
    port = makeFakeSerialPort()
    await openDirectCli port
    await writeCliBytes new TextEncoder().encode 'help'
    writer = port.writable.getWriter()
    expect(writer.write).toHaveBeenLastCalledWith(
      new TextEncoder().encode 'help'
    )

  it 'closes the direct port when the CLI channel is released', ->
    port = makeFakeSerialPort()
    await openDirectCli port
    await leaveCli()
    expect(port.close).toHaveBeenCalled()