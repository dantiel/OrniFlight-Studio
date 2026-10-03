import { render, screen, fireEvent, within } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import ServosView from '../components/views/ServosView/ServosView.chaml'
import useServoStore from '../stores/useServoStore.coffee'
import useOrnithopterStore from '../stores/useOrnithopterStore.coffee'

describe 'ServosView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useServoStore.getState().reset()
    useOrnithopterStore.getState().reset()

  afterEach -> vi.restoreAllMocks()

  renderView = ->
    render h(MemoryRouter, null, h(ServosView, null))

  it 'renders the control-surface deck with a SIMULATION badge', ->
    renderView()
    expect(document.querySelector '.layout-servos').toBeInTheDocument()
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Steuerflächen').toBeInTheDocument()
    expect(screen.queryByText 'Keine Steuerflächen').not.toBeInTheDocument()

  it 'renders only the surfaces the active mixer declares', ->
    # Default profile 1 = SERVO_2WING_1RUD → one rudder surface.
    renderView()
    expect(screen.getByText 'Seitenruder').toBeInTheDocument()
    expect(document.querySelectorAll('.servos-surface')).toHaveLength 1

  it 'lists every gearbox surface for a v-tail mixer', ->
    useOrnithopterStore.getState().setProfileId 3
    renderView()
    expect(screen.getByText 'Seitenruder').toBeInTheDocument()
    expect(screen.getByText 'V-Leitwerk L').toBeInTheDocument()
    expect(screen.getByText 'V-Leitwerk R').toBeInTheDocument()
    expect(document.querySelectorAll('.servos-surface')).toHaveLength 3

  it 'shows the empty state for a pure flapping mixer', ->
    useOrnithopterStore.getState().setProfileId 0
    renderView()
    expect(screen.getByText 'Keine Steuerflächen').toBeInTheDocument()
    expect(document.querySelectorAll('.servos-surface')).toHaveLength 0

  it 'offers only the mixer servo count as target channels', ->
    useOrnithopterStore.getState().setProfileId 3
    renderView()
    selects = document.querySelectorAll '.servos-surface-select'
    channelSelect = selects[1]
    options = Array.from(channelSelect.querySelectorAll('option')).map(
      (option) -> option.value
    )
    expect(options).toEqual ['0', '1', '2']

  it 'assigns a named input source and flags the draft dirty', ->
    renderView()
    selects = document.querySelectorAll '.servos-surface-select'
    fireEvent.change selects[0], { target: { value: 'rcYaw' } }
    expect(useServoStore.getState().draft.surfaces.rudder.inputSource
    ).toBe 'rcYaw'
    expect(screen.getByText 'DIRTY').toBeInTheDocument()

  it 'assigns a target channel and reverts cleanly', ->
    renderView()
    selects = document.querySelectorAll '.servos-surface-select'
    fireEvent.change selects[1], { target: { value: '2' } }
    expect(useServoStore.getState().draft.surfaces.rudder.targetChannel
    ).toBe 2
    fireEvent.click screen.getByText 'Revert'
    expect(screen.queryByText 'DIRTY').not.toBeInTheDocument()
    expect(useServoStore.getState().draft.surfaces.rudder.targetChannel
    ).toBe 0

  it 'save commits the draft in sim mode', ->
    renderView()
    selects = document.querySelectorAll '.servos-surface-select'
    fireEvent.change selects[0], { target: { value: 'rcYaw' } }
    fireEvent.click screen.getByText 'Save'
    expect(screen.queryByText 'DIRTY').not.toBeInTheDocument()
    expect(useServoStore.getState().saved.surfaces.rudder.inputSource
    ).toBe 'rcYaw'