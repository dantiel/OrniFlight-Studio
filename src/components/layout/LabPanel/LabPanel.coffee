import './LabPanel.sass'
import h from '../../../app/h.coffee'
import { asList } from '../../../lib/essential.coffee'

LabPanel = ({ children, style }) ->
  h 'div', { className: 'lab-panel', style: style }, asList(children)...

export default LabPanel
