import { describe, it, expect, vi } from 'vitest'
import WebSerialRuntimeTransport from '../transport/webSerialRuntimeTransport.coffee'

makePort = ->
  {
    getInfo: -> { usbVendorId: 0x0483, usbProductId: 0x5740 }
    open: vi.fn -> Promise.resolve()
    readable:
      getReader: -> {
        read: vi.fn -> new Promise (->)
        cancel: vi.fn -> Promise.resolve()
        releaseLock: vi.fn ->
      }
    writable:
      getWriter: -> { write: vi.fn ->, close: vi.fn -> }
    close: vi.fn -> Promise.resolve()
  }

describe 'webSerialRuntimeTransport', ->
  it 'opens the runtime port 115200 8N1', ->
    port = makePort()
    transport = new WebSerialRuntimeTransport port
    await transport.open()
    expect(port.open).toHaveBeenCalledWith
      baudRate: 115200
      dataBits: 8
      stopBits: 1
      parity: 'none'
      flowControl: 'none'
    await transport.close()

  it 'resolves open() while the read loop parks on reader.read()', ->
    # Regression: CoffeeScript's implicit return once made open()
    # return the read loop's never-settling promise — every await of
    # open() deadlocked until the port closed (connect hung forever).
    port = makePort()
    navigator.serial = {
      addEventListener: vi.fn ->
      removeEventListener: vi.fn ->
    }
    transport = new WebSerialRuntimeTransport port
    await transport.open()
    expect(port.readable.getReader).toBeDefined()
    await transport.close()
    expect(port.close).toHaveBeenCalled()
