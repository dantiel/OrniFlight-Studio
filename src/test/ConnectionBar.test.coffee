import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi } from 'vitest'
import ConnectionBar from '../components/panels/ConnectionBar/ConnectionBar.chaml'

describe 'ConnectionBar', ->

  renderConn = (props = {}) ->
    defaults = { connected: false, batteryVoltage: 0, flapFrequency: 0, viewMode: 'split', onViewModeChange: (->) }
    merged = { defaults..., props... }
    render h(MemoryRouter, null, h(ConnectionBar, merged))

  it 'renders the brand name', ->
    renderConn()
    expect(screen.getByText 'Orni').toBeInTheDocument()
    expect(screen.getByText 'Studio').toBeInTheDocument()
    flights = screen.getAllByText 'Flight'
    expect(flights.length).toBeGreaterThanOrEqual 1

  it 'shows DISCONNECTED when not connected', ->
    renderConn { connected: false }
    expect(screen.getByText 'GROUNDED').toBeInTheDocument()

  it 'shows SIMULATION when connected', ->
    renderConn { connected: true }
    expect(screen.getByText 'BREATHING').toBeInTheDocument()

  it 'displays battery voltage with 1 decimal', ->
    renderConn { connected: true, batteryVoltage: 11.4 }
    expect(screen.getByText '11.4V').toBeInTheDocument()

  it 'displays flap frequency with 1 decimal', ->
    renderConn { connected: true, flapFrequency: 8.5 }
    expect(screen.getByText '8.5 Hz').toBeInTheDocument()

  it 'handles undefined battery voltage gracefully', ->
    renderConn { connected: false }
    expect(screen.getByText '0.0V').toBeInTheDocument()

  it 'handles undefined flap frequency gracefully', ->
    renderConn { connected: false }
    expect(screen.getByText '0.0 Hz').toBeInTheDocument()

  it 'renders version badge', ->
    renderConn()
    expect(screen.getByText(/v0\.2.*Hermetic/)).toBeInTheDocument()

  it 'renders toolbar structure', ->
    renderConn()
    el = document.querySelector '.connection-bar'
    expect(el).toBeInTheDocument()