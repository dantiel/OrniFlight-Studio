import './ProgressiveBlur.sass'
import h from '../../../app/h.coffee'

# Stacked blur layers create a genuine progressive falloff —
# strongest at the edge, dissolving to nothing by `reach`.
LAYERS = [
  { blur: 24, reach: '100%' }
  { blur: 16, reach: '78%' }
  { blur: 10, reach: '56%' }
  { blur: 6, reach: '36%' }
]

ProgressiveBlur = (props) ->
  position = props.position or 'top'
  h 'div', { className: "progressive-blur #{position}", 'aria-hidden': true },
    LAYERS.map (layer) ->
      h 'div',
        key: layer.blur
        className: 'progressive-blur-layer'
        style:
          '--pb-blur': "#{layer.blur}px"
          '--pb-reach': layer.reach

export default ProgressiveBlur
