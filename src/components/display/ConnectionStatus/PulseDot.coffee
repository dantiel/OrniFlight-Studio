import { motion } from 'framer-motion'
import { createElement as h } from 'react'

###
# PulseDot — animated indicator with breathing pulse
# Used by ConnectionStatus for simulation/connected states
###
PulseDot = ({ active }) ->
  h motion.span,
    className: 'indicator-dot'
    animate: if active then {
      scale: [1, 1.25, 1]
      opacity: [1, 0.65, 1]
    } else {
      scale: 1
      opacity: 0.45
    }
    transition: if active then {
      repeat: Infinity
      duration: 2.2
      ease: 'easeInOut'
    } else {
      duration: 0.3
    }

export default PulseDot
