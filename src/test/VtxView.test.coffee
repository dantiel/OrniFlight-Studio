import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import VtxView from '../components/views/VtxView/VtxView.coffee'
import useVtxStore from '../stores/useVtxStore.coffee'

describe 'VtxView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useVtxStore.getState().reset()

  afterEach -> vi.restoreAllMocks()

  it 'renders the band table, frequency and sim badge', ->
    render h VtxView, null
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'VTX Transmitter').toBeInTheDocument()
    expect(screen.getAllByText 'FATSHARK').toHaveLength 2
    expect(screen.getByText '5917').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeDisabled()
    frequency = document.querySelector '.vtx-frequency'
    expect(frequency.textContent).toContain '5740'

  it 'tunes through a band table cell click', ->
    render h VtxView, null
    fireEvent.click screen.getByText '5917'
    draft = useVtxStore.getState().draft
    expect(draft.band).toBe 5
    expect(draft.channel).toBe 8
    expect(draft.freq).toBe 5917
    expect(screen.getByText 'DIRTY').toBeInTheDocument()
    active = document.querySelector '.vtx-band-cell-active'
    expect(active.textContent).toBe '5917'

  it 'tracks the custom frequency input', ->
    render h VtxView, null
    input = document.querySelector '.vtx-freq-input'
    fireEvent.change input, { target: { value: '5801' } }
    draft = useVtxStore.getState().draft
    expect(draft.band).toBe 0
    expect(draft.freq).toBe 5801
    expect(document.querySelector('.vtx-frequency').textContent)
      .toContain '5801'

  it 'exposes band and channel selects wired to the store', ->
    render h VtxView, null
    selects = document.querySelectorAll '.vtx-select'
    bandSelect = selects[0]
    channelSelect = selects[1]
    expect(bandSelect.value).toBe '4'
    fireEvent.change bandSelect, { target: { value: '3' } }
    fireEvent.change channelSelect, { target: { value: '5' } }
    draft = useVtxStore.getState().draft
    expect(draft.band).toBe 3
    expect(draft.channel).toBe 5
    # BOSCAM E channel 5 = 5885 MHz (vtx58frequencyTable).
    expect(draft.freq).toBe 5885