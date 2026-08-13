import './Section.sass'
import h from '../../../app/h.coffee'
import { asList } from '../../../lib/essential.coffee'

Section = ({ heading, subheading, children }) ->
  h 'div', { className: 'inspector-section' },
    [
      h 'div', { className: 'inspector-heading', key: 'h' }, heading
      if subheading
        h 'div', { className: 'inspector-subheading', key: 'sh' }, subheading
      asList(children)...
    ]...

export default Section
