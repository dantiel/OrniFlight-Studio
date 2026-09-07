import { describe, it, expect, beforeEach } from 'vitest'
import { render, screen, fireEvent } from '@testing-library/react'
import useCliStore from '../stores/useCliStore.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'
import h from '../app/h.coffee'
import CliTerminalView from \
  '../components/views/CliTerminalView/CliTerminalView.coffee'
import { SIM_VERSION } from '../hooks/useCliSession.coffee'

describe 'CliTerminalView', ->
  beforeEach ->
    useCliStore.getState().reset()
    useDeviceStore.getState().setSimulation()

  input = -> screen.getByLabelText 'CLI command input'

  it 'renders the simulation banner and badges', ->
    render h(CliTerminalView, null)
    expect(screen.getByText('CLI Terminal')).toBeInTheDocument()
    expect(screen.getByText('◌ SIMULATION')).toBeInTheDocument()
    expect(screen.getByRole('log')).toHaveTextContent 'OrniFlight CLI'

  it 'executes a sim command from the input line', ->
    render h(CliTerminalView, null)
    fireEvent.change input(), { target: { value: 'version' } }
    fireEvent.keyDown input(), { key: 'Enter' }
    expect(await screen.findByText(SIM_VERSION)).toBeInTheDocument()
    expect(await screen.findByText('# version')).toBeInTheDocument()

  it 'shows errors for unknown commands', ->
    render h(CliTerminalView, null)
    fireEvent.change input(), { target: { value: 'xyzzy' } }
    fireEvent.keyDown input(), { key: 'Enter' }
    expect(
      await screen.findByText '###ERROR: unknown command: xyzzy'
    ).toBeInTheDocument()

  it 'recalls history with the arrow keys', ->
    render h(CliTerminalView, null)
    fireEvent.change input(), { target: { value: 'version' } }
    fireEvent.keyDown input(), { key: 'Enter' }
    fireEvent.change input(), { target: { value: 'help' } }
    fireEvent.keyDown input(), { key: 'Enter' }
    expect(input().value).toBe ''
    fireEvent.keyDown input(), { key: 'ArrowUp' }
    expect(input().value).toBe 'help'
    fireEvent.keyDown input(), { key: 'ArrowUp' }
    expect(input().value).toBe 'version'
    fireEvent.keyDown input(), { key: 'ArrowDown' }
    expect(input().value).toBe 'help'

  it 'returns to the draft when navigating past the history top', ->
    render h(CliTerminalView, null)
    fireEvent.change input(), { target: { value: 'version' } }
    fireEvent.keyDown input(), { key: 'Enter' }
    fireEvent.change input(), { target: { value: 'draft' } }
    fireEvent.keyDown input(), { key: 'ArrowUp' }
    expect(input().value).toBe 'version'
    fireEvent.keyDown input(), { key: 'ArrowUp' }
    expect(input().value).toBe 'draft'

  it 'clears the scrollback with the clear button', ->
    render h(CliTerminalView, null)
    fireEvent.change input(), { target: { value: 'version' } }
    fireEvent.keyDown input(), { key: 'Enter' }
    await screen.findByText SIM_VERSION
    fireEvent.click screen.getByRole 'button', { name: 'Clear' }
    expect(screen.queryByText(SIM_VERSION)).toBeNull()

  it 'disables device entry without a connection', ->
    render h(CliTerminalView, null)
    expect(
      screen.getByRole 'button', { name: 'Open device CLI' }
    ).toBeDisabled()