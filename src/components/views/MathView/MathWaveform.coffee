import { useMemo } from 'react'
import h from '../../../app/h.coffee'
import useTuningStore from '../../../stores/useTuningStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import { strokePreviewPath } from '../../../lib/mathSuite.coffee'
import Section from '../../layout/Section/Section.coffee'

# The fixed waveform — one full flap cycle drawn through the same
# kernel the physics breathes. The path derives live from the
# Ferocity draft (every slider move re-breathes it); the phase bead
# pulses with the orgone rhythm while the frequency readout follows
# the measured flap rate (or rests in silence).
MathWaveform = ->
  ondas = useTuningStore (state) -> state.draft.ondas
  frequency = useTelemetryStore (state) -> state.flapFrequency
  down = ondas.ferocity_downstroke
  up = ondas.ferocity_upstroke
  path = useMemo (-> strokePreviewPath down, up, 240, 110), [down, up]
  freq = frequency or 0

  h 'div',
    { id: 'math-waveform', className: 'morph-section math-wave' },
    h(Section,
      { heading: 'Waveform',
        subheading: 'Ein kompletter Schlagzyklus aus dem Wellenkern — der fixe Anker der Schichten.' },
      h('div', { className: 'math-wave-field' },
        h('svg',
          { className: 'math-wave-svg', viewBox: '0 0 240 110',
            'aria-hidden': true, preserveAspectRatio: 'none' },
          h('defs', null,
            h('linearGradient',
              { id: 'math-wave-stroke', x1: '0', y1: '0', x2: '1', y2: '0' },
              h('stop', { offset: '0%', stopColor: 'var(--orgone-a)' }),
              h('stop', { offset: '60%', stopColor: 'var(--orgone-b)' }),
              h('stop', { offset: '100%', stopColor: 'var(--orgone-c)' }))),
          h('path',
            { d: path, fill: 'none', stroke: 'url(#math-wave-stroke)',
              strokeWidth: 2, vectorEffect: 'non-scaling-stroke' }),
          h('circle', { className: 'math-wave-bead', cx: 12, cy: 55, r: 3 })),
        h('div', { className: 'math-wave-legend' },
          h('span', null, "⬇ Down #{down}%"),
          h('span', { className: 'math-wave-asym' },
            "Asymmetrie #{Math.abs(down - up)}%"),
          h('span', null, "⬆ Up #{up}%")),
        h('div', { className: 'math-wave-freq' },
          if freq > 0
            "#{freq.toFixed(1)} Hz · live"
          else
            'Ruhe — keine Schlagfrequenz')))

export default MathWaveform