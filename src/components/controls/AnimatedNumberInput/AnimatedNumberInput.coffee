import './AnimatedNumberInput.sass'
import { useEffect, useState } from 'react'
import h from '../../../app/h.coffee'

AnimatedNumberInput = (props) ->
  [draft, setDraft] = useState String(props.value ? 0)
  useEffect (-> setDraft String(props.value ? 0)), [props.value]
  min = Number(props.min ? -Infinity)
  max = Number(props.max ? Infinity)
  step = Number(props.step ? 1)
  commit = (next) ->
    numeric = Number next
    return unless Number.isFinite numeric
    numeric = Math.min max, Math.max min, numeric
    setDraft String numeric
    props.onChange? numeric
  change = (delta) -> commit((Number(draft) || 0) + delta)

  h 'div', { className: 'animated-number-input' },
    h 'button', { type: 'button', onClick: (-> change -step), 'aria-label': "Decrease #{props.label || 'value'}" }, '−'
    h 'input',
      type: 'number'
      value: draft
      min: props.min
      max: props.max
      step: props.step || 1
      'aria-label': props.label || 'Value'
      onChange: (e) -> setDraft e.target.value
      onBlur: (e) -> commit e.target.value
      onKeyDown: (e) -> commit(e.currentTarget.value) if e.key == 'Enter'
    h 'button', { type: 'button', onClick: (-> change step), 'aria-label': "Increase #{props.label || 'value'}" }, '+'

export default AnimatedNumberInput
