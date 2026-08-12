import './ViewArea.sass'
import h from '../../../app/h.coffee'

ViewArea = (props) ->
  { area, children } = props
  kids = if children?
    if Array.isArray(children) then children else [children]
  else
    []
  h 'div', { className: "view-area-#{area}" }, kids...

export default ViewArea