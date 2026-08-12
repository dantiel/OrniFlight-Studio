import './WaveformPlot.sass'
import { useEffect, useRef, createElement } from 'react'

# ═══════════════════════════════════════════════════════════════
# Waveform Canvas
# Receives history array: [{t, wingL, wingR, gyroRoll, gyroPitch, gyroYaw}]
# curves prop: array of curve ids to render, e.g. ['wingL', 'wingR']
# Supported: wingL, wingR, gyroRoll, gyroPitch, gyroYaw
# ═══════════════════════════════════════════════════════════════

CURVE_COLORS =
  wingL:    '#f0883e'
  wingR:    '#58a6ff'
  gyroRoll: '#f85149'
  gyroPitch: '#3fb950'
  gyroYaw:  '#bc8cff'

CURVE_LABELS =
  wingL:    'Wing L'
  wingR:    'Wing R'
  gyroRoll: 'Gyro Roll'
  gyroPitch: 'Gyro Pitch'
  gyroYaw:  'Gyro Yaw'

WaveformPlot = ({ history, curves }) ->
  canvasRef = useRef null
  
  useEffect ->
    canvas = canvasRef.current
    return unless canvas
    
    ctx = canvas.getContext '2d'
    w = canvas.width = canvas.clientWidth * (window.devicePixelRatio or 1)
    h = canvas.height = canvas.clientHeight * (window.devicePixelRatio or 1)
    ctx.scale window.devicePixelRatio or 1, window.devicePixelRatio or 1
    cw = canvas.clientWidth
    ch = canvas.clientHeight
    
    # Clear
    ctx.fillStyle = '#0d1117'
    ctx.fillRect 0, 0, cw, ch
    
    # Grid
    ctx.strokeStyle = '#1c2333'
    ctx.lineWidth = 0.5
    for i in [0..4]
      y = (ch / 4) * i
      ctx.beginPath()
      ctx.moveTo 0, y
      ctx.lineTo cw, y
      ctx.stroke()
    for i in [0..8]
      x = (cw / 8) * i
      ctx.beginPath()
      ctx.moveTo x, 0
      ctx.lineTo x, ch
      ctx.stroke()
    
    # Zero line
    ctx.strokeStyle = '#30363d'
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo 0, ch / 2
    ctx.lineTo cw, ch / 2
    ctx.stroke()
    
    return unless history and history.length > 1
    activeCurves = curves or ['wingL', 'wingR']
    
    # Scale: show last 3 seconds
    maxT = history[history.length - 1].t
    minT = Math.max 0, maxT - 3.0
    
    timeToX = (t) -> ((t - minT) / Math.max(0.001, maxT - minT)) * cw
    
    # Determine if we're showing gyro (rate) or wing (angle) data
    hasGyro = activeCurves.some (c) -> c.indexOf('gyro') == 0
    hasWing = activeCurves.some (c) -> c.indexOf('wing') == 0
    
    # Amplitude scale
    if hasGyro and not hasWing
      # Gyro rates: ±720 °/s
      ampScale = ch / 1440
    else
      # Wing angles: ±60°
      ampScale = ch / 120
    centerY = ch / 2
    
    valueToY = (v) -> centerY - v * ampScale
    
    # Draw each selected curve
    legendY = 14
    for curveId, idx in activeCurves
      color = CURVE_COLORS[curveId] or '#ffffff'
      ctx.strokeStyle = color
      ctx.lineWidth = 1.5
      ctx.beginPath()
      first = true
      for pt in history
        continue if pt.t < minT
        x = timeToX pt.t
        val = pt[curveId] or 0
        # Convert gyro values from rad/s to °/s
        val = val * 180 / Math.PI if curveId.indexOf('gyro') == 0
        y = valueToY val
        if first
          ctx.moveTo x, y
          first = false
        else
          ctx.lineTo x, y
      ctx.stroke()
      
      # Legend
      ctx.font = '10px "SF Mono", "Fira Code", monospace'
      ctx.fillStyle = color
      ctx.fillText CURVE_LABELS[curveId] or curveId, 8, legendY
      legendY += 14
    return
  , [history, curves]
  
  createElement 'canvas', { className: 'waveform-canvas', ref: canvasRef }

export default WaveformPlot