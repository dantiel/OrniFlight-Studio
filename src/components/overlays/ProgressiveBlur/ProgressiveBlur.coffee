import './ProgressiveBlur.sass'
import h from '../../../app/h.coffee'

ProgressiveBlur = (props) ->
  h 'div', { className: "progressive-blur #{props.position || 'top'}", 'aria-hidden': true }

export default ProgressiveBlur
