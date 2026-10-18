###
# ORNIFLIGHT STUDIO — FreqMod (tempo / frequency modulator)
#
# Assigns an AUX channel as the flap-cadence frequency modulator
# (OrniFlight behaviour): the channel's deflection around 1500 µs
# offsets the base cadence by ±gain Hz. Rendered in the Schlagdynamik
# params column so the tempo control lives beside the signal chain.
###
import h from '../../../app/h.coffee'
import useEngineStore from '../../../stores/useEngineStore.coffee'
import Section from '../../layout/Section/Section.coffee'
import { useI18n } from '../../../i18n/index.coffee'

AUX_OPTIONS = [-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]

FreqMod = ->
  { t } = useI18n()
  freqMod = useEngineStore (state) -> state.freqMod
  setFreqMod = useEngineStore (state) -> state.setFreqMod
  auxChannel = freqMod.auxChannel
  gain = freqMod.gain

  optionLabel = (i) ->
    if i < 0 then t('schlagdynamik.freqNone') else t('rc.aux', { n: i + 1 })

  h 'div', { id: 'freq-mod', className: 'morph-section freq-mod-section' },
    h(Section,
      { heading: t('schlagdynamik.freqModHeading'),
        subheading: t('schlagdynamik.freqModSub') },
      h('div', { className: 'freq-mod' },
        h('label', { className: 'freq-mod-row' },
          h('span', { className: 'freq-mod-label' }, t('schlagdynamik.freqAuxChannel')),
          h('select', {
            className: 'freq-mod-select'
            value: String(auxChannel)
            onChange: (event) -> setFreqMod { auxChannel: Number(event.target.value) }
          },
            AUX_OPTIONS.map (i) ->
              h 'option', { key: i, value: String(i) }, optionLabel(i))),
        h('label', { className: 'freq-mod-row' },
          h('span', { className: 'freq-mod-label' },
            t('schlagdynamik.freqGain', { hz: gain.toFixed(1) })),
          h('input', {
            className: 'freq-mod-slider'
            type: 'range'
            min: '0'
            max: '12'
            step: '0.5'
            value: String(gain)
            onInput: (event) -> setFreqMod { gain: Number(event.target.value) }
          }))))

export default FreqMod
