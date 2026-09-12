###
# ORNIFLIGHT STUDIO — ProgressiveBlur
#
# A soft blur curtain for the virtual safe-area under transparent
# toolbars. Two sticky, height-zero anchors pin to the top and
# bottom edges of the #main-content scroll viewport; stacked
# backdrop-filter layers with shrinking mask reaches produce a
# genuine progressive falloff — strongest at the edge, dissolving
# to nothing by `reach`. Content scrolling beneath is blurred in
# graded steps, like water losing its memory.
###
import './ProgressiveBlur.sass'
import h from '../../../app/h.coffee'

# Gentle falloff — four tiers instead of seven. Each tier blurs less
# and reaches less far from the edge, so the edge dissolves to nothing
# progressively instead of slamming shut in a blue wall.
LAYERS = [
  { blur: 16, reach: '100%' }
  { blur: 10, reach: '70%' }
  { blur: 5,  reach: '44%' }
  { blur: 2,  reach: '22%' }
]

CURTAIN = 88

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
    h 'div', { className: 'progressive-blur-tint' }

export default ProgressiveBlur