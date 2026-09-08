import { render, screen } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'

describe 'ConnectionBar — Interaction', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
  afterEach ->
    vi.restoreAllMocks()

  renderApp = (route = '/device') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  it 'renders connection status BREATHING on startup', ->
    renderApp()
    els = screen.getAllByText 'BREATHING'
    expect(els.length).toBeGreaterThanOrEqual 1

  it 'renders flap and battery metric badge labels', ->
    renderApp()
    expect(screen.getByText 'Flap').toBeInTheDocument()
    expect(screen.getByText 'Battery').toBeInTheDocument()

  it 'renders brand identifiers', ->
    renderApp()
    expect(screen.getByText 'Orni').toBeInTheDocument()
    expect(screen.getByText 'Studio').toBeInTheDocument()

  it 'renders thirteen domain workspace links', ->
    renderApp()
    links = document.querySelectorAll 'a.config-view-btn'
    expect(links.length).toBe 13
    texts = Array.from(links).map (l) -> l.textContent
    expect(texts).toContain 'Device'
    expect(texts).toContain 'Airframe'
    expect(texts).toContain 'Flight Control'
    expect(texts).toContain 'Receiver'
    expect(texts).toContain 'Power'
    expect(texts).toContain 'Sensors'
    expect(texts).toContain 'Safety'
    expect(texts).toContain 'OSD'
    expect(texts).toContain 'VTX'
    expect(texts).toContain 'Ports'
    expect(texts).toContain 'Data'
    expect(texts).toContain 'Flash Firmware'
    expect(texts).toContain 'CLI'