import h from '../../../app/h.coffee'
import { useI18n } from '../../../i18n/index.coffee'
import ParamRow from '../ParamRow/ParamRow.chaml'

# Registry-driven ParamRow for the math suite — keeps the chaml
# attribute blocks single-line (nested-loop chaml parsing breaks on
# multiline {} blocks) and the props readable.
MathParamRow = ({ rowKey, meta, value, onInput }) ->
  { t } = useI18n()
  h ParamRow,
    key: rowKey
    label: t(meta.label)
    value: value
    min: String(meta.min)
    max: String(meta.max)
    step: '1'
    display: "#{value} #{meta.unit}"
    hint: t(meta.role)
    onInput: onInput

export default MathParamRow
