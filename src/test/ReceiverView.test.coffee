import { render, fireEvent, screen, within } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'
import useReceiverStore from '../stores/useReceiverStore.coffee'
import useModesStore from '../stores/useModesStore.coffee'

# The first App render compiles ReceiverView + embedded ModesView on
# demand; under full-suite parallel load it can exceed the 5s default.
describe 'ReceiverView', { timeout: 20000 }, ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useReceiverStore.getState().reset()
    useModesStore.getState().reset()

  afterEach -> vi.restoreAllMocks()

  renderView = ->
    render h(MemoryRouter, { initialEntries: ['/control/receiver'] }, h(App, null))

  view = -> within document.querySelector '.layout-receiver'

  it 'renders the receiver panels with a SIMULATION badge', ->
    renderView()
    expect(document.querySelector '.layout-receiver').toBeInTheDocument()
    expect(
      view().getByText 'SIMULATION', { selector: '.receiver-mode-badge' }
    ).toBeInTheDocument()
    expect(view().getByText 'RX Protocol').toBeInTheDocument()
    expect(view().getByText 'Channel Map').toBeInTheDocument()
    expect(view().getByText 'Failsafe Channels').toBeInTheDocument()
    expect(view().getByText 'Live Channels').toBeInTheDocument()

  it 'disables Read device in sim mode and shows no DIRTY badge', ->
    renderView()
    readButtons = view().getAllByText 'Read device'
    expect(readButtons[0]).toBeDisabled()
    expect(view().queryByText 'DIRTY').not.toBeInTheDocument()

  it 'edits the provider select and flags the draft dirty', ->
    renderView()
    providerSelect = document.querySelector '.receiver-provider'
    fireEvent.change providerSelect, { target: { value: '2' } }
    expect(view().getByText 'DIRTY').toBeInTheDocument()
    expect(useReceiverStore.getState().draft.provider).toBe 2

  it 'edits a channel-map position', ->
    renderView()
    selects = document.querySelectorAll '.channel-map-select'
    fireEvent.change selects[0], { target: { value: 'T' } }
    expect(useReceiverStore.getState().draft.channelMap).toBe 'TETR1234'

  it 'edits a failsafe mode and reverts cleanly', ->
    renderView()
    modeSelects = document.querySelectorAll '.rxfail-mode'
    fireEvent.change modeSelects[2], { target: { value: '2' } }
    expect(useReceiverStore.getState().draft.rxFail[2].mode).toBe 2
    fireEvent.click view().getAllByText('Revert')[0]
    expect(view().queryByText 'DIRTY').not.toBeInTheDocument()
    expect(useReceiverStore.getState().draft.rxFail[2].mode).toBe 0

  it 'logs a failed device save instead of rejecting silently', ->
    session =
      readRxConfig: -> Promise.resolve null
      readRxMap: -> Promise.resolve []
      readRxFailConfig: -> Promise.resolve []
      writeRxConfig: -> Promise.reject new Error 'armed guard'
    useReceiverStore.getState().attachSession session
    await useReceiverStore.getState().loadFromDevice session
    errorSpy = vi.spyOn(console, 'error').mockImplementation -> null
    renderView()
    fireEvent.click view().getAllByText('Save')[0]
    await vi.waitFor -> expect(errorSpy).toHaveBeenCalled()

  it 'logs a failed device mode save instead of rejecting silently', ->
    session =
      readModeRanges: -> Promise.resolve { ranges: [], extras: null }
    useModesStore.getState().attachSession session
    await useModesStore.getState().loadFromDevice session
    errorSpy = vi.spyOn(console, 'error').mockImplementation -> null
    render h(MemoryRouter, { initialEntries: ['/control/modes'] }, h(App, null))
    fireEvent.click screen.getByText('Save')
    await vi.waitFor -> expect(errorSpy).toHaveBeenCalled()