import h from '../../../app/h.coffee'
import { MATH_LAYERS } from '../../../lib/mathSuite.coffee'
import MathLayerCard from './MathLayerCard.coffee'

# The nine layer cards as one stack. Lives in .coffee so the layer
# mapping is plain CoffeeScript (chaml loops cannot carry component
# tags — the callback escapes its scope).
MathLayerStack = ({ draft, onInput }) ->
  h 'div', { className: 'math-layers' },
    MATH_LAYERS.map (layer) ->
      h MathLayerCard,
        key: layer.id
        layer: layer
        draft: draft
        onInput: onInput

export default MathLayerStack
