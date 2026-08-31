import './FlashProgress.sass'
import { motion } from 'framer-motion'
import { createElement as h } from 'react'

PHASE_GLYPHS =
  idle:      '🪶'
  scanning:  '📡'
  ready:     '🥚'
  erasing:   '🌀'
  writing:   '⚡'
  verifying: '🧿'
  done:      '🐦'
  error:     '💥'
  reboot:    '🐣'

R = 54
CIRC = 2 * Math.PI * R

FlashProgress = ({ phase = 'idle', progress = 0, label = '' }) ->
  pct = Math.max 0, Math.min 100, (progress || 0)
  offset = CIRC * (1 - pct / 100)
  glyph = PHASE_GLYPHS[phase] || '◇'

  h 'div', { className: "flash-progress phase-#{phase}" },
    h 'div', { className: 'flash-ring' },
      h 'svg', { width: 132, height: 132, viewBox: '0 0 132 132' },
        h 'circle', { className: 'ring-track', cx: 66, cy: 66, r: R, fill: 'none', strokeWidth: 8 }
        h 'circle', {
          className: 'ring-value'
          cx: 66
          cy: 66
          r: R
          fill: 'none'
          strokeWidth: 8
          strokeDasharray: CIRC
          strokeDashoffset: offset
        }
      h motion.span,
        className: 'flash-glyph'
        key: phase
        initial: { scale: 0.7, opacity: 0, rotate: -8 }
        animate: { scale: 1, opacity: 1, rotate: 0 }
        transition: { type: 'spring', stiffness: 260, damping: 18 }
      , glyph
    h 'div', { className: 'flash-phase-label' }, label
    h 'div', { className: 'flash-percent' }, "#{Math.round pct}%"

export default FlashProgress
