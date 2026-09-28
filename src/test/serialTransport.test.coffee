import { describe, it, expect, vi } from 'vitest'
import { openPort } from '../firmware/serialTransport.coffee'

makeFakePort = ->
  {
    open: vi.fn ->
    readable:
      getReader: -> { read: vi.fn -> new Promise (->) }
    writable:
      getWriter: -> { write: vi.fn ->, close: vi.fn -> }
    close: vi.fn ->
  }

describe 'serialTransport · AN3155 port negotiation', ->
  it 'opens the bootloader port 115200 8E1 (even parity)', ->
    port = makeFakePort()
    await openPort port
    expect(port.open).toHaveBeenCalledWith
      baudRate: 115200
      dataBits: 8
      stopBits: 1
      parity: 'even'
      flowControl: 'none'

  it 'honours an explicit baud rate while keeping 8E1', ->
    port = makeFakePort()
    await openPort port, 57600
    expect(port.open).toHaveBeenCalledWith
      baudRate: 57600
      dataBits: 8
      stopBits: 1
      parity: 'even'
      flowControl: 'none'
