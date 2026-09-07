import './Tooltip.sass'
import h from '../../../app/h.coffee'

Tooltip = (props) ->
  h 'span', { className: 'studio-tooltip', 'data-tip': props.label }, props.children

export default Tooltip
