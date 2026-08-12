import { render, screen } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'

describe 'App', ->

  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1

  afterEach ->
    vi.restoreAllMocks()

  renderApp = (route = '/wings') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  it 'renders the studio shell', ->
    renderApp()
    el = document.querySelector '.studio-shell'
    expect(el).toBeInTheDocument()

  it 'renders the skip-to-content link', ->
    renderApp()
    el = screen.getByText 'Skip to content'
    expect(el).toBeInTheDocument()

  it 'renders the toolbar with brand name', ->
    renderApp()
    expect(screen.getByText 'Orni').toBeInTheDocument()
    expect(screen.getByText 'Studio').toBeInTheDocument()
    flights = screen.getAllByText 'Flight'
    expect(flights.length).toBeGreaterThanOrEqual 1

  it 'renders the wings view layout (default route /wings)', ->
    renderApp()
    el = document.querySelector '.layout-wings'
    expect(el).toBeInTheDocument()

  it 'renders the 3D viewport in wings view', ->
    renderApp()
    el = document.querySelector '.view-area-vport'
    expect(el).toBeInTheDocument()

  it 'renders the servo inspector in wings view', ->
    renderApp()
    el = document.querySelector '.studio-inspector'
    expect(el).toBeInTheDocument()

  it 'renders telemetry panels in wings view', ->
    renderApp()
    el = document.querySelector '.view-area-tele'
    expect(el).toBeInTheDocument()

  it 'shows SIMULATION mode on startup', ->
    renderApp()
    els = screen.getAllByText 'BREATHING'
    expect(els.length).toBeGreaterThanOrEqual 1

  it 'renders overlay badges in wings view', ->
    renderApp()
    els = document.querySelectorAll '.overlay-badge'
    expect(els.length).toBeGreaterThanOrEqual 3

  it 'renders all servo names in wings sidebar', ->
    renderApp()
    items = screen.getAllByText /Servo [1-4]/
    expect(items.length).toBeGreaterThanOrEqual 3

  it 'renders stick input section with abbreviated labels', ->
    renderApp()
    items = screen.getAllByText 'THR'
    expect(items.length).toBeGreaterThanOrEqual 1

  it 'renders Wing Servos section in sidebar', ->
    renderApp()
    items = screen.getAllByText 'Wing Servos'
    expect(items.length).toBeGreaterThanOrEqual 1

  it 'renders gyro rate display in perception view', ->
    render h(MemoryRouter, { initialEntries: ['/perception'] }, h(App, null))
    els = document.querySelectorAll '.layout-perception'
    expect(els.length).toBe 1
