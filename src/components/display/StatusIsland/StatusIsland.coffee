import './StatusIsland.sass'
import { motion, useReducedMotion } from 'framer-motion'
import h from '../../../app/h.coffee'

StatusIsland = (props) ->
  state = props.state || 'disconnected'
  label = props.label || state.toUpperCase()
  detail = switch state
    when 'streaming'
      metrics = "#{Number(props.voltage || 0).toFixed(1)} V"
      if props.deviceLabel then "#{props.deviceLabel} · #{metrics}" else metrics
    when 'scanning' then 'Choose a serial controller'
    when 'handshaking' then 'Reading ORNI identity and capabilities'
    when 'stalled' then 'Telemetry interrupted'
    when 'reconnecting' then "Retry #{props.attempts || 1}"
    else props.error or 'No device'
  reduce = useReducedMotion()

  h motion.div,
    className: "status-island state-#{state}"
    layout: not reduce
    transition: { type: 'spring', stiffness: 430, damping: 34 }
    role: 'status'
    'aria-live': 'polite'
  ,
    h motion.span, { className: 'status-island-dot', layout: not reduce }
    h 'span', { className: 'status-island-label' }, label
    h motion.span, { className: 'status-island-detail', initial: { opacity: 0 }, animate: { opacity: 1 } }, detail

export default StatusIsland
