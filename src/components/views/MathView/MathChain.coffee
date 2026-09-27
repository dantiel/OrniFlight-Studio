import h from '../../../app/h.coffee'
import { MATH_LAYERS, mathParamsOf } from '../../../lib/mathSuite.coffee'
import { scrollMorphTo } from '../../../hooks/useScrollMorph.coffee'

# The nine-layer signal chain — clickable nodes that scroll+spotlight
# their layer card. Plain CoffeeScript mapping keeps the per-layer
# closures intact (chaml loop variables are IIFE-scoped and escape
# closures inside attribute blocks).
MathChain = ({ draft }) ->
  h 'div', { className: 'math-chain-row' },
    MATH_LAYERS.map (layer) ->
      keys = mathParamsOf layer.id
      avg = keys.reduce(
        ((acc, k) -> acc + Math.abs(draft.ondas[k]))
        0
      ) / (keys.length * 100)
      h 'button',
        key: layer.id
        type: 'button'
        className: 'math-chain-node'
        onClick: (-> scrollMorphTo "math-#{layer.id}")
        'aria-label': "#{layer.name} anzeigen"
      ,
        [
          h('span', { className: 'math-chain-glyph' }, layer.glyph)
          h('span', { className: 'math-chain-name' }, layer.name)
          h('span', { className: 'math-chain-bar' },
            h('span',
              { className: 'math-chain-fill',
                style: { width: "#{Math.round(avg * 100)}%" } }))
        ]

export default MathChain
