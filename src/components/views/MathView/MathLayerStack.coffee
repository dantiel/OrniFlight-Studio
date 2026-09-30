import h from '../../../app/h.coffee'
import { MATH_LAYERS } from '../../../lib/mathSuite.coffee'
import MathLayerCard from './MathLayerCard.coffee'

# The layer cards as a half-width parallax field around the fixed
# waveform rail. Alternating depths: every card drifts at its own
# rate against the scroll — closer cards carry more color, distant
# cards recede. Lives in .coffee so the layer mapping is plain
# CoffeeScript (chaml loops cannot carry component tags).
MathLayerStack = ({ draft, onInput }) ->
  h 'div', { className: 'math-layers' },
    MATH_LAYERS.map (layer, index) ->
      depth = (if index % 2 == 0 then 1 else -1) * (4 + (index % 3) * 3)
      h MathLayerCard,
        key: layer.id
        layer: layer
        draft: draft
        onInput: onInput
        plx: depth

export default MathLayerStack