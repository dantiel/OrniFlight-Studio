import './WaveformPlot.sass'
import { useEffect, useRef, createElement } from 'react'
import { curveFor } from '../../../telemetry/curveCatalog.coffee'

clamp = (min, max, value) -> Math.max min, Math.min max, value

WaveformPlot = ({ history = [], curves = [] }) ->
  canvasRef = useRef null
  latestRef = useRef { history, curves }
  drawRef = useRef null

  latestRef.current = { history, curves }

  useEffect ->
    canvas = canvasRef.current
    return unless canvas
    frame = null

    draw = ->
      canvas = canvasRef.current
      return unless canvas
      rect = canvas.getBoundingClientRect()
      width = Math.floor rect.width
      height = Math.floor rect.height
      return unless width > 1 and height > 1

      dpr = Math.min window.devicePixelRatio or 1, 2
      pixelWidth = Math.floor width * dpr
      pixelHeight = Math.floor height * dpr
      if canvas.width isnt pixelWidth or canvas.height isnt pixelHeight
        canvas.width = pixelWidth
        canvas.height = pixelHeight

      ctx = canvas.getContext '2d'
      return unless ctx
      ctx.setTransform dpr, 0, 0, dpr, 0, 0
      styles = getComputedStyle canvas
      background = styles.getPropertyValue('--plot-background').trim() or '#151519'
      grid = styles.getPropertyValue('--plot-grid').trim() or 'rgba(255,255,255,.06)'
      zero = styles.getPropertyValue('--plot-zero').trim() or 'rgba(255,255,255,.14)'
      text = styles.getPropertyValue('--plot-text').trim() or '#9c9ca4'

      ctx.clearRect 0, 0, width, height
      ctx.fillStyle = background
      ctx.fillRect 0, 0, width, height

      top = 28
      bottom = height - 8
      plotHeight = Math.max 1, bottom - top

      ctx.strokeStyle = grid
      ctx.lineWidth = 1
      for i in [0..4]
        y = top + (plotHeight / 4) * i
        ctx.beginPath()
        ctx.moveTo 0, Math.round(y) + .5
        ctx.lineTo width, Math.round(y) + .5
        ctx.stroke()
      for i in [0..8]
        x = (width / 8) * i
        ctx.beginPath()
        ctx.moveTo Math.round(x) + .5, top
        ctx.lineTo Math.round(x) + .5, bottom
        ctx.stroke()

      ctx.strokeStyle = zero
      ctx.beginPath()
      ctx.moveTo 0, top + plotHeight / 2
      ctx.lineTo width, top + plotHeight / 2
      ctx.stroke()

      current = latestRef.current
      active = current.curves.map(curveFor).filter(Boolean)
      samples = current.history or []

      if samples.length < 2 or active.length is 0
        ctx.fillStyle = text
        ctx.font = '10px "JetBrains Mono", "SF Mono", monospace'
        message = if active.length then 'WAITING FOR TELEMETRY' else 'CHOOSE A CURVE'
        ctx.fillText message, 10, top + 18
        return

      maxT = samples[samples.length - 1].t or 0
      minT = Math.max 0, maxT - 4
      spanT = Math.max .001, maxT - minT
      timeToX = (t) -> ((t - minT) / spanT) * width

      legendX = 9
      for curve in active
        [domainMin, domainMax] = curve.domain
        span = Math.max .001, domainMax - domainMin
        valueToY = (value) ->
          normalized = clamp 0, 1, (value - domainMin) / span
          bottom - normalized * plotHeight

        ctx.strokeStyle = curve.color
        ctx.lineWidth = 1.5
        ctx.lineJoin = 'round'
        ctx.beginPath()
        started = false
        for sample in samples when (sample.t or 0) >= minT
          value = sample[curve.id]
          continue unless Number.isFinite value
          x = timeToX sample.t or 0
          y = valueToY value
          if started then ctx.lineTo x, y else ctx.moveTo x, y
          started = true
        ctx.stroke() if started

        latest = samples[samples.length - 1][curve.id]
        label = curve.shortLabel
        if Number.isFinite latest
          precision = if Math.abs(latest) < 20 then 1 else 0
          label += " #{latest.toFixed(precision)}#{curve.unit}"
        ctx.font = '10px "JetBrains Mono", "SF Mono", monospace'
        labelWidth = ctx.measureText(label).width
        break if legendX + labelWidth > width - 8
        ctx.fillStyle = curve.color
        ctx.fillText label, legendX, 17
        legendX += labelWidth + 14

    scheduleDraw = ->
      cancelAnimationFrame frame if frame?
      frame = requestAnimationFrame draw

    drawRef.current = scheduleDraw
    observer = new ResizeObserver scheduleDraw
    observer.observe canvas
    scheduleDraw()

    ->
      cancelAnimationFrame frame if frame?
      observer.disconnect()
      drawRef.current = null
  , []

  useEffect ->
    drawRef.current?()
    return
  , [history, curves]

  createElement 'div', { className: 'waveform-plot' },
    createElement 'canvas', {
      className: 'waveform-canvas'
      ref: canvasRef
      role: 'img'
      'aria-label': 'Live telemetry plot'
    }

export default WaveformPlot
