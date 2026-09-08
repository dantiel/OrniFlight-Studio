import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import PortsView from '../components/views/PortsView/PortsView.coffee'
import usePortsStore from '../stores/usePortsStore.coffee'
import { FUNCTION_MSP, FUNCTION_GPS } from '../lib/serialCatalog.coffee'

describe 'PortsView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    usePortsStore.getState().reset()

  afterEach -> vi.restoreAllMocks()

  it 'renders port rows with checkboxes and sim badge', ->
    render h PortsView, null
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'UART Ports').toBeInTheDocument()
    expect(screen.getByText 'UART1').toBeInTheDocument()
    expect(screen.getByText 'USB VCP').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeDisabled()
    expect(screen.getAllByRole 'checkbox').toHaveLength 12

  it 'toggles a function with firmware arbitration', ->
    render h PortsView, null
    boxes = screen.getAllByRole 'checkbox'
    expect(boxes[0].checked).toBe true   # UART1 · MSP
    fireEvent.click boxes[4]             # UART1 · GPS
    port = usePortsStore.getState().draft
      .find (p) -> p.identifier == 0
    expect(port.functionMask).toBe FUNCTION_GPS
    expect(screen.getByText 'DIRTY').toBeInTheDocument()
    # arbitration cleared MSP in the row
    row = document.querySelectorAll('.port-row')[0]
    expect(
        row.querySelectorAll('input[type="checkbox"]:checked')
      ).toHaveLength 1

  it 'unchecks a function without touching the rest', ->
    render h PortsView, null
    boxes = screen.getAllByRole 'checkbox'
    fireEvent.click boxes[0]             # UART1 · MSP off
    port = usePortsStore.getState().draft
      .find (p) -> p.identifier == 0
    expect(port.functionMask).toBe 0
    expect(usePortsStore.getState().draft[1].functionMask)
      .toBe FUNCTION_MSP

  it 'updates a baud select through the store', ->
    render h PortsView, null
    row = document.querySelectorAll('.port-row')[0]
    selects = row.querySelectorAll '.port-baud-select'
    fireEvent.change selects[0], { target: { value: '3' } }
    port = usePortsStore.getState().draft
      .find (p) -> p.identifier == 0
    expect(port.mspBaud).toBe 3
