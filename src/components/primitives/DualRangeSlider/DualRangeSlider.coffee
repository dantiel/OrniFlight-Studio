import './DualRangeSlider.sass'
import h from '../../../app/h.coffee'
import { useRef } from 'react'

clamp = (v, lo, hi) -> Math.max lo, Math.min hi, v
pct = (v, min, max) -> clamp((v - min) / (max - min), 0, 1) * 100

# One track, two thumbs — a lower and an upper bound on a single rail.
# The thumbs are plain divs driven by pointer events (not overlapping
# native range inputs), so dragging is deterministic and the upper
# thumb always sits above the lower one when they collapse.
DualRangeSlider = ({ min, max, step = 1, low, high, onLow, onHigh,
                     lowLabel, highLabel, disabled = false }) ->
  low ?= min
  high ?= max
  trackRef = useRef null

  valueAt = (clientX) ->
    rect = trackRef.current?.getBoundingClientRect()
    return null unless rect?
    ratio = clamp (clientX - rect.left) / rect.width, 0, 1
    clamp min + Math.round((ratio * (max - min)) / step) * step, min, max

  apply = (which, value) ->
    if which == 'low'
      onLow? clamp value, min, high
    else
      onHigh? clamp value, low, max

  drag = (which) -> (e) ->
    return if disabled
    e.preventDefault()
    e.stopPropagation()
    v = valueAt e.clientX
    apply which, v if v?
    move = (ev) ->
      v = valueAt ev.clientX
      apply which, v if v?
    end = ->
      window.removeEventListener 'pointermove', move
      window.removeEventListener 'pointerup', end
      window.removeEventListener 'pointercancel', end
    window.addEventListener 'pointermove', move
    window.addEventListener 'pointerup', end
    window.addEventListener 'pointercancel', end

  key = (which) -> (e) ->
    return if disabled
    delta = 0
    switch e.key
      when 'ArrowLeft', 'ArrowDown' then delta = -step
      when 'ArrowRight', 'ArrowUp' then delta = step
      when 'Home' then delta = min - (if which == 'low' then low else high)
      when 'End' then delta = max - (if which == 'low' then low else high)
      else return
    e.preventDefault()
    apply which, (if which == 'low' then low else high) + delta

  # Clicking the rail jumps the nearer thumb to the pointer.
  jump = (e) ->
    return if disabled
    v = valueAt e.clientX
    return unless v?
    if Math.abs(v - low) <= Math.abs(v - high)
      onLow? clamp v, min, high
    else
      onHigh? clamp v, low, max

  loPct = pct low, min, max
  hiPct = pct high, min, max

  h 'div', { className: "dual-range#{if disabled then ' is-disabled' else ''}" },
    h 'div', { className: 'dual-range-track', ref: trackRef, onPointerDown: jump },
      h 'div', { className: 'dual-range-rail' },
        h 'div', {
          className: 'dual-range-fill'
          style: { left: "#{loPct}%", width: "#{hiPct - loPct}%" }
        }
      h 'div', {
        className: 'dual-range-thumb dual-range-low'
        style: { left: "#{loPct}%" }
        role: 'slider'
        tabIndex: if disabled then -1 else 0
        'aria-valuemin': min
        'aria-valuemax': max
        'aria-valuenow': low
        'aria-label': lowLabel or 'Lower bound'
        onPointerDown: drag 'low'
        onKeyDown: key 'low'
      }
      h 'div', {
        className: 'dual-range-thumb dual-range-high'
        style: { left: "#{hiPct}%" }
        role: 'slider'
        tabIndex: if disabled then -1 else 0
        'aria-valuemin': min
        'aria-valuemax': max
        'aria-valuenow': high
        'aria-label': highLabel or 'Upper bound'
        onPointerDown: drag 'high'
        onKeyDown: key 'high'
      }
    h 'div', { className: 'dual-range-labels' },
      h 'span', { className: 'dual-range-label dual-range-label-low' },
        lowLabel
      h 'span', { className: 'dual-range-label dual-range-label-high' },
        highLabel

export default DualRangeSlider
