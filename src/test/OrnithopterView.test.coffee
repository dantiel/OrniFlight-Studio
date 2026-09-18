import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, vi, beforeEach, afterEach } from 'vitest'
import OrnithopterView from '../components/views/OrnithopterView/OrnithopterView.coffee'
import useOrnithopterStore from '../stores/useOrnithopterStore.coffee'

describe 'OrnithopterView', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useOrnithopterStore.getState().reset()
  afterEach -> vi.restoreAllMocks()

  renderAt = (route = '/basic/body') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(OrnithopterView, null))

  it 'renders the drive-side body plan under Grundkonfiguration', ->
    renderAt()
    expect(screen.getByText 'GRUNDKONFIGURATION').toBeInTheDocument()
    expect(screen.getByText 'Körperplan').toBeInTheDocument()
    expect(screen.getByText 'GPIO-Map').toBeInTheDocument()

  it 'shows Flugwerk on the airframe sub-view', ->
    renderAt '/basic/airframe'
    expect(screen.getByText 'Flugwerk').toBeInTheDocument()
    expect(screen.getByText 'Spannweite').toBeInTheDocument()
    expect(screen.getByText 'Schwerpunkt längs').toBeInTheDocument()
    expect(screen.getByText 'Servo-Montage').toBeInTheDocument()

  it 'shows Schlagkurve on the wave sub-view', ->
    renderAt '/basic/wave'
    expect(screen.getByText 'Schlagkurve').toBeInTheDocument()
    expect(screen.getByText 'Abwärts-Ferocity').toBeInTheDocument()
    expect(screen.getByText 'Shape-Mix').toBeInTheDocument()
    expect(screen.getByText 'Quer-Slew').toBeInTheDocument()

  it 'shows only the mount pairs the mixer actually grows', ->
    useOrnithopterStore.getState().setProfileId 2
    renderAt '/basic/airframe'
    expect(screen.getAllByText 'Montagewinkel').toHaveLength 2
    expect(screen.getByText 'Paar 2').toBeInTheDocument()
    expect(screen.queryByText 'Paar 3').toBeNull()

  it 'does not leak flight profiles or the channel test into the view', ->
    renderAt()
    expect(screen.queryByText 'Flugprofile').toBeNull()
    expect(screen.queryByText 'Kanal-Test').toBeNull()
