import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { MemoryRouter } from 'react-router-dom'
import MathView from '../components/views/MathView/MathView.chaml'
import useTuningStore from '../stores/useTuningStore.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'

LAYER_NAMES = [
  'Cadence', 'Ferocity', 'Balance', 'Warp', 'Anchor'
  'Resonance', 'Prescience', 'Espelho', 'Saudade', 'Aeroelastic'
]

rowFor = (label) ->
  rows = Array.from document.querySelectorAll '.param-row'
  rows.find (row) -> row.textContent.includes label

describe 'MathView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useTuningStore.getState().reset()
    useTelemetryStore.setState {
      waveformHistory: []
      flapFrequency: 0
      debug: [0, 0, 0, 0]
      source: 'offline'
    }

  afterEach ->
    vi.restoreAllMocks()

  renderView = ->
    render h(MemoryRouter, null, h(MathView, null))

  it 'renders the ORGONE head and the deck', ->
    renderView()
    expect(screen.getByText 'Math').toBeInTheDocument()
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeInTheDocument()
    expect(screen.getByText 'Save').toBeInTheDocument()
    expect(screen.getByText 'Revert').toBeInTheDocument()
    expect(screen.getByText '→ Espelho').toBeInTheDocument()

  it 'anchors the layer flow to the fixed waveform rail', ->
    renderView()
    rail = document.querySelector '.math-rail'
    expect(rail).toBeInTheDocument()
    expect(rail.querySelector '.math-wave-svg').toBeInTheDocument()
    expect(screen.getByText 'Waveform').toBeInTheDocument()
    # The layers live in a half-width parallax field beside the rail.
    layers = document.querySelectorAll '.math-layers .math-layer'
    expect(layers.length).toBe 10
    depths = Array.from(layers).map (el) ->
      el.style.getPropertyValue '--plx'
    expect(depths.some (d) -> d.trim() isnt '0px').toBe true

  it 'renders ten layer cards and eighteen param rows', ->
    renderView()
    for name in LAYER_NAMES
      expect(screen.getAllByText(name).length).toBeGreaterThan 0
    expect(document.querySelectorAll '.param-row').toHaveLength 18
    expect(screen.getByText(/Profil 1/)).toBeInTheDocument()

  it 'honours signed registry ranges on the sliders', ->
    renderView()
    cadence = rowFor('Phase advance').querySelector '.param-slider'
    expect(cadence.getAttribute 'min').toBe '-100'
    expect(cadence.getAttribute 'max').toBe '100'
    down = rowFor('Downstroke shape').querySelector '.param-slider'
    expect(down.getAttribute 'min').toBe '1'
    anchor = rowFor('Damping anchor').querySelector '.param-slider'
    expect(anchor.getAttribute 'min').toBe '0'

  it 'renders the stroke preview and the espelho readouts', ->
    renderView()
    expect(document.querySelector '.math-stroke path').toBeInTheDocument()
    expect(document.querySelectorAll '.espelho-gauge').toHaveLength 4
    expect(screen.getAllByText('0.000').length).toBeGreaterThan 0
    expect(screen.getByText '0°').toBeInTheDocument()
    expect(screen.getByText 'SIM · stroke-derived').toBeInTheDocument()

  it 'edits the draft with signed values and shows DIRTY', ->
    renderView()
    cadence = rowFor('Phase advance').querySelector '.param-slider'
    fireEvent.input cadence, { target: { value: '-40' } }
    expect(useTuningStore.getState().draft.ondas.cadence_gain).toBe -40
    expect(screen.getByText 'DIRTY').toBeInTheDocument()

  it 'spotlights a layer section from the signal chain', ->
    renderView()
    node = screen
      .getAllByRole('button')
      .find((b) -> b.textContent.includes 'Ferocity')
    fireEvent.click node
    target = document.getElementById 'math-ferocity'
    expect(target.classList.contains 'morph-spotlight').toBe true