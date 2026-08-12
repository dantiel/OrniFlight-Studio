###
# ORNIFLIGHT STUDIO — Suspense Fallback (React 18 Concurrent)
# Rendered while lazy route chunks load.
# Motion skeleton with shimmer effect.
###
import { createElement as h } from 'react'
import { motion } from 'framer-motion'

shimmerVariants =
  animate:
    backgroundPosition: ['200% 0', '-200% 0']
    transition: { repeat: Infinity, duration: 1.6, ease: 'linear' }

SuspenseFallback = ->
  h motion.div,
    className: 'suspense-fallback'
    initial: { opacity: 0 }
    animate: { opacity: 1 }
    exit: { opacity: 0 }
    transition: { duration: 0.15 }
    h 'div', { className: 'suspense-shell' },
      h 'div', { className: 'suspense-bar', style: { width: '60%' } }
      h 'div', { className: 'suspense-bar', style: { width: '40%' } }
      h 'div', { className: 'suspense-bar', style: { width: '75%' } }
      h 'div', { className: 'suspense-bar', style: { width: '35%' } }
      h 'div', { className: 'suspense-bar', style: { width: '55%' } }

export default SuspenseFallback
