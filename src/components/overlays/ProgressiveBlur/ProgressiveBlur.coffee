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

# Strong blur ends nearest the safe area; softer tiers reach further.
# The whole veil dies within 40px of the edge — it blends only what
# is directly approaching the toolbar/dock, never what merely hovers
# nearby. Beyond that band content stays completely crisp.
LAYERS = [
  { blur: 2, reach: '40px' }
  { blur: 5, reach: '28px' }
  { blur: 10, reach: '18px' }
  { blur: 20, reach: '10px' }
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
          '--pb-reach': layer.reach
    h 'div',
      className: 'progressive-blur-tint'
      style: { '--pb-reach': '40px' }

export default ProgressiveBlur