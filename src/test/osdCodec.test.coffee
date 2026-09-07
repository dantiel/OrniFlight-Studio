import { describe, it, expect } from 'vitest'
import { decodeOsdConfig, encodeOsdItem } from '../protocol/mspDecoders.coffee'
import { OSD_ITEM_COUNT, OSD_DEFAULTS, itemPos, posCell } from '../lib/osdCatalog.coffee'

u16 = (value) -> [value & 0xff, value >>> 8 & 0xff]
u32 = (value) -> [value & 0xff, value >>> 8 & 0xff, value >>> 16 & 0xff, value >>> 24 & 0xff]

# Builds a full MSP_OSD_CONFIG payload matching the firmware wire layout:
# header (u8 flags/video/units/rssiAlarm, u16 capAlarm, u8 reserved,
# u8 itemCount, u16 altAlarm) → itemCount × u16 → adaptive trailer
# (statCount+stats, timerCount+timers, warningsLow, warningCount,
# warningsFull, profileCount, profileIndex, overlayRadioMode).
osdWirePayload = (items, trailer = {}) ->
  bytes = []
  bytes.push 0x01, 0x02, 0x03, 0x40
  bytes.push u16(0x0123)...
  bytes.push 0x00
  bytes.push items.length
  bytes.push u16(0x0456)...
  for pos in items
    bytes.push u16(pos)...
  bytes.push 0x00             # statCount
  bytes.push 0x00             # timerCount
  bytes.push u16(0x0000)...   # warningsLow
  bytes.push 0x00             # warningCount
  bytes.push u32(0x00000000)... # warningsFull
  bytes.push trailer.profileCount ? 3
  bytes.push trailer.profileIndex ? 1
  bytes.push trailer.overlayRadioMode ? 0
  bytes

describe 'OSD codec (wire)', ->
  it 'encodes an OSD item as [index, lo, hi, screen=1]', ->
    pos = itemPos 15, 8
    expect(Array.from encodeOsdItem(21, pos)).toEqual [
      21, pos & 0xff, pos >>> 8 & 0xff, 1
    ]

  it 'round-trips a full 52-slot config through the wire layout', ->
    items = (itemPos(i % 30, Math.floor(i / 30)) for i in [0...OSD_ITEM_COUNT])
    items[21] = itemPos 15, 8
    items[2] = itemPos 13, 6
    decoded = decodeOsdConfig osdWirePayload(
      items, { profileIndex: 2, profileCount: 3, overlayRadioMode: 4 }
    )
    expect(decoded.osdFlags).toBe 0x01
    expect(decoded.videoSystem).toBe 0x02
    expect(decoded.units).toBe 0x03
    expect(decoded.rssiAlarm).toBe 0x40
    expect(decoded.capAlarm).toBe 0x0123
    expect(decoded.altAlarm).toBe 0x0456
    expect(decoded.items).toHaveLength OSD_ITEM_COUNT
    expect(posCell decoded.items[21]).toEqual { x: 15, y: 8 }
    expect(posCell decoded.items[2]).toEqual { x: 13, y: 6 }
    expect(decoded.profileCount).toBe 3
    expect(decoded.profileIndex).toBe 2
    expect(decoded.overlayRadioMode).toBe 4

  it 'clamps an oversized item count to 52 slots', ->
    items = (itemPos(0, 0) for i in [0...OSD_ITEM_COUNT])
    payload = []
    payload.push 0x00, 0x00, 0x00, 0x00
    payload.push u16(0)...
    payload.push 0x00
    payload.push 60            # bogus itemCount beyond the enum
    payload.push u16(0)...
    for pos in items
      payload.push u16(pos)...
    expect(decodeOsdConfig(payload).items).toHaveLength OSD_ITEM_COUNT

  it 'fills missing slots with firmware defaults on truncation', ->
    # Header only: itemCount = 2 but no item bytes follow, and the
    # trailer is absent — the codec must back-fill all 52 slots.
    decoded = decodeOsdConfig [0, 0, 0, 0, 0, 0, 0, 2, 0, 0]
    expect(decoded.items).toHaveLength OSD_ITEM_COUNT
    expect(posCell decoded.items[2]).toEqual { x: 13, y: 6 }
    expect(decoded.profileIndex).toBe 1
    expect(decoded.profileCount).toBe 3

  it 'degrades to defaults on an empty payload instead of throwing', ->
    decoded = decodeOsdConfig []
    expect(decoded.items).toHaveLength OSD_ITEM_COUNT
    expect(decoded.items[21]).toBe OSD_DEFAULTS[21]
    expect(decoded.profileIndex).toBe 1
    expect(decoded.profileCount).toBe 3

  it 'degrades to defaults on a header shorter than 10 bytes', ->
    decoded = decodeOsdConfig [0x01, 0x02, 0x03]
    expect(decoded.items).toHaveLength OSD_ITEM_COUNT
    expect(decoded.osdFlags).toBe 0
    expect(posCell decoded.items[3]).toEqual posCell OSD_DEFAULTS[3]

  it 'masks an out-of-range item index into a single byte', ->
    expect(encodeOsdItem(300, itemPos(1, 1))[0]).toBe 300 & 0xFF
    expect(encodeOsdItem(-1, itemPos(1, 1))[0]).toBe 255