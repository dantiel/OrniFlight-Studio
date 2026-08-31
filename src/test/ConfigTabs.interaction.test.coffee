import { render, screen } from '@testing-library/react'
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

  renderApp = (route = '/wings') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  getTabLink = (text) ->
    document.querySelector "a.config-view-btn[href=\"/#{text.toLowerCase()}\"]"

  it 'renders all six config tabs with text labels', ->
    renderApp()
    links = document.querySelectorAll 'a.config-view-btn'
    expect(links.length).toBe 6
    expect(links[0].textContent).toBe 'Wings'
    expect(links[1].textContent).toBe 'Flight'
    expect(links[2].textContent).toBe 'Perception'
    expect(links[3].textContent).toBe 'Voice'
    expect(links[4].textContent).toBe 'Memory'
    expect(links[5].textContent).toBe 'Flash'

  it 'navigates to /perception when Perception tab clicked', ->
    renderApp()
    user = userEvent.setup()
    link = getTabLink 'Perception'
    expect(link).toBeTruthy()
    user.click(link).then ->
      el = document.querySelector '.layout-perception'
      expect(el).toBeInTheDocument()

  it 'navigates to /flight when Flight tab clicked', ->
    renderApp()
    user = userEvent.setup()
    link = getTabLink 'Flight'
    expect(link).toBeTruthy()
    user.click(link).then ->
      el = document.querySelector '.layout-flight'
      expect(el).toBeInTheDocument()

  it 'navigates to /wings from /perception via Wings tab', ->
    renderApp('/perception')
    user = userEvent.setup()
    link = getTabLink 'Wings'
    expect(link).toBeTruthy()
    user.click(link).then ->
      el = document.querySelector '.layout-wings'
      expect(el).toBeInTheDocument()