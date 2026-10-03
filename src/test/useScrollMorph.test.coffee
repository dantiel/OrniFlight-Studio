import { renderHook, act } from '@testing-library/react'
import { describe, it, expect, vi, afterEach } from 'vitest'
import useScrollMorph from '../hooks/useScrollMorph.coffee'

afterEach ->
  vi.restoreAllMocks()
  vi.unstubAllGlobals()
  document.body.innerHTML = ''

it 'tracks actual docking, wrapped height and undocking even with reduced motion', ->
  document.body.innerHTML = '<div class="studio-shell"><div class="connection-bar"></div><main id="main-content"><div class="morph-doc"><div class="morph-head-title"></div><div class="morph-deck"></div></div></main></div>'
  shell = document.querySelector '.studio-shell'
  host = document.querySelector '.morph-doc'
  deck = document.querySelector '.morph-deck'
  toolbar = document.querySelector '.connection-bar'
  scroll = document.getElementById 'main-content'
  top = 250
  height = 48
  frame = null
  resized = null
  vi.stubGlobal 'matchMedia', -> { matches: true }
  vi.stubGlobal 'requestAnimationFrame', (cb) ->
    frame = cb
    1
  vi.stubGlobal 'cancelAnimationFrame', vi.fn()
  vi.stubGlobal 'ResizeObserver', class
    constructor: (cb) -> resized = cb
    observe: ->
    disconnect: ->
  vi.spyOn(toolbar, 'getBoundingClientRect').mockImplementation -> { height: 70 }
  vi.spyOn(scroll, 'getBoundingClientRect').mockImplementation -> { top: 0 }
  vi.spyOn(deck, 'getBoundingClientRect').mockImplementation -> { top, height, bottom: top + height }
  { unmount } = renderHook -> useScrollMorph { current: host }
  expect(shell.style.getPropertyValue '--of-safe-area-bar').toBe '70px'
  top = 70
  act ->
    scroll.dispatchEvent new Event 'scroll'
    frame()
  expect(host.classList.contains 'morph-stuck').toBe true
  expect(shell.style.getPropertyValue '--of-safe-area-bar').toBe '118px'
  expect(host.style.getPropertyValue '--head-morph').toBe '0.000'
  height = 96
  act ->
    resized()
    frame()
  expect(shell.style.getPropertyValue '--of-safe-area-bar').toBe '166px'
  top = 120
  act ->
    scroll.dispatchEvent new Event 'scroll'
    frame()
  expect(host.classList.contains 'morph-stuck').toBe false
  expect(shell.style.getPropertyValue '--of-safe-area-bar').toBe '70px'
  unmount()
  expect(shell.style.getPropertyValue '--of-safe-area-bar').toBe ''
