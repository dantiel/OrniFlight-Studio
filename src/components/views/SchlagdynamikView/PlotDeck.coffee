###
# ORNIFLIGHT STUDIO — PlotDeck
#
# The right-hand visualization column of Schlagdynamik. A sticky deck
# that keeps the motion in view while the params scroll: a segmented
# hero switcher (living scope / 3D bird / Espelho mirror) plus the
# profile signature as a persistent ribbon below, so dragging a
# ferocity slider always re-breathes the shape in front of you.
#
# The 3D bird is interchangeable with the plotter — same telemetry
# feed, different lens — so "what the wings are doing" and "what the
# waveform is doing" share one stage instead of competing for it.
###
import { useState } from 'react'
import h from '../../../app/h.coffee'
import StrokeScope from './StrokeScope.coffee'
import MathWaveform from './MathWaveform.coffee'
import MathEspelho from './MathEspelho.coffee'
import DeferredAircraftViewport from '../../canvas/DeferredAircraftViewport/DeferredAircraftViewport.coffee'
import GyroDisturb from './GyroDisturb.coffee'
import useEngineStore from '../../../stores/useEngineStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import { useI18n } from '../../../i18n/index.coffee'

PLOTS = [
  { id: 'motion',  glyph: '∿', label: 'schlagdynamik.tabMotion' }
  { id: '3d',      glyph: '◇', label: 'schlagdynamik.tab3d' }
  { id: 'mirror',  glyph: '⌁', label: 'schlagdynamik.tabMirror' }
]

PlotDeck = ({ active = 'motion', onActive }) ->
  { t } = useI18n()
  sim = useEngineStore()
  tele = useTelemetryStore()

  stage = switch active
    when '3d'
      h 'div', { className: 'plot-deck-3d' },
        h DeferredAircraftViewport, {
          attitude: tele.attitude or [0, 0, 0]
          wingAngleL: tele.wingAngleL or 0
          wingAngleR: tele.wingAngleR or 0
          flapFrequency: tele.flapFrequency or 0
          flapPhase: tele.flapPhase or 0
          amplitude: tele.amplitude or 45
          pairCount: tele.pairCount or 2
          servoMounts: tele.servoMounts or []
          aeroelasticFlapCoefficient: sim.simParams?.aeroelasticFlapCoefficient
          aeroelasticGlideCoefficient: sim.simParams?.aeroelasticGlideCoefficient
          onBump: sim.bump
          onDisturb: sim.disturb
        }
        h GyroDisturb, {}
    when 'mirror'
      h MathEspelho, {}
    else
      h StrokeScope, {}

  h 'div', { className: 'plot-deck' },
    h 'div', { className: 'plot-deck-bar', role: 'tablist' },
      PLOTS.map ({ id, glyph, label }) ->
        h 'button', {
          key: id
          type: 'button'
          role: 'tab'
          'aria-selected': String(active is id)
          className: "plot-deck-tab#{if active is id then ' plot-deck-tab-on' else ''}"
          onClick: -> onActive id
        },
          h('span', { className: 'plot-deck-tab-glyph' }, glyph),
          h('span', null, t(label))
    h 'div', { className: 'plot-deck-stage', role: 'tabpanel' }, stage
    h 'div', { className: 'plot-deck-ribbon' },
      h MathWaveform, {}

export default PlotDeck