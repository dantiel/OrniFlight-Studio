import h from '../../../app/h.coffee'
import ParamRow from '../ParamRow/ParamRow.chaml'

# Registry-driven ParamRow for the math suite — keeps the chaml
# attribute blocks single-line (nested-loop chaml parsing breaks on
# multiline {} blocks) and the props readable.
MathParamRow = ({ rowKey, meta, value, onInput }) ->
  h ParamRow,
    key: rowKey
    label: meta.label
    value: value
    min: String(meta.min)
    max: String(meta.max)
    step: '1'
    display: "#{value} #{meta.unit}"
    hint: meta.role
    onInput: onInput

export default MathParamRow
