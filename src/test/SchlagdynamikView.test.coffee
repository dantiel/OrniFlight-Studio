import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { MemoryRouter } from 'react-router-dom'
import SchlagdynamikView from '../components/views/SchlagdynamikView/SchlagdynamikView.chaml'
import useOrnithopterStore from '../stores/useOrnithopterStore.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'

LAYER_NAMES = [
  'Cadence', 'Ferocity', 'Balance', 'Warp', 'Anchor'
  'Resonance', 'Prescience', 'Espelho', 'Saudade', 'Aeroelastic'
]

rowFor = (label) ->
  rows = Array.from document.querySelectorAll '.param-row'
  rows.find (row) -> row.textContent.includes label

describe 'SchlagdynamikView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useOrnithopterStore.getState().reset()
    useTelemetryStore.setState {
      waveformHistory: []
      flapFrequency: 0
      debug: [0, 0, 0, 0]
      source: 'offline'
    }

  afterEach ->
    vi.restoreAllMocks()

  renderView = ->
    render h(MemoryRouter, null, h(SchlagdynamikView, null))

  it 'renders the Schlagdynamik head and the deck', ->
    renderView()
    expect(screen.getByText 'Schlagdynamik').toBeInTheDocument()
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Gerät lesen').toBeInTheDocument()
    expect(screen.getByText 'Speichern').toBeInTheDocument()
    expect(screen.getByText 'Verwerfen').toBeInTheDocument()
    expect(screen.getByText '→ Espelho').toBeInTheDocument()

  it 'pins the plotter deck beside the scrolling params', ->
    renderView()
    layout = document.querySelector '.schlag-layout'
    expect(layout).toBeInTheDocument()
    expect(document.querySelector '.schlag-params').toBeInTheDocument()
    plots = document.querySelector '.schlag-plots'
    expect(plots).toBeInTheDocument()
    expect(plots.querySelector '.plot-deck').toBeInTheDocument()
    expect(document.querySelector '.math-wave-svg').toBeInTheDocument()
    expect(screen.getByText 'Signatur').toBeInTheDocument()
    layers = document.querySelectorAll '.math-layers .math-layer'
    expect(layers.length).toBe 10
    depths = Array.from(layers).map (el) ->
      el.style.getPropertyValue '--plx'
    expect(depths.some (d) -> d.trim() isnt '0px').toBe true

  it 'mounts the living stroke scope with an offline empty state', ->
    renderView()
    scope = document.querySelector '.stroke-scope'
    expect(scope).toBeInTheDocument()
    expect(scope.querySelector '.stroke-scope-canvas').toBeInTheDocument()
    empty = scope.querySelector '.stroke-scope-empty'
    expect(empty).toBeInTheDocument()
    expect(screen.getByText 'Kein Signal — verbinde einen Controller oder starte die Simulation.').toBeInTheDocument()

  it 'renders ten layer cards and eighteen param rows', ->
    renderView()
    for name in LAYER_NAMES
      expect(screen.getAllByText(name).length).toBeGreaterThan 0
    expect(document.querySelectorAll '.param-row').toHaveLength 18
    expect(screen.getByText 'Profil 1 · ONDAS-Ziel').toBeInTheDocument()

  it 'renders the shared profile selector with four chips', ->
    renderView()
    selector = document.querySelector '.profile-selector'
    expect(selector).toBeInTheDocument()
    expect(selector.querySelectorAll('.profile-selector-chip')).toHaveLength 4

  it 'honours signed registry ranges on the sliders', ->
    renderView()
    cadence = rowFor('Phasenvoreilung').querySelector '.param-slider'
    expect(cadence.getAttribute 'min').toBe '-100'
    expect(cadence.getAttribute 'max').toBe '100'
    down = rowFor('Downstroke-Form').querySelector '.param-slider'
    expect(down.getAttribute 'min').toBe '1'
    anchor = rowFor('Dämpfungsanker').querySelector '.param-slider'
    expect(anchor.getAttribute 'min').toBe '0'

  it 'renders the stroke preview and switches the deck to the espelho readouts', ->
    renderView()
    expect(document.querySelector '.math-stroke path').toBeInTheDocument()
    fireEvent.click screen.getByText 'Spiegel'
    expect(document.querySelectorAll '.espelho-gauge').toHaveLength 4
    expect(screen.getAllByText('0.000').length).toBeGreaterThan 0
    expect(screen.getByText '0°').toBeInTheDocument()
    expect(screen.getByText 'SIM · stroke-derived').toBeInTheDocument()

  it 'switches the active profile from the selector', ->
    renderView()
    chips = document.querySelectorAll '.profile-selector-chip'
    fireEvent.click chips[2]
    expect(useOrnithopterStore.getState().draft.activeProfile).toBe 2
    expect(screen.getByText 'Profil 3 · ONDAS-Ziel').toBeInTheDocument()