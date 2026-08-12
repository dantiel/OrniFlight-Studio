import './Section.sass'
import h from '../../../app/h.coffee'

Section = (props) ->
  { heading, subheading, children } = props
  kids = [
    h 'div', { className: 'inspector-heading', key: 'h' }, heading
  ]
  if subheading
    kids.push h 'div', { className: 'inspector-subheading', key: 'sh' },
      subheading
  if children?
    if Array.isArray children
      kids = kids.concat children
    else
      kids.push children
  h 'div', { className: 'inspector-section' }, kids...

export default Section