###
# ORNIFLIGHT STUDIO — AnimatedPage
# Wraps children in Framer Motion page transition (fade + slide)
# Used by App.chaml for route-level enter/exit animations
###

import { motion } from 'framer-motion'
import { createElement as h } from 'react'

pageVariants =
  initial: { opacity: 0, y: 16 }
  animate: { opacity: 1, y: 0 }
  exit:    { opacity: 0, y: -12 }

pageTransition =
  duration: 0.28
  ease: [0.16, 1, 0.3, 1]

AnimatedPage = ({ children, className }) ->
  h motion.div,
    className: className
    initial: 'initial'
    animate: 'animate'
    exit: 'exit'
    variants: pageVariants
    transition: pageTransition
    style: { flex: 1, display: 'flex', flexDirection: 'column', minHeight: 0 }
  , children

export default AnimatedPage
