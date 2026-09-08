import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import FailsafeView from '../components/views/FailsafeView/FailsafeView.coffee'
import useSafetyStore from '../stores/useSafetyStore.coffee'

state = -> useSafetyStore.getState()

describe 'FailsafeView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    state().reset()

  afterEach -> vi.restoreAllMocks()

  it 'renders the four panels with the sim badge and defaults', ->
    render h FailsafeView, null
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Failsafe').toBeInTheDocument()
    # 'Arming' appears as panel heading and as a beeper condition.
    expect(screen.getAllByText('Arming').length).toBeGreaterThan 0
    expect(screen.getByText 'Features').toBeInTheDocument()
    expect(screen.getByText 'Beeper').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeDisabled()
    expect(screen.getByText 'Save').toBeEnabled()
    expect(screen.getByText 'Revert').toBeDisabled()

  it 'patches the failsafe draft through the guard-time input', ->
    render h FailsafeView, null
    guardTime = document.querySelectorAll('.safety-input')[0]
    fireEvent.change guardTime, { target: { value: '12' } }
    expect(state().draft.failsafe.delay).toBe 12
    expect(screen.getByText 'DIRTY').toBeInTheDocument()

  it 'toggles a feature bit through its checkbox', ->
    render h FailsafeView, null
    ppmRow = screen.getByLabelText 'PPM receiver'
    expect(ppmRow.checked).toBe false
    fireEvent.click ppmRow
    expect(state().draft.features & 1).toBe 1
    expect(state().dirty).toBe true

  it 'mutes a beeper condition through its checkbox', ->
    render h FailsafeView, null
    armingRow = screen.getByLabelText 'Arming'
    expect(armingRow.checked).toBe true
    fireEvent.click armingRow
    expect(state().draft.beeper.offFlags & (1 << 4)).toBeTruthy()

  it 'commits locally in sim mode through the save button', ->
    render h FailsafeView, null
    state().setFailsafe { delay: 8 }
    fireEvent.click screen.getByText 'Save'
    await waitFor ->
      expect(state().saved.failsafe.delay).toBe 8
    expect(state().dirty).toBe false