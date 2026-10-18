import { render, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import { MemoryRouter } from 'react-router-dom'
import ModesView from '../components/views/ModesView/ModesView.chaml'
import useModesStore from '../stores/useModesStore.coffee'

# Regression: the dual-range slider in /control/modes must actually
# write through to the store. A multiline HAML `%DualRangeSlider{...}`
# attribute block once compiled `onLow`/`onHigh` as *children strings*
# instead of props, leaving the thumbs unmovable. This test fires a
# pointer on the low thumb and asserts the draft startStep changes.
describe 'ModesView dual-range wiring', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    useModesStore.getState().reset()

  afterEach ->
    vi.restoreAllMocks()

  renderView = -> render h(MemoryRouter, null, h(ModesView, null))

  it 'routes the low-thumb drag into setRangeField', ->
    renderView()
    low = document.querySelector '.dual-range-thumb.dual-range-low'
    expect(low).toBeInTheDocument()
    expect(useModesStore.getState().draft.ranges[0].startStep).toBe 0
    fireEvent.pointerDown low, { clientX: 200 }
    expect(useModesStore.getState().draft.ranges[0].startStep).toBeGreaterThan 0

  it 'renders a spread band for every slot', ->
    renderView()
    sliders = document.querySelectorAll '.dual-range'
    expect(sliders.length).toBe 20
    fills = document.querySelectorAll '.dual-range-fill'
    expect(fills.length).toBe 20
