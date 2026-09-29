import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { createElement as h } from 'react'
import { MemoryRouter } from 'react-router-dom'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import App from '../app/App.chaml'
import useDeviceStore from '../stores/useDeviceStore.coffee'
import useFirmwareStore from '../stores/useFirmwareStore.coffee'

MANIFEST = { images: [
  { name: 'OrniFlight', target: 'ORNI-F4', version: '2.1.0', channel: 'stable', size: 262144 }
  { name: 'OrniFlight', target: 'ORNI-F4', version: '2.0.0', channel: 'stable', size: 249856 }
] }

describe 'FlashingView', ->
  beforeEach ->
    vi.stubGlobal 'fetch', vi.fn ->
      Promise.resolve { ok: true, json: -> Promise.resolve MANIFEST }

  afterEach ->
    useDeviceStore.getState().setSimulation()
    vi.unstubAllGlobals()

  renderApp = (route = '/system/flash') ->
    render h(MemoryRouter, { initialEntries: [route] }, h(App, null))

  it 'renders the flashing layout', ->
    renderApp()
    el = document.querySelector '.layout-flash'
    expect(el).toBeInTheDocument()
    # Migrated off the fixed grid: vertical parallax document.
    expect(document.querySelector '.molt-view').toBeInTheDocument()
    expect(document.querySelector '.molt-stage-grid').toBeInTheDocument()

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
    # The sticky control deck arms itself too.
    expect(document.querySelector('.deck-flash').disabled).toBe false

  it 'carries a functional sticky control deck', ->
    renderApp()
    expect(document.querySelector '.molt-deck').toBeInTheDocument()
    deck = document.querySelector '.deck-flash'
    expect(deck).toBeInTheDocument()
    # The deck always carries its own action label.
    expect(deck.textContent).toContain 'FLASH'

  it 'offers the bootloader bridge when a device session is live', ->
    # Serial capability is captured at store creation — seed it, since
    # jsdom has no navigator.serial.
    useFirmwareStore.setState { serialSupported: true }
    useDeviceStore.getState().setDevice {
      name: 'tiny-bird'
      board: { targetName: 'TINYFISH' }
      firmware: { version: '1.46.0' }
    }
    renderApp()
    btn = await screen.findByText 'Enter bootloader'
    expect(btn).toBeEnabled()
    expect(screen.getByText 'CONNECTED').toBeInTheDocument()
    # The deck arms the bridge as its primary action.
    deck = document.querySelector '.deck-flash'
    expect(deck.textContent).toContain 'BOOTLOADER'
    expect(deck.disabled).toBe false

  it 'pairs the flash stage with the console side by side', ->
    renderApp()
    deck = document.querySelector '#molt-flash-deck'
    expect(deck).toBeInTheDocument()
    expect(deck.querySelector '.molt-stage-grid').toBeInTheDocument()
    expect(deck.querySelector '.deck-console').toBeInTheDocument()

  it 'spotlights the flash deck when a card is chosen', ->
    renderApp()
    await waitFor (-> document.querySelector '.fw-card')
    fireEvent.click document.querySelector '.fw-card'
    deck = document.querySelector '#molt-flash-deck'
    expect(deck.classList.contains('molt-spotlight')).toBe true

  it 'offers loading a local image from disk', ->
    renderApp()
    await screen.findByText 'Firmware Images'
    input = document.querySelector '.fw-local-input'
    expect(screen.getByText 'Load local image').toBeInTheDocument()
    expect(input).toBeInTheDocument()
    expect(input.getAttribute('accept')).toContain '.bin'