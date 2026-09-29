###
# ORNIFLIGHT STUDIO — ProgressiveBlur
#
# A soft blur curtain for the virtual safe-area under transparent
# toolbars. Two absolute, height-zero overlays pin to the top and
# bottom edges of the window (not the scroll viewport), so the blur
# reaches the very top of the frame — under the title toolbar —
# rather than hovering below the scroll content's top padding.
# Stacked backdrop-filter layers with shrinking mask reaches produce
# a genuine progressive falloff — strongest at the edge, dissolving
# to nothing by `reach`. Content scrolling beneath is blurred in
# graded steps, like water losing its memory.
###
import './ProgressiveBlur.sass'
import h from '../../../app/h.coffee'

# The veil is confined to the safe-area bar itself: the strongest
# tier only covers what lies deepest under the toolbar, every tier
# dissolves before the bar's lower edge. Content below the bar is
# never blurred — the bar blends only what it actually covers.
LAYERS = [
  { blur: 2, hold: '86%' }
  { blur: 4, hold: '68%' }
  { blur: 8, hold: '46%' }
  { blur: 14, hold: '22%' }
]

ProgressiveBlur = (props) ->
  position = props.position or 'top'
  h 'div',
    className: "progressive-blur progressive-blur-#{position}"
    'aria-hidden': true
  ,
    LAYERS.map (layer) ->
      h 'div',
        key: layer.blur
        className: 'progressive-blur-layer'
        style:
          '--pb-blur': "#{layer.blur}px"
          '--pb-hold': layer.hold
    h 'div',
      className: 'progressive-blur-tint'

export default ProgressiveBlur