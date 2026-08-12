import './ViewportOverlay.sass'
import h from '../../../app/h.coffee'

ViewportOverlay = (props) ->
  { badges } = props
  badgeElements = (badges || []).map (b) ->
    h 'div', { className: 'overlay-badge', key: b }, b
  h 'div', { className: 'vport-overlay' }, badgeElements...

export default ViewportOverlay