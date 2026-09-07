import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import OsdEditorView from '../components/views/OsdEditorView/OsdEditorView.coffee'
import useOsdStore from '../stores/useOsdStore.coffee'
import { itemPos, posCell, visibleInProfile } from '../lib/osdCatalog.coffee'

GRID_RECT =
  left: 0, top: 0, right: 300, bottom: 160
  width: 300, height: 160, x: 0, y: 0

pointerEvent = (type, clientX, clientY) ->
  event = new Event type, { bubbles: true, cancelable: true }
  Object.defineProperty event, 'clientX', { value: clientX }
  Object.defineProperty event, 'clientY', { value: clientY }
  event

describe 'OsdEditorView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useOsdStore.getState().reset()

  afterEach ->
    vi.restoreAllMocks()

  renderView = ->
    render h(OsdEditorView, null)

  gridEl = -> document.querySelector '.osd-grid'

  it 'renders palette, grid and toolbar in sim mode', ->
    renderView()
    expect(gridEl()).toBeInTheDocument()
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Elements').toBeInTheDocument()
    expect(screen.getByText 'Properties').toBeInTheDocument()
    expect(screen.getByText 'Save').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeDisabled()
    for label in ['RSSI', 'Altitude', 'Timer 1', 'Stick left']
      expect(screen.getAllByText(label).length).toBeGreaterThan 0

  it 'renders only the visible elements on the grid', ->
    renderView()
    # Firmware default: WARNINGS is the only element visible in profile 1.
    # The palette lists every element, so scope the query to the grid.
    expect(document.querySelectorAll '.osd-item').toHaveLength 1
    itemEl = document.querySelector '.osd-item'
    expect(itemEl?.textContent).toContain 'Warnings'

  it 'places an element when clicked in the palette', ->
    renderView()
    fireEvent.click screen.getAllByText('Altitude')[0].closest 'button'
    draft = useOsdStore.getState().draft
    expect(visibleInProfile draft[15], 1).toBe true
    expect(posCell draft[15]).toEqual { x: 0, y: 0 }
    expect(useOsdStore.getState().dirty).toBe true

  it 'selects an element on pointer press without moving it', ->
    renderView()
    gridEl().getBoundingClientRect = -> GRID_RECT
    item = document.querySelector '.osd-item'  # WARNINGS at (9,10)
    fireEvent item, pointerEvent('pointerdown', 95, 105)
    fireEvent item, pointerEvent('pointerup', 95, 105)
    expect(document.querySelector '.osd-props-name').toBeInTheDocument()
    expect(useOsdStore.getState().dragState).toBe null
    expect(useOsdStore.getState().dirty).toBe false

  it 'drags a grid element to a new cell with pointer events', ->
    renderView()
    gridEl().getBoundingClientRect = -> GRID_RECT
    item = document.querySelector '.osd-item'  # WARNINGS at (9,10)
    fireEvent item, pointerEvent('pointerdown', 95, 105)
    fireEvent item, pointerEvent('pointermove', 150, 80)
    fireEvent item, pointerEvent('pointerup', 150, 80)
    draft = useOsdStore.getState().draft
    expect(draft[21] & 0x3FF).toBe itemPos 15, 8
    expect(visibleInProfile draft[21], 1).toBe true
    expect(useOsdStore.getState().dirty).toBe true

  it 'restores the origin when a drag is cancelled', ->
    renderView()
    gridEl().getBoundingClientRect = -> GRID_RECT
    item = document.querySelector '.osd-item'
    fireEvent item, pointerEvent('pointerdown', 95, 105)
    fireEvent item, pointerEvent('pointermove', 250, 150)
    fireEvent item, new Event('pointercancel', { bubbles: true })
    draft = useOsdStore.getState().draft
    expect(draft[21] & 0x3FF).toBe itemPos 9, 10
    expect(useOsdStore.getState().dragState).toBe null
    expect(useOsdStore.getState().dirty).toBe false

  it 'edits the selected element position through the props panel', ->
    renderView()
    gridEl().getBoundingClientRect = -> GRID_RECT
    item = document.querySelector '.osd-item'
    fireEvent item, pointerEvent('pointerdown', 95, 105)
    fireEvent item, pointerEvent('pointerup', 95, 105)
    inputs = document.querySelectorAll '.osd-props-field input'
    fireEvent.change inputs[0], { target: { value: '21' } }
    fireEvent.change inputs[1], { target: { value: '9' } }
    expect(posCell useOsdStore.getState().draft[21]).toEqual { x: 21, y: 9 }

  it 'toggles visibility through the props panel checkboxes', ->
    renderView()
    gridEl().getBoundingClientRect = -> GRID_RECT
    item = document.querySelector '.osd-item'
    fireEvent item, pointerEvent('pointerdown', 95, 105)
    fireEvent item, pointerEvent('pointerup', 95, 105)
    boxes = document.querySelectorAll '.osd-props-check input'
    expect(boxes[0].checked).toBe true
    fireEvent.click boxes[0]
    expect(visibleInProfile useOsdStore.getState().draft[21], 1).toBe false
    expect(document.querySelectorAll '.osd-item').toHaveLength 0

  it 'switches the active profile', ->
    renderView()
    select = document.querySelector '#osd-profile'
    fireEvent.change select, { target: { value: '2' } }
    expect(useOsdStore.getState().profileIndex).toBe 2