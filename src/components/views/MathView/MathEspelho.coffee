import { useMemo } from 'react'
import h from '../../../app/h.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import { espelhoDiagnostic } from '../../../lib/mathSuite.coffee'
import Section from '../../layout/Section/Section.coffee'

gauge = (label, value) ->
  h('div', { className: 'espelho-gauge', key: label }, [
    h('span', { className: 'espelho-gauge-label' }, label)
    h('span', { className: 'espelho-gauge-value' }, value.toFixed(3))
    h('div', { className: 'espelho-gauge-track' },
      h('span',
        { className: 'espelho-gauge-fill',
          style: { width: "#{Math.min(100, value * 100).toFixed(1)}%" } }))
  ])

# Espelho skew diagnostic — |2nd harmonic| / |fundamental| per axis
# plus the pitch phase dial. Device mode reads MSP_DEBUG channels
# (DEBUG_ESPELHO); sim mode derives the fingerprint from the live
# telemetry waveform (wing stroke and gyro), so the mirror is alive
# without a craft attached. Renders clean zeros on silence.
MathEspelho = ->
  telemetry = useTelemetryStore()
  hist = telemetry.waveformHistory or []
  freq = telemetry.flapFrequency or 0
  diagFor = (field) ->
    espelhoDiagnostic (hist.map (s) -> { t: s.t, value: s[field] }), freq
  rollDiag = useMemo (-> diagFor 'gyroRoll'), [hist, freq]
  pitchDiag = useMemo (-> diagFor 'gyroPitch'), [hist, freq]
  yawDiag = useMemo (-> diagFor 'gyroYaw'), [hist, freq]
  strokeDiag = useMemo (-> diagFor 'wingL'), [hist, freq]
  dbg = telemetry.debug or [0, 0, 0, 0]
  liveDevice = telemetry.source == 'device' and
    dbg.some((v) -> v != 0)
  ratioOf = (diag, idx) ->
    if liveDevice then dbg[idx] / 1000 else (diag?.ratio ? 0)
  phase = if liveDevice then dbg[3] else (pitchDiag?.phaseDeg ? 0)

  h 'div',
    { id: 'math-espelho-diag', className: 'morph-section math-espelho' },
    [
      h(Section,
        { key: 'sec',
          heading: 'Espelho Skew Diagnostic',
          subheading: 'Der Spiegel: |2. Harmonische| / |Grundwelle| der Schlagbewegung — der Fingerabdruck der Asymmetrie. Im Gerät über DEBUG_ESPELHO, hier aus der Live-Telemetrie.' },
        [
          h('div', { className: 'espelho-source' },
            h('span',
              { className: "espelho-source-badge espelho-source-#{if liveDevice then 'device' else 'sim'}" },
              (if liveDevice then 'DEBUG_ESPELHO' else 'SIM · stroke-derived')))
          h('div', { className: 'espelho-grid' }, [
            gauge 'ROLL', ratioOf(rollDiag, 0)
            gauge 'PITCH', ratioOf(pitchDiag, 1)
            gauge 'YAW', ratioOf(yawDiag, 2)
            gauge 'STROKE', ratioOf(strokeDiag, 0)
            h('div', { className: 'espelho-dial-wrap', key: 'dial' }, [
              h('div',
                { className: 'espelho-dial',
                  style: { '--espelho-phase': "#{phase}deg" } },
                h('span', { className: 'espelho-dial-needle' }))
              h('span', { className: 'espelho-dial-label' }, 'PHASE')
              h('span', { className: 'espelho-dial-value' },
                "#{phase.toFixed(0)}°")
            ])
          ])
        ])
    ]

export default MathEspelho
