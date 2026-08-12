import './SidebarSection.sass'
import h from '../../../app/h.coffee'

SidebarSection = (props) ->
  { heading, children } = props
  kids = [
    h 'div', { className: 'sidebar-heading', key: 'h' }, heading
  ]
  if children?
    if Array.isArray children
      kids = kids.concat children
    else
      kids.push children
  h 'div', { className: 'sidebar-section' }, kids...

export default SidebarSection