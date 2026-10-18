###
# ORNIFLIGHT STUDIO — StrokeScope
#
# The living waveform: a canvas oscilloscope that reads the 60 Hz
# telemetry history directly (imperatively, no React re-render) and
# draws five synchronised bands —
#   · wing      — left/right wing angle in motion (the differential breath)
#   · servo     — the four waveformed PWM outputs, one envelope
#   · gyro      — roll/pitch/yaw, auto-scaled (the closed-loop response)
#   · ferocity  — live stroke/return/shapeMix over time (the signature)
#   · cadence   — the instantaneous modulated flap cadence (the tempo)
#
# Each band's curves are configurable: a legend names every visible
# trace, and a "•••" menu toggles curves on/off (grouped by band).
# A "now" cursor rides the right edge, a bead tracks the current left
# wing angle, and the phase readout follows flapPhase. Offline (no
# history) the canvas hides and an empty state breathes instead.
###
import { useEffect, useRef, useState } from 'react'
import h from '../../../app/h.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import { buildScopeBands } from './scopeGeometry.coffee'
import { SCOPE_BANDS, SCOPE_CURVES, curvesInBand } from './scopeCatalog.coffee'
import { useI18n } from '../../../i18n/index.coffee'

# ——— theme ——— read once per 500 ms (theme can flip live) ———
_themeCache = null
_themeAt = 0
readTheme = ->
  now = Date.now()
  return _themeCache if _themeCache and now - _themeAt < 500
  cs = getComputedStyle document.documentElement
  v = (name, fb) ->
    val = cs.getPropertyValue(name).trim()
    if val then val else fb
  colors = {}
  colors[curve.id] = v curve.theme, '#888' for curve in SCOPE_CURVES
  colors.grid  = v '--of-border-2', 'rgba(255,255,255,0.08)'
  colors.zero  = v '--of-border-1', 'rgba(255,255,255,0.14)'
  colors.muted = v '--of-text-muted', '#8b93a7'
  _themeCache = colors
  _themeAt = now
  _themeCache

# Map a normalised [x, y] (0..1) band point into pixel space.
polyPixels = (points, width, top, height) ->
  for [x, y] in points
    [x * width, top + y * height]

strokePoly = (ctx, pts, color, width = 1.5, dash = []) ->
  return unless pts.length > 1
  ctx.strokeStyle = color
  ctx.lineWidth = width
  ctx.setLineDash dash
  ctx.beginPath()
  ctx.moveTo pts[0][0], pts[0][1]
  for [x, y] in pts[1..]
    ctx.lineTo x, y
  ctx.stroke()
  ctx.setLineDash []

# Lay the five bands out top→bottom from their fraction of the canvas.
layoutBands = (hgt) ->
  gap = 4
  totalGap = gap * (SCOPE_BANDS.length - 1)
  avail = Math.max 1, hgt - totalGap
  top = 0
  SCOPE_BANDS.map (band) ->
    height = avail * band.frac
    rect = { id: band.id, label: band.label, top: top, height: height }
    top += height + gap
    rect

# Pure render of the scope onto a 2D context at CSS-pixel size.
drawScope = (canvas, ctx, state, hidden = {}) ->
  t = readTheme()
  rect = canvas.getBoundingClientRect()
  wid = rect.width
  hgt = rect.height
  return if wid < 20 or hgt < 20
  dpr = window.devicePixelRatio or 1
  pw = Math.round wid * dpr
  ph = Math.round hgt * dpr
  if canvas.width isnt pw or canvas.height isnt ph
    canvas.width = pw
    canvas.height = ph
  ctx.setTransform dpr, 0, 0, dpr, 0, 0
  ctx.clearRect 0, 0, wid, hgt

  history = state.waveformHistory ? []
  bands = buildScopeBands history, state.amplitude
  bandRects = layoutBands hgt

  for band in bandRects
    { top, height } = band
    # Grid + zero line per band.
    ctx.strokeStyle = t.grid
    ctx.lineWidth = 1
    ctx.setLineDash [3, 5]
    ctx.beginPath()
    ctx.moveTo 0, top + height / 2
    ctx.lineTo wid, top + height / 2
    ctx.stroke()
    ctx.setLineDash []

    # Band label — small, top-left, muted.
    ctx.fillStyle = t.muted
    ctx.font = '9px "JetBrains Mono", "SF Mono", monospace'
    ctx.fillText band.label.toUpperCase(), 6, top + 10

    # Visible curves in this band.
    lw = if band.id is 'wing' then 1.6 else 1.2
    for curve in curvesInBand band.id
      continue if hidden[curve.id]
      pts = bands[curve.id]
      continue unless pts?.length > 1
      strokePoly ctx, polyPixels(pts, wid, top, height), t[curve.id], lw, curve.dash

  # "Now" cursor + bead on the current left wing angle.
  last = history[history.length - 1]
  if last?
    nowX = wid - 0.5
    firstBand = bandRects[0]
    lastBand = bandRects[bandRects.length - 1]
    ctx.strokeStyle = t.muted
    ctx.lineWidth = 1
    ctx.setLineDash [2, 3]
    ctx.beginPath()
    ctx.moveTo nowX, firstBand.top
    ctx.lineTo nowX, lastBand.top + lastBand.height
    ctx.stroke()
    ctx.setLineDash []

    { lo, hi } = bands.wingRange ? { lo: -45, hi: 45 }
    span = hi - lo
    span = 1 if span <= 0
    beadY = firstBand.top + (1 - ((last.wingL ? 0) - lo) / span) * firstBand.height
    beadY = Math.max firstBand.top, Math.min firstBand.top + firstBand.height, beadY
    ctx.fillStyle = t.wingL
    ctx.beginPath()
    ctx.arc nowX, beadY, 3, 0, Math.PI * 2
    ctx.fill()

# ——— Component ———
StrokeScope = ->
  wrapRef    = useRef null
  canvasRef  = useRef null
  emptyRef   = useRef null
  menuRef    = useRef null
  [hidden, setHidden] = useState {}
  [menuOpen, setMenuOpen] = useState false
  hiddenRef = useRef hidden
  hiddenRef.current = hidden
  { t } = useI18n()

  useEffect ->
    canvas = canvasRef.current
    ctx = canvas.getContext '2d'
    return unless ctx
    empty = emptyRef.current
    raf = null
    tick = ->
      state = useTelemetryStore.getState()
      history = state.waveformHistory ? []
      hasData = history.length > 1 and state.source isnt 'offline'
      if empty then empty.style.display = if hasData then 'none' else ''
      drawScope canvas, ctx, state, hiddenRef.current if hasData
      raf = requestAnimationFrame tick
    raf = requestAnimationFrame tick
    -> cancelAnimationFrame raf if raf
  , []

  # Close the config menu on outside pointer.
  useEffect ->
    return unless menuOpen
    close = (event) ->
      setMenuOpen false unless menuRef.current?.contains event.target
    document.addEventListener 'pointerdown', close
    -> document.removeEventListener 'pointerdown', close
  , [menuOpen]

  toggleCurve = (id) ->
    setHidden (prev) ->
      next = { prev... }
      if next[id] then delete next[id] else next[id] = true
      next

  visible = SCOPE_CURVES.filter (curve) -> not hidden[curve.id]

  legend = h 'div', { className: 'scope-legend', 'aria-hidden': true },
    visible.map (curve) ->
      h 'span', { className: 'scope-legend-chip', key: curve.id },
        h('span',
          { className: 'scope-legend-swatch',
            style: { background: "var(#{curve.theme})" } }),
        h('span', { className: 'scope-legend-label' }, curve.shortLabel)

  menu = null
  if menuOpen
    menu = h 'div', {
      className: 'scope-menu'
      ref: menuRef
      role: 'dialog'
      'aria-label': t('schlagdynamik.scopeConfigure')
    },
      SCOPE_BANDS.map (band) ->
        h 'fieldset', { className: 'scope-menu-group', key: band.id },
          h('legend', null, band.label),
          curvesInBand(band.id).map (curve) ->
            active = not hidden[curve.id]
            h 'label', { className: 'scope-curve-option', key: curve.id },
              h('input', {
                type: 'checkbox'
                checked: active
                onChange: -> toggleCurve curve.id
              }),
              h('span',
                { className: 'scope-swatch',
                  style: { background: "var(#{curve.theme})" } }),
              h('span', { className: 'scope-option-label' }, curve.label)

  h 'div',
    { className: 'stroke-scope', ref: wrapRef },
    h 'div', { className: 'scope-toolbar' },
      legend,
      h 'button', {
        type: 'button'
        className: 'scope-config-trigger'
        title: t('schlagdynamik.scopeConfigure')
        'aria-label': t('schlagdynamik.scopeConfigure')
        'aria-expanded': menuOpen
        onClick: -> setMenuOpen not menuOpen
      }, '•••'
    h('canvas',
      { ref: canvasRef, className: 'stroke-scope-canvas',
        'aria-label': t('schlagdynamik.scopeLabel') })
    h('div',
      { className: 'stroke-scope-empty', ref: emptyRef },
      h('span', { className: 'stroke-scope-empty-glyph' }, '∿'),
      h('span', null, t('schlagdynamik.scopeEmpty')))
    menu

export default StrokeScope