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

  renderApp = (route = '/device') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  getTabLink = (text) ->
    document.querySelector "a.config-view-btn[href=\"/#{text.toLowerCase()}\"]"

  it 'renders all eleven domain workspaces with full labels', ->
    renderApp()
    links = document.querySelectorAll 'a.config-view-btn'
    expect(links.length).toBe 11
    labels = [
      'Device', 'Airframe', 'Flight Control', 'Receiver', 'Power',
      'Sensors', 'Safety', 'OSD', 'Data', 'Flash Firmware', 'CLI'
    ]
    expect(Array.from(links).map((link) -> link.textContent)).toEqual labels

  it 'navigates to the Sensors workspace', ->
    renderApp()
    user = userEvent.setup()
    link = getTabLink 'Sensors'
    expect(link).toBeTruthy()
    await user.click link
    await waitFor ->
      el = document.querySelector '.layout-perception'
      expect(el).toBeInTheDocument()

  it 'navigates to Flight Control', ->
    renderApp()
    user = userEvent.setup()
    link = document.querySelector 'a.config-view-btn[href="/control"]'
    expect(link).toBeTruthy()
    await user.click link
    await waitFor ->
      el = document.querySelector '.layout-control'
      expect(el).toBeInTheDocument()

  it 'navigates to Airframe from Sensors', ->
    renderApp('/sensors')
    user = userEvent.setup()
    link = getTabLink 'Airframe'
    expect(link).toBeTruthy()
    await user.click link
    await waitFor ->
      el = document.querySelector '.layout-wings'
      expect(el).toBeInTheDocument()