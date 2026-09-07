import './BreakpointIndicator.sass'
import h from '../../../app/h.coffee'

BreakpointIndicator = ->
  return null unless import.meta.env.DEV
  h 'div', { className: 'breakpoint-indicator', 'aria-hidden': true },
    h 'span', { className: 'bp-xs' }, 'XS'
    h 'span', { className: 'bp-sm' }, 'SM'
    h 'span', { className: 'bp-md' }, 'MD'
    h 'span', { className: 'bp-lg' }, 'LG'

export default BreakpointIndicator
