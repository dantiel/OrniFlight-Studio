import './SidebarSection.sass'
import h from '../../../app/h.coffee'
import { asList } from '../../../lib/essential.coffee'

SidebarSection = ({ heading, children }) ->
  h 'div', { className: 'sidebar-section' },
    [
      h 'div', { className: 'sidebar-heading', key: 'h' }, heading
      asList(children)...
    ]...

export default SidebarSection
