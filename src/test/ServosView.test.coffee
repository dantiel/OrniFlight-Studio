import { render, screen, fireEvent, within } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'
import useServoStore from '../stores/useServoStore.coffee'

describe 'ServosView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useServoStore.getState().reset()

  afterEach -> vi.restoreAllMocks()

  renderView = ->
    render h(MemoryRouter, { initialEntries: ['/servos'] }, h(App, null))

  view = -> within document.querySelector '.layout-servos'

  it 'renders the servo panels with a SIMULATION badge', ->
    renderView()
    expect(document.querySelector '.layout-servos').toBeInTheDocument()
    expect(view().getByText 'SIMULATION').toBeInTheDocument()
    expect(view().getByText 'Wing Mapping').toBeInTheDocument()
    expect(view().getByText 'Servo Channels').toBeInTheDocument()
    expect(view().getByText 'Glide').toBeInTheDocument()
    expect(view().getByText 'Mix Rules').toBeInTheDocument()
    expect(view().getByText 'Servo 1 — L1 wing').toBeInTheDocument()
    expect(view().getByText 'Servo 2 — R1 wing').toBeInTheDocument()

  it 'disables Read device in sim mode and shows no DIRTY badge', ->
    renderView()
    expect(view().getByText 'Read device').toBeDisabled()
    expect(view().queryByText 'DIRTY').not.toBeInTheDocument()

  it 'edits a servo channel and flags the draft dirty', ->
    renderView()
    input = screen.getAllByLabelText('Min pulse')[0]
    fireEvent.change input, { target: { value: '1100' } }
    fireEvent.blur input
    expect(view().getByText 'DIRTY').toBeInTheDocument()
    expect(useServoStore.getState().draft.servos[0].min).toBe 1100

  it 'edits the glide degree and reverts cleanly', ->
    renderView()
    input = screen.getByLabelText 'Glide degree'
    fireEvent.change input, { target: { value: '30' } }
    fireEvent.blur input
    expect(useServoStore.getState().draft.glide).toBe 30
    fireEvent.click view().getByText 'Revert'
    expect(view().queryByText 'DIRTY').not.toBeInTheDocument()
    expect(useServoStore.getState().draft.glide).toBe 0

  it 'save commits the draft in sim mode', ->
    renderView()
    input = screen.getAllByLabelText('Max pulse')[0]
    fireEvent.change input, { target: { value: '1900' } }
    fireEvent.blur input
    fireEvent.click view().getByText 'Save'
    expect(view().queryByText 'DIRTY').not.toBeInTheDocument()
    expect(useServoStore.getState().saved.servos[0].max).toBe 1900
