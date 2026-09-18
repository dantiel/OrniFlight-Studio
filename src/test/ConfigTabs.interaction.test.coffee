import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'

describe 'ConfigTabs — Interaction', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
  afterEach ->
    vi.restoreAllMocks()

  renderApp = (route = '/basic/body') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  labels = -> Array.from(document.querySelectorAll('a.config-view-btn')).map((l) -> l.textContent)

  it 'renders the Grundkonfiguration sub-views', ->
    renderApp '/basic/body'
    expect(labels()).toEqual ['Körperplan', 'Flugwerk', 'Schlagkurve']

  it 'renders the System sub-views', ->
    renderApp '/system/device'
    expect(labels()).toEqual [
      'Gerät', 'Ports', 'Power', 'VTX', 'OSD',
      'Sprache', 'Speicher', 'Firmware', 'Daten'
    ]

  it 'renders the Steuerung sub-views', ->
    renderApp '/control/pid'
    expect(labels()).toEqual ['PID', 'Modi', 'Empfänger', 'Justierung']

  it 'navigates between sub-views of one module', ->
    renderApp '/basic/body'
    user = userEvent.setup()
    link = document.querySelector 'a.config-view-btn[href="/basic/airframe"]'
    expect(link).toBeTruthy()
    await user.click link
    await waitFor ->
      expect(screen.getByText 'Servo-Montage').toBeInTheDocument()
