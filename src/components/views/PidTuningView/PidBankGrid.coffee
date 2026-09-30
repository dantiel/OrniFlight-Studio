import h from '../../../app/h.coffee'
import { fmt2 } from '../../../lib/essential.coffee'
import { PID_AXES, PID_TERMS } from '../../../protocol/mspDecoders.coffee'
import { pidHandlers } from './fieldHandlers.coffee'
import ParamRow from '../../primitives/ParamRow/ParamRow.chaml'

# The four axis blocks of the PID bank. Lives in .coffee so the
# nested axis/term mapping is plain CoffeeScript — nested chaml
# loops escape their scope (MathLayerStack law).
PidBankGrid = ({ draft, pidMax }) ->
  bounds =
    P: { min: '0', max: String(pidMax), step: '0.1' }
    I: { min: '0', max: '2', step: '0.001' }
    D: { min: '0', max: String(pidMax), step: '0.1' }

  h 'div', { className: 'pid-bank-grid' },
    PID_AXES.map (axis) ->
      h 'div', { className: 'pid-axis', key: "pid-axis-#{axis}" },
        [h('span', { className: 'pid-axis-name' }, axis.toUpperCase())]
          .concat PID_TERMS.map (term) ->
            h ParamRow,
              key: "pid-#{axis}-#{term}"
              label: "#{axis} #{term}"
              value: draft.pid[axis][term]
              min: bounds[term].min
              max: bounds[term].max
              step: bounds[term].step
              display: fmt2(draft.pid[axis][term])
              onInput: pidHandlers["#{axis}-#{term}"]

export default PidBankGrid
