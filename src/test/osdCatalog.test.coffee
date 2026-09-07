import { describe, it, expect } from 'vitest'
import {
  GRID_COLS, GRID_ROWS, OSD_ITEM_COUNT, OSD_PROFILE_COUNT
  POSITION_XY_MASK, PROFILE_MASK, POSITION_MASK
  itemPos, posX, posY, posCell, clampCell, cellFromPointer, movePos
  sanitizePos, profileFlag, visibleInProfile, visibilityMask
  setVisibleInProfile, toggleVisibleInProfile, isVisible, findFreeCell
  OSD_ITEMS, OSD_DEFAULTS
} from '../lib/osdCatalog.coffee'

describe 'osdCatalog codec', ->
  it 'packs and unpacks cells losslessly', ->
    for x in [0, 5, 29]
      for y in [0, 7, 15]
        expect(itemPos x, y).toBe x | y << 5
        expect(posCell itemPos(x, y)).toEqual { x, y }

  it 'exposes x and y extractors matching the firmware macros', ->
    pos = itemPos 13, 6
    expect(posX pos).toBe 13
    expect(posY pos).toBe 6

  it 'matches the firmware wire constants', ->
    expect(POSITION_XY_MASK).toBe 31
    expect(PROFILE_MASK).toBe 0x3800
    expect(POSITION_MASK).toBe 0x3FF

  it 'clamps cells into the visible 30x16 grid', ->
    expect(clampCell(-3, 99)).toEqual { x: 0, y: 15 }
    expect(clampCell(50, -1)).toEqual { x: 29, y: 0 }
    expect(clampCell(NaN, 4)).toEqual { x: 0, y: 4 }
    expect(clampCell(7.6, 3.4)).toEqual { x: 8, y: 3 }

  it 'maps pointer coordinates onto grid cells', ->
    rect = { left: 100, top: 200, width: 600, height: 320 }
    expect(cellFromPointer(100, 200, rect)).toEqual { x: 0, y: 0 }
    expect(cellFromPointer(700, 520, rect)).toEqual { x: 29, y: 15 }
    expect(cellFromPointer(101, 201, rect)).toEqual { x: 0, y: 0 }
    expect(cellFromPointer(100, 200, { width: 0, height: 0 })).toEqual(
      { x: 0, y: 0 }
    )

  it 'exposes profile flags with bit SET meaning visible', ->
    expect(profileFlag 1).toBe 0x0800
    expect(profileFlag 2).toBe 0x1000
    expect(profileFlag 3).toBe 0x2000
    pos = itemPos 10, 7
    expect(visibleInProfile pos, 1).toBe false
    pos = setVisibleInProfile pos, 2, true
    expect(visibleInProfile pos, 2).toBe true
    expect(visibleInProfile pos, 1).toBe false
    expect(visibilityMask pos).toBe 0x1000
    expect(toggleVisibleInProfile pos, 2).toBe itemPos 10, 7

  it 'moves a cell while preserving visibility flags', ->
    pos = setVisibleInProfile itemPos(2, 3), 1, true
    moved = movePos pos, 20, 10
    expect(posCell moved).toEqual { x: 20, y: 10 }
    expect(visibleInProfile moved, 1).toBe true

  it 'sanitizes bits the wire format does not define', ->
    expect(sanitizePos 0xFFFF).toBe 0x3BFF
    expect(sanitizePos 0xC000).toBe 0x0000

  it 'registers all 52 firmware elements in enum order', ->
    expect(OSD_ITEMS.length).toBe OSD_ITEM_COUNT
    expect(OSD_ITEMS[0].key).toBe 'RSSI_VALUE'
    expect(OSD_ITEMS[21].key).toBe 'WARNINGS'
    expect(OSD_ITEMS[48].key).toBe 'STICK_OVERLAY_LEFT'
    expect(OSD_ITEMS[51].key).toBe 'ESC_RPM_FREQ'
    for item, i in OSD_ITEMS
      expect(item.index).toBe i

  it 'mirrors the firmware default positions', ->
    expect(OSD_DEFAULTS.length).toBe OSD_ITEM_COUNT
    expect(OSD_DEFAULTS[2]).toBe itemPos 13, 6
    expect(OSD_DEFAULTS[3]).toBe itemPos 14, 2
    expect(OSD_DEFAULTS[4]).toBe itemPos 14, 6
    expect(OSD_DEFAULTS[21]).toBe itemPos(9, 10) | PROFILE_MASK
    for i in [0...OSD_ITEM_COUNT]
      continue if i in [2, 3, 4, 21]
      expect(OSD_DEFAULTS[i]).toBe itemPos 10, 7

  it 'reports isVisible only when a profile bit is set', ->
    expect(isVisible itemPos(1, 1)).toBe false
    expect(isVisible setVisibleInProfile(itemPos(1, 1), 3, true)).toBe true

  it 'finds the first free cell', ->
    expect(findFreeCell OSD_DEFAULTS).toEqual { x: 0, y: 0 }
    full = (itemPos x % GRID_COLS, Math.floor(x / GRID_COLS) for x in [0...480])
    expect(findFreeCell full).toBe null
