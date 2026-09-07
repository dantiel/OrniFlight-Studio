import { render, screen, fireEvent, act } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import PidTuningView from '../components/views/PidTuningView/PidTuningView.coffee'
import useTuningStore from '../stores/useTuningStore.coffee'

describe 'PidTuningView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useTuningStore.getState().reset()

  afterEach ->
    vi.restoreAllMocks()

  renderView = ->
    render h(PidTuningView, null)

  it 'renders the four tuning sections in sim mode', ->
    renderView()
    expect(document.querySelector '.layout-control').toBeInTheDocument()
    for title in ['PID Bank', 'Rates', 'ONDAS', 'Filters']
      expect(screen.getByText title).toBeInTheDocument()
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText(/nicht persistiert/)).toBeInTheDocument()

  it 'shows twelve PID rows and ten ONDAS rows', ->
    renderView()
    for trigger in document.querySelectorAll '.studio-accordion-trigger'
      fireEvent.click trigger
    rows = document.querySelectorAll '.param-row'
    expect(rows.length).toBe 12 + 3 + 10 + 4
    expect(screen.getByText 'roll P').toBeInTheDocument()
    expect(screen.getByText 'flap D').toBeInTheDocument()
    expect(screen.getByText 'anchor gain').toBeInTheDocument()

  it 'shows the UNSAVED badge after a draft edit', ->
    renderView()
    slider = document.querySelector '.param-slider'
    fireEvent.input slider, { target: { value: '5' } }
    expect(screen.getByText 'UNSAVED').toBeInTheDocument()
    expect(useTuningStore.getState().draft.pid.roll.P).toBe 5

  it 'renders the DEVICE badge without the sim banner', ->
    useTuningStore.getState().attachSession {
      writeTuning: (->), readTuning: (->)
    }
    renderView()
    expect(screen.getByText 'DEVICE').toBeInTheDocument()
    expect(screen.queryByText(/nicht persistiert/)).toBeNull()

  it 'saves the draft locally when clicking Save in sim mode', ->
    renderView()
    slider = document.querySelector '.param-slider'
    fireEvent.input slider, { target: { value: '5' } }
    user = userEvent.setup()
    await user.click screen.getByText 'Save'
    state = useTuningStore.getState()
    expect(state.dirty).toBe false
    expect(state.mode).toBe 'sim'
    expect(state.saved.pid.roll.P).toBe 5

  it 'reverts the draft when clicking Revert', ->
    renderView()
    slider = document.querySelector '.param-slider'
    fireEvent.input slider, { target: { value: '5' } }
    await act -> await useTuningStore.getState().save()
    fireEvent.input slider, { target: { value: '7' } }
    user = userEvent.setup()
    await user.click screen.getByText 'Revert'
    expect(useTuningStore.getState().draft.pid.roll.P).toBe 5
    expect(useTuningStore.getState().dirty).toBe false