import { describe, it, expect } from 'vitest'
import {
  asBytes, crc8DvbS2, encodeMspV2, MspV2Parser, MspCrcError
  HEADER_SIZE, FRAME_OVERHEAD
} from '../protocol/mspCodec.coffee'

toFrame = (bytes) -> new MspV2Parser().push(bytes)[0]

describe 'mspCodec', ->
  it 'encodes an MSPv2 frame with header, command, length and CRC', ->
    frame = encodeMspV2 0x0413, [0xAA, 0xBB, 0xCC]
    expect(Array.from frame[0...2]).toEqual [0x24, 0x58]
    expect(String.fromCharCode frame[2]).toBe '<'
    expect(frame[3]).toBe 0
    expect(frame[4]).toBe 0x13
    expect(frame[5]).toBe 0x04
    expect(frame[6]).toBe 3
    expect(frame[7]).toBe 0
    expect(frame.length).toBe 3 + FRAME_OVERHEAD
    # CRC covers flags..payload — recompute and compare
    crc = 0
    for index in [3...HEADER_SIZE + 3]
      crc = crc8DvbS2 crc, frame[index]
    expect(frame[frame.length - 1]).toBe crc

  it 'round-trips command, direction, flags and payload', ->
    payload = Uint8Array.from [1, 2, 3, 4]
    frame = encodeMspV2 42, payload, '>', 0x80
    parsed = toFrame frame
    expect(parsed.command).toBe 42
    expect(parsed.direction).toBe '>'
    expect(parsed.flags).toBe 0x80
    expect(Array.from parsed.payload).toEqual [1, 2, 3, 4]

  it 'rejects out-of-range commands and invalid directions', ->
    expect((-> encodeMspV2(-1))).toThrow RangeError
    expect((-> encodeMspV2(0x10000))).toThrow RangeError
    expect((-> encodeMspV2 1, [], '?')).toThrow TypeError

  it 'normalizes Array, Uint8Array and ArrayBuffer payloads', ->
    fromArray = encodeMspV2 1, [9]
    fromTyped = encodeMspV2 1, Uint8Array.from [9]
    fromBuffer = encodeMspV2 1, Uint8Array.from([9]).buffer
    expect(Array.from fromArray).toEqual Array.from fromTyped
    expect(Array.from fromArray).toEqual Array.from fromBuffer
    expect(asBytes([1, 2])).toBeInstanceOf Uint8Array

  it 'delivers a frame only once all bytes arrived', ->
    frame = encodeMspV2 7, [0x10, 0x20]
    parser = new MspV2Parser()
    for index in [0...frame.length - 1]
      expect(parser.push(frame.subarray(index, index + 1))).toEqual []
    received = parser.push(frame.subarray(frame.length - 1))[0]
    expect(received.command).toBe 7
    expect(Array.from received.payload).toEqual [0x10, 0x20]

  it 'parses multiple frames from a single chunk', ->
    first = encodeMspV2 1, [0xAA]
    second = encodeMspV2 2, [0xBB]
    merged = new Uint8Array first.length + second.length
    merged.set first
    merged.set second, first.length
    frames = new MspV2Parser().push merged
    expect(frames.map((frame) -> frame.command)).toEqual [1, 2]

  it 're-syncs on $X after garbage bytes', ->
    frame = encodeMspV2 5, [0x01]
    garbage = Uint8Array.from [0x00, 0xFF, 0x24, 0x59, 0x13]
    merged = new Uint8Array garbage.length + frame.length
    merged.set garbage
    merged.set frame, garbage.length
    frames = new MspV2Parser().push merged
    expect(frames.length).toBe 1
    expect(frames[0].command).toBe 5

  it 'reports a CRC mismatch as a MspCrcError frame', ->
    frame = encodeMspV2 9, [0x01, 0x02]
    corrupted = Uint8Array.from frame
    corrupted[corrupted.length - 1] ^= 0xFF
    parsed = toFrame corrupted
    expect(parsed.error).toBeInstanceOf MspCrcError
    expect(parsed.command).toBe 9

  it 'keeps a trailing partial $X for the next chunk', ->
    frame = encodeMspV2 3, [0x07]
    parser = new MspV2Parser()
    expect(parser.push Uint8Array.from([0x24])).toEqual []
    frames = parser.push frame
    expect(frames.length).toBe 1
    expect(frames[0].command).toBe 3

  it 'skips an invalid direction byte and recovers', ->
    frame = encodeMspV2 4, [0x21]
    bad = Uint8Array.from [0x24, 0x58, 0x3F] # '?' is not a direction
    merged = new Uint8Array bad.length + frame.length
    merged.set bad
    merged.set frame, bad.length
    frames = new MspV2Parser().push merged
    expect(frames.length).toBe 1
    expect(frames[0].command).toBe 4
