import { describe, it, expect } from 'vitest'
import {
  parseCatalog, normalizeFirmware, fmtBytes, localFirmware, sha256Hex
} from '../firmware/firmwareCatalog.coffee'

describe 'firmwareCatalog', ->
  it 'normalizes a raw entry with an id key', ->
    fw = normalizeFirmware { target: 'ORNI-F4', version: '2.1.0', name: 'OrniFlight' }
    expect(fw.id).toBe 'ORNI-F4@2.1.0'
    expect(fw.channel).toBe 'stable'

  it 'sorts catalog by version descending', ->
    result = parseCatalog { images: [
      { target: 'ORNI-F4', version: '2.0.0' }
      { target: 'ORNI-F4', version: '2.1.0' }
    ] }
    versions = result.unwrap().map (f) -> f.version
    expect(versions).toEqual ['2.1.0', '2.0.0']

  it 'returns Err on empty manifest', ->
    result = parseCatalog { images: [] }
    expect(result.ok).toBe false

  it 'formats byte sizes', ->
    expect(fmtBytes(512)).toBe '512 B'
    expect(fmtBytes(262144)).toBe '256.0 KB'

  it 'builds a local firmware descriptor from a file', ->
    bytes = new Uint8Array [0x01, 0x02, 0x03]
    fw = localFirmware { name: 'custom-fw.bin' }, bytes, 'abc123'
    expect(fw.id).toBe 'local'
    expect(fw.name).toBe 'custom-fw'
    expect(fw.channel).toBe 'local'
    expect(fw.size).toBe 3
    expect(fw.sha256).toBe 'abc123'
    expect(fw.bytes).toBe bytes

  it 'computes a 64-char sha256 hex digest', ->
    digest = await sha256Hex new Uint8Array [1, 2, 3]
    expect(digest).toMatch /^[0-9a-f]{64}$/