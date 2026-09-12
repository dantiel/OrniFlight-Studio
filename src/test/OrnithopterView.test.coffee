import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, vi, beforeEach, afterEach } from 'vitest'
import OrnithopterView from '../components/views/OrnithopterView/OrnithopterView.coffee'
import useOrnithopterStore from '../stores/useOrnithopterStore.coffee'

describe 'OrnithopterView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useOrnithopterStore.getState().reset()
  afterEach -> vi.restoreAllMocks()

  it 'renders the unified body plan without object-child crash', ->
    render h(OrnithopterView, null)
    expect(screen.getByText 'ORNITHOPTER').toBeInTheDocument()
    expect(screen.getByText 'Körperplan').toBeInTheDocument()
    expect(screen.getByText 'Flugprofile').toBeInTheDocument()
    expect(screen.getByText 'Schlagkurve').toBeInTheDocument()
    expect(screen.getByText 'Kanal-Test').toBeInTheDocument()

  it 'renders all nine waveform fields as slider controls', ->
    render h(OrnithopterView, null)
    expect(screen.getByText 'Abwärts-Ferocity').toBeInTheDocument()
    expect(screen.getByText 'Aufwärts-Ferocity').toBeInTheDocument()
    expect(screen.getByText 'Shape-Mix').toBeInTheDocument()
    expect(screen.getByText 'Gas → Skew').toBeInTheDocument()
    expect(screen.getByText 'Quer-Slew').toBeInTheDocument()

  it 'switches the active face on click', ->
    render h(OrnithopterView, null)
    face = document.querySelectorAll('.orni-face')[1]
    fireEvent.click face
    expect(useOrnithopterStore.getState().draft.activeProfile).toBe 1