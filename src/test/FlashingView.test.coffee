import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'

MANIFEST = { images: [
  { name: 'OrniFlight', target: 'ORNI-F4', version: '2.1.0', channel: 'stable', size: 262144 }
  { name: 'OrniFlight', target: 'ORNI-F4', version: '2.0.0', channel: 'stable', size: 249856 }
] }

describe 'FlashingView', ->
  beforeEach ->
    vi.stubGlobal 'fetch', vi.fn ->
      Promise.resolve { ok: true, json: -> Promise.resolve MANIFEST }

  afterEach ->
    vi.unstubAllGlobals()

  renderApp = (route = '/flash') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  it 'renders the flashing layout', ->
    renderApp()
    el = document.querySelector '.layout-flash'
    expect(el).toBeInTheDocument()

  it 'renders the device target and console', ->
    renderApp()
    expect(screen.getByText 'Firmware Images').toBeInTheDocument()
    expect(screen.getByText 'Flash Log').toBeInTheDocument()

  it 'loads the catalog and lists firmware cards', ->
    renderApp()
    card = await screen.findByText 'v2.1.0'
    expect(card).toBeInTheDocument()

  it 'enables the flash button after selecting firmware', ->
    renderApp()
    card = await screen.findByText 'v2.1.0'
    fireEvent.click card.closest('button')
    btn = screen.getByText 'FLASH FIRMWARE'
    expect(btn.closest('button').disabled).toBe false

  it 'offers loading a local image from disk', ->
    renderApp()
    await screen.findByText 'Firmware Images'
    input = document.querySelector '.fw-local-input'
    expect(screen.getByText 'Load local image').toBeInTheDocument()
    expect(input).toBeInTheDocument()
    expect(input.getAttribute('accept')).toContain '.bin'