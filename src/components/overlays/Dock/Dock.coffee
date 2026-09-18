import './Dock.sass'
import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { motion } from 'framer-motion'
import h from '../../../app/h.coffee'
import { MODULES } from '../../../lib/navigation.coffee'

# Top-level modules — the bird's-eye path through the suite.
# Sub-views live in the top menu (ConfigTabs); the dock stays coarse.

Dock = ->
  [hovered, setHovered] = useState -1
  h 'nav', { className: 'dock-shell', 'aria-label': 'Primary navigation' },
    h 'div', { className: 'dock', onMouseLeave: -> setHovered -1 },
      MODULES.map ([to, label, glyph], i) ->
        scale = switch
          when i == hovered then 1.35
          when Math.abs(i - hovered) == 1 then 1.12
          else 1
        h NavLink,
          key: to
          to: to
          className: 'dock-item'
          onMouseEnter: -> setHovered i
        ,
          h motion.span,
            className: 'dock-icon'
            animate: { scale }
            transition: { type: 'spring', stiffness: 340, damping: 22 }
          , glyph
          h 'span', { className: 'dock-label' }, label

export default Dock
