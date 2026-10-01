import './Icon.sass'
import h from '../../../app/h.coffee'
import { ICONS } from '../../../lib/icons.coffee'

# Stroke icon rendered from the shared registry — color follows
# currentColor, so every surface themes it through CSS.
Icon = ({ name, className, size = 20, strokeWidth = 1.6 }) ->
  icon = ICONS[name]
  return null unless icon
  paths = (icon.paths ? []).map (d) -> h 'path', { key: d, d }
  circles = (icon.circles ? []).map (c) ->
    h 'circle', { key: "c#{c.cx}-#{c.cy}-#{c.r}", cx: c.cx, cy: c.cy, r: c.r }
  h 'svg',
    className: "of-icon #{className ? ''}"
    viewBox: '0 0 24 24'
    width: size
    height: size
    fill: 'none'
    stroke: 'currentColor'
    strokeWidth: strokeWidth
    strokeLinecap: 'round'
    strokeLinejoin: 'round'
    'aria-hidden': 'true'
    focusable: 'false'
  , paths.concat circles

export default Icon
