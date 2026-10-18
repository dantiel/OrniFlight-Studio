import { describe, it, expect, vi } from 'vitest'
import {
  openPort, classifySerialOpenError
} from '../firmware/serialTransport.coffee'

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

  it 'retries a vanished port across the re-enumeration window', ->
    vi.useFakeTimers()
    try
      port = makeFakePort()
      port.open
        .mockImplementationOnce -> Promise.reject Object.assign new Error('Failed to open serial port'), { name: 'NetworkError' }
        .mockImplementationOnce -> Promise.reject Object.assign new Error('Failed to open serial port'), { name: 'NetworkError' }
      opening = openPort port
      await vi.advanceTimersByTimeAsync 1100
      await opening
      expect(port.open).toHaveBeenCalledTimes 3
    finally
      vi.useRealTimers()

  it 'classifies a NetworkError as a re-enumeration / contention hint', ->
    error = classifySerialOpenError Object.assign(
      new Error('Failed to open serial port'), { name: 'NetworkError' }
    )
    expect(error.message).toMatch /re-enumerated after reboot/
    expect(error.name).toBe 'NetworkError'