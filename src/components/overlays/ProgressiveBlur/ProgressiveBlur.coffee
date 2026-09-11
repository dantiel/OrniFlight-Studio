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
  { blur: 30, reach: '100%' }
  { blur: 24, reach: '86%' }
  { blur: 18, reach: '72%' }
  { blur: 13, reach: '58%' }
  { blur: 9,  reach: '44%' }
  { blur: 5,  reach: '30%' }
  { blur: 2,  reach: '16%' }
]

CURTAIN = 96

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