###
# ORNIFLIGHT STUDIO — RcInputStrip
#
# A compact test harness for the simulation: four stick sliders
# (roll / pitch / yaw / throttle) plus a few AUX channels, wired
# straight into the engine so the UI is fully exercisable without a
# controller. Reads and writes useEngineStore — the same sticks the
# firmware path would feed, so the diagrams, modes ranges and receiver
# bars all breathe from one source.
###
import './RcInputStrip.sass'
import h from '../../../app/h.coffee'
import useEngineStore from '../../../stores/useEngineStore.coffee'
import { fmt0 } from '../../../lib/essential.coffee'
import { useI18n } from '../../../i18n/index.coffee'

STICKS = [
  { key: 'roll',     min: 1000, max: 2000 }
  { key: 'pitch',    min: 1000, max: 2000 }
  { key: 'yaw',      min: 1000, max: 2000 }
  { key: 'throttle', min: 1000, max: 2000 }
]

RcInputStrip = ({ auxCount = 4 }) ->
  { t } = useI18n()
  sticks = useEngineStore (s) -> s.sticks
  aux = useEngineStore (s) -> s.aux
  setStick = useEngineStore (s) -> s.setStick
  setAux = useEngineStore (s) -> s.setAux

  cell = (label, value, min, max, onChange, key) ->
    h 'label', { className: 'rc-strip-cell', key },
      h('span', { className: 'rc-strip-label' }, label),
      h('input', {
        className: 'rc-strip-slider'
        type: 'range'
        min: String(min)
        max: String(max)
        step: '5'
        value: String(value)
        onInput: (e) -> onChange Number(e.target.value)
      }),
      h('span', { className: 'rc-strip-value' }, fmt0 value)

  h 'div', { className: 'rc-strip' },
    h('div', { className: 'rc-strip-head' },
      h('span', null, t('rc.title'))),
    h('div', { className: 'rc-strip-body' },
      STICKS.map ({ key, min, max }) ->
        cell t("rc.#{key}"), sticks[key], min, max,
          (v) -> setStick key, v, "rc-#{key}"
      for i in [0...auxCount]
        cell t('rc.aux', { n: i + 1 }), (aux[i] ? 1500), 900, 2100,
          ((idx) -> (v) -> setAux idx, v)(i), "rc-aux-#{i}"
    )

export default RcInputStrip
