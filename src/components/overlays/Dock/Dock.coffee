import './Dock.sass'
import { useState } from 'react'
import { NavLink } from 'react-router-dom'
import { motion } from 'framer-motion'
import h from '../../../app/h.coffee'

# Core launcher — the few, the essential, the bird's-eye path.
ITEMS = [
  ['Device', '/device', '◫']
  ['Wings', '/airframe', '⌁']
  ['Flight', '/control', '△']
  ['Receiver', '/receiver', '⇄']
  ['Power', '/power', 'ϟ']
  ['Sensors', '/sensors', '◎']
  ['Safety', '/safety', '◇']
  ['OSD', '/osd', '⌗']
  ['CLI', '/cli', '❯']
]

Dock = ->
  [hovered, setHovered] = useState -1
  h 'nav', { className: 'dock-shell', 'aria-label': 'Primary navigation' },
    h 'div', { className: 'dock', onMouseLeave: -> setHovered -1 },
      ITEMS.map ([label, to, glyph], i) ->
        scale = switch
          when i == hovered then 1.35
          when Math.abs(i - hovered) == 1 then 1.12
          else 1
        h NavLink,
          key: to
          to: to
          end: true
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
