import { render, fireEvent, screen } from '@testing-library/react'
import { createElement as h, memo, useState } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import PidTuningView from '../components/views/PidTuningView/PidTuningView.coffee'
import MockRow from '../components/primitives/ParamRow/ParamRow.chaml'
import useTuningStore from '../stores/useTuningStore.coffee'

# Render-count probe for the ParamRow memo contract. The real ParamRow is
# memoized; PidTuningView must hand it stable handler references (see
# fieldHandlers.coffee), otherwise every keystroke re-renders all 29 rows.
# The mock factory is synchronous — async factories break under the
# CoffeeScript transform; imports are already evaluated when it runs.
renderCount = 0
lastRowProps = null

vi.mock '../components/primitives/ParamRow/ParamRow.chaml', ->
  row = (props) ->
    renderCount += 1
    lastRowProps = props
    h 'div', { className: 'param-row' },
      h 'input',
        className: 'param-slider'
        type: 'range'
        value: String(props.value ? 0)
        onInput: props.onInput
  { default: row }

describe 'mock memo probe', ->
  it 're-renders a memoized row when its props change', ->
    stable = (->)
    Container = (props) ->
      [n, setN] = useState 0
      h 'div', null,
        h MockRow, { value: n, onInput: stable }
        h 'button', { onClick: (-> setN 1) }, 'bump'
    render h(Container, null)
    expect(renderCount).toBe 1
    fireEvent.click screen.getByText 'bump'
    expect(renderCount).toBe 2

describe 'PidTuningView render efficiency', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    renderCount = 0
    useTuningStore.getState().reset()

  afterEach ->
    vi.restoreAllMocks()

  it 'only re-renders the edited row, not all 29', ->
    render h(PidTuningView, null)
    # Open only the closed sections. PID Bank is defaultOpen — clicking
    # its trigger would close it, and the mocked rAF never completes the
    # framer-motion exit animation, so its body would linger as a stale
    # snapshot whose rows can never re-render.
    for trigger in document.querySelectorAll '.studio-accordion-trigger'
      if trigger.getAttribute('aria-expanded') == 'false'
        fireEvent.click trigger
    baseline = renderCount
    expect(baseline).toBe 12 + 3 + 10 + 4
    slider = document.querySelector '.param-slider'
    fireEvent.input slider, { target: { value: '6.5' } }
    expect(useTuningStore.getState().draft.pid.roll.P).toBe 6.5
    expect(screen.getByText 'UNSAVED').toBeInTheDocument()
    expect(renderCount).toBe baseline + 1
    expect(lastRowProps.value).toBe 6.5
    expect(
      document.querySelector('.param-slider').getAttribute 'value'
    ).toBe '6.5'