import './DualRangeSlider.sass'
import h from '../../../app/h.coffee'

pct = (v, min, max) -> ((v - min) / (max - min)) * 100

# One track, two thumbs — a lower and an upper bound on a single rail.
# The thumbs clamp against each other, so low never crosses high.
DualRangeSlider = ({ min, max, step = 1, low, high, onLow, onHigh,
                     lowLabel, highLabel, disabled = false }) ->
  loPct = pct(low, min, max)
  hiPct = pct(high, min, max)
  handleLow = (e) -> onLow? Math.min(Number(e.target.value), high)
  handleHigh = (e) -> onHigh? Math.max(Number(e.target.value), low)
  h 'div', { className: 'dual-range' },
    h 'div', { className: 'dual-range-track' },
      h 'div', { className: 'dual-range-rail' },
        h 'div', {
          className: 'dual-range-fill'
          style: { left: "#{loPct}%", width: "#{hiPct - loPct}%" }
        }
      h 'input', {
        className: 'dual-range-thumb dual-range-low'
        type: 'range'
        min: min
        max: max
        step: step
        value: low
        disabled: disabled
        onChange: handleLow
        'aria-label': 'Lower bound'
      }
      h 'input', {
        className: 'dual-range-thumb dual-range-high'
        type: 'range'
        min: min
        max: max
        step: step
        value: high
        disabled: disabled
        onChange: handleHigh
        'aria-label': 'Upper bound'
      }
    h 'div', { className: 'dual-range-labels' },
      h 'span', { className: 'dual-range-label dual-range-label-low' },
        lowLabel
      h 'span', { className: 'dual-range-label dual-range-label-high' },
        highLabel

export default DualRangeSlider