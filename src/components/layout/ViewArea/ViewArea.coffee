import './ViewArea.sass'
import h from '../../../app/h.coffee'
import { asList } from '../../../lib/essential.coffee'

ViewArea = ({ area, children }) ->
  h 'div', { className: "view-area view-area-#{area}" }, asList(children)...

export default ViewArea
