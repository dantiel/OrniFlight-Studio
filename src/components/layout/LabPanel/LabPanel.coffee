import './LabPanel.sass'
import h from '../../../app/h.coffee'

LabPanel = (props) ->
  { children, style } = props
  kids = if children?
    if Array.isArray(children) then children else [children]
  else
    []
  h 'div', { className: 'lab-panel', style: style }, kids...

export default LabPanel