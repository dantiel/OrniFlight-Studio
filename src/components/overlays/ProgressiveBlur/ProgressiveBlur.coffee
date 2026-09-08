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

LAYERS = [
  { blur: 24, reach: '100%' }
  { blur: 16, reach: '78%' }
  { blur: 10, reach: '56%' }
  { blur: 6, reach: '36%' }
]

CURTAIN = 64

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

export default ProgressiveBlur
