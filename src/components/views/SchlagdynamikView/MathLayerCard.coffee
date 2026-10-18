import h from '../../../app/h.coffee'
import {
  MATH_PARAMS, mathParamsOf, strokePreviewPath
} from '../../../lib/mathSuite.coffee'
import { useI18n } from '../../../i18n/index.coffee'
import MathParamRow from '../../primitives/MathParamRow/MathParamRow.coffee'

# One layer card of the math suite: glyph + name + role, the layer's
# ParamRows from the registry, and — for Ferocity — the live
# down/up stroke preview. Lives in .coffee so the rows can map freely
# (nested chaml loops escape their scope).
MathLayerCard = ({ layer, ondas, onInput, plx = 0 }) ->
  { t } = useI18n()
  keys = mathParamsOf layer.id
  down = ondas.ferocity_downstroke
  up = ondas.ferocity_upstroke
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
          h('span', null, t('math.downstroke'))
          h('span', { className: 'math-stroke-asym' },
            t('math.asymmetry', { value: Math.abs(down - up) }))
          h('span', null, t('math.upstroke'))
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
        h('h2', { className: 'math-layer-name orgone-display' }, t(layer.name))
        h('p', { className: 'math-layer-role' }, t(layer.role))
      ])
      keys.map (key) ->
        h MathParamRow,
          key: "math-#{key}"
          rowKey: "math-#{key}"
          meta: MATH_PARAMS[key]
          value: ondas[key]
          onInput: onInput[key]
      stroke
    ]...

export default MathLayerCard
