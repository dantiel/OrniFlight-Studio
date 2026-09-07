import './AnimatedValue.sass'
import { useEffect, useRef, useState } from 'react'
import { animate, motion, useMotionValue, useReducedMotion } from 'framer-motion'
import h from '../../../app/h.coffee'

AnimatedValue = (props) ->
  raw = Number props.value
  target = if Number.isFinite(raw) then raw else 0
  decimals = props.decimals ? 1
  prefix = props.prefix || ''
  suffix = props.suffix || ''
  reduce = useReducedMotion()
  value = useMotionValue target
  [shown, setShown] = useState target
  previous = useRef target

  useEffect ->
    if reduce
      value.set target
      setShown target
      return
    controls = animate value, target,
      duration: props.duration ? 0.28
      ease: [0.16, 1, 0.3, 1]
      onUpdate: (next) -> setShown next
    previous.current = target
    -> controls.stop()
  , [target, reduce]

  text = prefix + shown.toFixed(decimals) + suffix
  h motion.span,
    className: ['animated-value', props.className].filter(Boolean).join(' ')
    title: text
    'aria-label': text
  , text

export default AnimatedValue
