import { describe, it, expect, vi } from 'vitest'
import { getDeviceId } from '../firmware/dfuUsbProtocol.coffee'

# A WebUSB device fake: controlTransferOut answers 'ok', and
# controlTransferIn routes GETSTATUS (request 3) → DFU_IDLE and
# UPLOAD (request 2) → the supplied GETID response bytes.
makeFakeDfuDevice = (uploadBytes) ->
  controlTransferOut: vi.fn -> Promise.resolve { status: 'ok' }
  controlTransferIn: vi.fn (params) ->
    if params.request is 3
      Promise.resolve { status: 'ok', data: new Uint8Array [0x00, 0x00, 0x00, 0x00, 0x02] }
    else if params.request is 2
      Promise.resolve { status: 'ok', data: new Uint8Array uploadBytes }
    else
      Promise.resolve { status: 'ok', data: new Uint8Array [0x00] }

describe 'dfuUsbProtocol · DfuSe GETID', ->
  it 'reads the F405 product ID from a standard GETID response', ->
    device = makeFakeDfuDevice [0x01, 0x13, 0x04, 0x01]
    r = await getDeviceId device
    expect(r.ok).toBe true
    expect(r.value).toBe 0x413
    call = device.controlTransferOut.mock.calls[0]
    expect(call[0]).toEqual
      requestType: 'class'
      recipient: 'interface'
      request: 1
      value: 0
      index: 0
      length: 1
    expect(Array.from call[1]).toEqual [0x02]

  it 'tolerates a GETID response without the length byte', ->
    device = makeFakeDfuDevice [0x31, 0x04]
    r = await getDeviceId device
    expect(r.ok).toBe true
    expect(r.value).toBe 0x431

  it 'fails cleanly on an unrecognised GETID response', ->
    device = makeFakeDfuDevice [0xFF, 0xFF, 0xFF, 0xFF]
    r = await getDeviceId device
    expect(r.ok).toBe false
    expect(r.error).toMatch /unrecognised GETID/
