import { render, screen, fireEvent, within } from '@testing-library/react'
import { waitFor } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'
import useConfigurationStore from '../stores/useConfigurationStore.coffee'

describe 'ConfigSections', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useConfigurationStore.getState().reset()

  afterEach ->
    vi.restoreAllMocks()

  renderApp = ->
    render h(MemoryRouter, { initialEntries: ['/airframe'] }, h(App, null))

  sections = -> within document.querySelector '.config-sections'

  it 'renders the airframe configuration sections', ->
    renderApp()
    expect(document.querySelector '.config-sections').toBeInTheDocument()
    expect(sections().getByText 'Geometry').toBeInTheDocument()
    expect(sections().getByText 'Mass & CG').toBeInTheDocument()
    expect(sections().getByText 'Servo Pairs').toBeInTheDocument()

  it 'shows the SIMULATION badge in sim mode', ->
    renderApp()
    expect(sections().getByText 'SIMULATION').toBeInTheDocument()

  it 'starts clean without a DIRTY badge', ->
    renderApp()
    expect(sections().queryByText 'DIRTY').not.toBeInTheDocument()

  it 'flags the draft dirty when a field changes', ->
    renderApp()
    input = screen.getByLabelText 'Wing span'
    fireEvent.change input, { target: { value: '1500' } }
    fireEvent.blur input
    expect(sections().getByText 'DIRTY').toBeInTheDocument()
    expect(
      useConfigurationStore.getState().draft.geometry.wingSpan
    ).toBe 1500

  it 'save commits and clears the dirty flag', ->
    renderApp()
    input = screen.getByLabelText 'Wing span'
    fireEvent.change input, { target: { value: '1500' } }
    fireEvent.blur input
    fireEvent.click sections().getByText 'Save'
    expect(sections().queryByText 'DIRTY').not.toBeInTheDocument()
    expect(useConfigurationStore.getState().saved.geometry.wingSpan).toBe 1500

  it 'revert stays disabled while the draft is clean', ->
    renderApp()
    expect(sections().getByText 'Revert').toBeDisabled()

  it 'revert restores the saved draft', ->
    renderApp()
    input = screen.getByLabelText 'Wing span'
    fireEvent.change input, { target: { value: '1500' } }
    fireEvent.blur input
    fireEvent.click sections().getByText 'Revert'
    expect(
      useConfigurationStore.getState().draft.geometry.wingSpan
    ).toBe 1200
    expect(sections().queryByText 'DIRTY').not.toBeInTheDocument()

  it 'disables Read device while in sim mode', ->
    renderApp()
    expect(sections().getByText 'Read device').toBeDisabled()

  it 'reads servo configurations from the device on demand', ->
    store = useConfigurationStore.getState()
    store.setMode 'device'
    configs = [{
      index: 0, min: 1050, max: 1950, middle: 1510, rate: 80
      forwardFromChannel: 0
      reversedSources: 0
    }]
    store.attachSession {
      readServoConfigurations: -> Promise.resolve configs
      writeServoConfiguration: -> Promise.resolve null
    }
    renderApp()
    expect(sections().getByText 'Read device').toBeEnabled()
    fireEvent.click sections().getByText 'Read device'
    await waitFor ->
      expect(useConfigurationStore.getState().draft.servos).toEqual configs
    expect(sections().getByText 'DEVICE').toBeInTheDocument()