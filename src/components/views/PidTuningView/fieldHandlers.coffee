###
# ORNIFLIGHT STUDIO — Stable field handlers for the PID tuning view
#
# ParamRow is memoized; a fresh onInput closure per render would defeat
# the memo and re-render all 29 rows on every keystroke. These handlers
# are built once at module scope and reach the store imperatively, so
# their identity is stable across renders and React's shallow memo
# comparison can skip untouched rows.
###
import useTuningStore from '../../../stores/useTuningStore.coffee'
import {
  ONDAS_KEYS, PID_AXES, PID_TERMS
} from '../../../protocol/mspDecoders.coffee'

floatSetter = (path) ->
  (event) ->
    useTuningStore.getState().setField path, parseFloat event.target.value

intSetter = (path) ->
  (event) ->
    useTuningStore.getState().setField path, parseInt event.target.value

pidHandlers = {}
for axis in PID_AXES
  for term in PID_TERMS
    pidHandlers["#{axis}-#{term}"] = floatSetter "pid.#{axis}.#{term}"

ondasHandlers = {}
ondasHandlers[key] = intSetter "ondas.#{key}" for key in ONDAS_KEYS

rateHandlers =
  rcRate: intSetter 'rate.rcRate'
  superRate: intSetter 'rate.superRate'
  expo: intSetter 'rate.expo'

filterHandlers =
  gyroDlpfHz: intSetter 'filter.gyroDlpfHz'
  gyroNotchHz: intSetter 'filter.gyroNotchHz'
  gyroNotchQ: intSetter 'filter.gyroNotchQ'
  dTermDlpfHz: intSetter 'filter.dTermDlpfHz'

export { pidHandlers, ondasHandlers, rateHandlers, filterHandlers }
