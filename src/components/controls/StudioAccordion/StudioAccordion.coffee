import './StudioAccordion.sass'
import { useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import h from '../../../app/h.coffee'

StudioAccordion = (props) ->
  [open, setOpen] = useState props.defaultOpen ? false
  h 'section', { className: 'studio-accordion' },
    h 'button', { className: 'studio-accordion-trigger', type: 'button', onClick: (-> setOpen (v) -> !v), 'aria-expanded': open },
      h 'span', null, props.title
      h motion.span, { animate: { rotate: if open then 180 else 0 }, 'aria-hidden': true }, '⌄'
    h AnimatePresence, { initial: false },
      if open then h motion.div,
        className: 'studio-accordion-body'
        key: 'body'
        initial: { height: 0, opacity: 0 }
        animate: { height: 'auto', opacity: 1 }
        exit: { height: 0, opacity: 0 }
        transition: { duration: 0.18 }
      , h 'div', { className: 'studio-accordion-inner' }, props.children

export default StudioAccordion
