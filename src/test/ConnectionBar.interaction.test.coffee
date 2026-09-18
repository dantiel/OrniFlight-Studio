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

  renderApp = (route = '/system/device') ->
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

  it 'renders the active module sub-views in the top menu', ->
    renderApp()
    links = document.querySelectorAll 'a.config-view-btn'
    expect(links.length).toBe 9
    texts = Array.from(links).map (l) -> l.textContent
    expect(texts).toContain 'Gerät'
    expect(texts).toContain 'Ports'
    expect(texts).toContain 'Power'
    expect(texts).toContain 'VTX'
    expect(texts).toContain 'OSD'
    expect(texts).toContain 'Sprache'
    expect(texts).toContain 'Speicher'
    expect(texts).toContain 'Firmware'
    expect(texts).toContain 'Daten'
