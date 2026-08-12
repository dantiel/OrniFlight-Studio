import './GyroBars.sass'
import { useEffect, useRef, createElement } from 'react'

# ═══════════════════════════════════════════════════════════════
# Gyro Readout — simple bar display of gyro rates
# ═══════════════════════════════════════════════════════════════

GyroBars = ({ gyro }) ->
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
    
    # Background
    ctx.fillStyle = '#0d1117'
    ctx.fillRect 0, 0, cw, ch
    
    barH = 14
    gap = 8
    maxRate = 720  # °/s
    labelW = 48
    barX = labelW + 8
    barMaxW = cw - barX - 60
    
    axes = [
      { name: 'ROLL',  color: '#f0883e', value: (gyro?.roll  or 0) * 180 / Math.PI }
      { name: 'PITCH', color: '#58a6ff', value: (gyro?.pitch or 0) * 180 / Math.PI }
      { name: 'YAW',   color: '#3fb950', value: (gyro?.yaw   or 0) * 180 / Math.PI }
    ]
    
    ctx.font = '10px "SF Mono", "Fira Code", monospace'
    
    for axis, i in axes
      y = 16 + i * (barH + gap)
      
      # Label
      ctx.fillStyle = '#8b949e'
      ctx.textAlign = 'right'
      ctx.fillText axis.name, barX - 6, y + barH - 3
      
      # Bar background
      ctx.fillStyle = '#1c2333'
      ctx.fillRect barX, y, barMaxW, barH
      
      # Bar fill
      barLen = Math.min(Math.abs(axis.value) / maxRate * barMaxW, barMaxW)
      ctx.fillStyle = axis.color
      if axis.value >= 0
        ctx.fillRect barX + barMaxW / 2, y, barLen, barH
      else
        ctx.fillRect barX + barMaxW / 2 - barLen, y, barLen, barH
      
      # Center line
      ctx.fillStyle = '#30363d'
      ctx.fillRect barX + barMaxW / 2 - 0.5, y, 1, barH
      
      # Value
      ctx.fillStyle = '#e6edf3'
      ctx.textAlign = 'left'
      ctx.fillText "#{axis.value.toFixed(0)}°/s", barX + barMaxW + 6, y + barH - 3
    return
  , [gyro]
  
  createElement 'canvas', { className: 'gyro-canvas', ref: canvasRef }

export default GyroBars