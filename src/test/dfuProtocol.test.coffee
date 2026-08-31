import { describe, it, expect } from 'vitest'
import * as dfu from '../firmware/dfuProtocol.coffee'

# A scripted port: each read() consumes the next scripted chunk,
# truncating/padding to the requested count. write() is recorded.
mockPort = (script = []) ->
  i = 0
  calls = { writes: [] }
  port =
    read: (count) ->
      chunk = script[i++] or new Uint8Array count
      out = new Uint8Array count
      out.set chunk.subarray 0, Math.min count, chunk.length
      Promise.resolve out
    write: (bytes) ->
      calls.writes.push Array.from bytes
      Promise.resolve()
  { port, calls }

ACK = Uint8Array.from [dfu.ACK]

describe 'dfuProtocol', ->
  it 'syncs with a single 0x7F and ACK', ->
    { port, calls } = mockPort [ACK]
    r = await dfu.sync port
    expect(r.ok).toBe true
    expect(calls.writes[0]).toEqual [0x7F]

  it 'decodes the device ID little-endian', ->
    n2 = Uint8Array.from [2]
    pid = Uint8Array.from [0x13, 0x04]
    { port } = mockPort [ACK, n2, pid, ACK]
    r = await dfu.getDeviceId port
    expect(r.unwrap()).toBe 0x0413

  it 'frames writeMemory with address and body checksums', ->
    { port, calls } = mockPort [ACK, ACK, ACK]
    data = Uint8Array.from [0xAA, 0xBB]
    r = await dfu.writeMemory port, 0x08000000, data
    expect(r.ok).toBe true
    # command 0x31 + complement
    expect(calls.writes[0]).toEqual [0x31, 0xCE]
    # address 0x08000000 + xor(0x08,0x00,0x00,0x00)
    expect(calls.writes[1]).toEqual [0x08, 0x00, 0x00, 0x00, 0x08]
    # N=1, data, checksum = 0x01 ^ 0xAA ^ 0xBB
    expect(calls.writes[2]).toEqual [0x01, 0xAA, 0xBB, 0x10]

  it 'returns Err on a NACK', ->
    { port } = mockPort [Uint8Array.from [dfu.NACK]]
    r = await dfu.sync port
    expect(r.ok).toBe false

  it 'covers image size with the right sector count', ->
    expect(dfu.sectorsFor(0x413, 262144)).toEqual [0, 1, 2, 3, 4, 5]
    expect(dfu.sectorsFor(0x413, 1)).toEqual [0]
    expect(dfu.sectorsFor(0x9999, 262144)).toEqual [0, 1]

  it 'maps known chip IDs to friendly names', ->
    expect(dfu.CHIP_IDS[0x413].mcu).toBe 'STM32F405RGT6'
    expect(dfu.CHIP_IDS[0x452].target).toBe 'ORNI-F7'
