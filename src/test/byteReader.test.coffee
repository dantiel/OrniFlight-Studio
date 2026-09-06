import { describe, it, expect } from 'vitest'
import ByteReader from '../protocol/byteReader.coffee'

describe 'byteReader', ->
  it 'reads unsigned and signed little-endian integers', ->
    reader = new ByteReader [0xff, 0x80]
    expect(reader.u8()).toBe 0xff
    expect(reader.i8()).toBe -128
    expect(new ByteReader([0xff]).i8()).toBe -1

  it 'reads u16 and u32 at the little-endian boundaries', ->
    reader = new ByteReader [0xff, 0xff, 0x00, 0x00, 0x00, 0x80]
    expect(reader.u16()).toBe 0xffff
    expect(reader.u32()).toBe 0x80000000

  it "decodes negative i16 via two's complement", ->
    expect(new ByteReader([0x00, 0x80]).i16()).toBe -32768

  it 'reports how many bytes were missing on truncation', ->
    reader = new ByteReader [0x01, 0x02]
    expect((-> reader.u32())).toThrow 'MSP payload truncated: need 4, have 2'

  it 'throws RangeError when reading past an empty buffer', ->
    empty = new ByteReader []
    expect((-> empty.u8())).toThrow RangeError

  it 'exposes remaining() and take() at exact boundaries', ->
    reader = new ByteReader [1, 2, 3, 4]
    expect(reader.remaining()).toBe 4
    expect(Array.from reader.take(4)).toEqual [1, 2, 3, 4]
    expect(reader.remaining()).toBe 0

  it 'reads ascii and length-prefixed ascii', ->
    expect(new ByteReader([65, 66]).ascii(2)).toBe 'AB'
    expect(new ByteReader([3, 65, 66, 67]).lengthPrefixedAscii()).toBe 'ABC'

  it 'normalizes Array, Uint8Array and nil inputs', ->
    expect(new ByteReader([7]).u8()).toBe 7
    expect(new ByteReader(Uint8Array.from [9]).u8()).toBe 9
    expect(new ByteReader().remaining()).toBe 0
