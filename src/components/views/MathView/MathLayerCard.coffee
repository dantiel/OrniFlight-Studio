import h from '../../../app/h.coffee'
import {
  MATH_PARAMS, mathParamsOf, strokePreviewPath
} from '../../../lib/mathSuite.coffee'
import MathParamRow from '../../primitives/MathParamRow/MathParamRow.coffee'

# One layer card of the math suite: glyph + name + role, the layer's
# ParamRows from the registry, and — for Ferocity — the live
# down/up stroke preview. Lives in .coffee so the rows can map freely
# (nested chaml loops escape their scope).
MathLayerCard = ({ layer, draft, onInput, plx = 0 }) ->
  keys = mathParamsOf layer.id
  down = draft.ondas.ferocity_downstroke
  up = draft.ondas.ferocity_upstroke
  stroke =
    if layer.id == 'ferocity'
      h('div', { className: 'math-stroke-wrap', key: 'stroke' }, [
        h('svg',
          { className: 'math-stroke', viewBox: '0 0 168 56',
            'aria-hidden': true, preserveAspectRatio: 'none' },
          h('path',
            { d: strokePreviewPath(down, up), fill: 'none',
              stroke: 'currentColor', strokeWidth: '1.5' }))
        h('div', { className: 'math-stroke-legend' }, [
          h('span', null, '⬇ Downstroke')
          h('span', { className: 'math-stroke-asym' },
            "Asymmetrie #{Math.abs(down - up)}%")
          h('span', null, '⬆ Upstroke')
        ])
      ])
    else
      null
  h 'div',
    { id: "math-#{layer.id}", className: 'morph-section math-layer',
      style: { '--plx': "#{plx}px" } },
    [
      h('div', { className: 'math-layer-head', key: 'head' }, [
        h('span', { className: 'math-layer-glyph' }, layer.glyph)
        h('h2', { className: 'math-layer-name orgone-display' }, layer.name)
        h('p', { className: 'math-layer-role' }, layer.role)
      ])
      keys.map (key) ->
        h MathParamRow,
          key: "math-#{key}"
          rowKey: "math-#{key}"
          meta: MATH_PARAMS[key]
          value: draft.ondas[key]
          onInput: onInput[key]
      stroke
    ]...

export default MathLayerCard