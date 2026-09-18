###
# ORNIFLIGHT STUDIO — OrnithopterView (Grundkonfiguration)
#
# The drive-side body plan, split into three sub-views reached from
# the top menu: Körperplan (kernel + mixer + servo timing + trims),
# Flugwerk (airframe geometry + servo mounting), Schlagkurve (the
# stroke waveform). Flight profiles live in their own module; the
# RC channel test has been removed from here.
###
import './OrnithopterView.sass'
import h from '../../../app/h.coffee'
import { useLocation } from 'react-router-dom'
import useOrnithopterStore from '../../../stores/useOrnithopterStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import {
  KERNELS, profilesForKernel, profileById
  SERVO_SPEED_PRESETS, trimsForProfile
} from '../../../lib/mixerCatalog.coffee'
import {
  sampleWave, WAVEFORM_FIELDS, WAVEFORM_LIMITS
} from '../../../simulation/waveform.coffee'
import {
  AIRFRAME_FIELDS, AIRFRAME_LIMITS, MOUNT_FIELDS, MOUNT_LIMITS
  airframeDerived
} from '../../../lib/airframeCatalog.coffee'
import { getArrangement } from '../../../simulation/OrnithopterModel.coffee'

Section = (props) ->
  h 'section', { className: 'orni-panel' },
    h 'header', { className: 'orni-panel-head' },
      h 'span', { className: 'orni-glyph' }, props.glyph
      h 'div', null,
        h 'h2', null, props.title
        h 'p', { className: 'orni-hermes' }, props.hermes
    props.children

Field = (props) ->
  h 'div', { className: 'orni-field' },
    h 'div', { className: 'orni-field-label' },
      h 'b', null, props.label
      if props.hermes?
        h 'small', { className: 'orni-hermes' }, props.hermes
    h 'div', { className: 'orni-field-control' }, props.children

# Signed number — a + prefix only when the axis crosses zero.
signedValue = (value, limits) ->
  "#{if limits.min < 0 and value > 0 then '+' else ''}#{value}"

# ── Waveform widget — the stroke's shape drawn live ──────────
WAVE_W = 340
WAVE_H = 140
WAVE_PAD = 14

WaveformWidget = (props) ->
  { points, limiarFraction } = sampleWave props.params, 128
  plotX = (x) -> WAVE_PAD + x * (WAVE_W - 2 * WAVE_PAD)
  plotY = (y) -> WAVE_H / 2 - y * (WAVE_H / 2 - WAVE_PAD)
  pathFor = (half) ->
    pts = points.filter (p) -> p.half is half
    pts.map (p, i) ->
      cmd = if i is 0 then 'M' else 'L'
      "#{cmd}#{plotX(p.x).toFixed 1} #{plotY(p.y).toFixed 1}"
    .join ' '
  divX = plotX limiarFraction
  h 'svg',
    className: 'orni-wave-svg'
    viewBox: "0 0 #{WAVE_W} #{WAVE_H}"
    preserveAspectRatio: 'none'
  ,
    h 'line',
      className: 'orni-wave-axis'
      x1: WAVE_PAD
      x2: WAVE_W - WAVE_PAD
      y1: WAVE_H / 2
      y2: WAVE_H / 2
    h 'line',
      className: 'orni-wave-limi'
      x1: divX
      x2: divX
      y1: WAVE_PAD
      y2: WAVE_H - WAVE_PAD
    h 'path',
      className: 'orni-wave-path orni-wave-stroke'
      d: pathFor 'stroke'
    h 'path',
      className: 'orni-wave-path orni-wave-return'
      d: pathFor 'return'
    h 'circle',
      className: 'orni-wave-dot'
      cx: plotX 0
      cy: plotY (points[0]?.y ? 0)
      r: 3

OrnithopterView = ->
  orni = useOrnithopterStore()
  tele = useTelemetryStore()
  draft = orni.draft
  profile = profileById draft.profileId
  trims = trimsForProfile profile
  pairCount = getArrangement(profile.arrangement).pairs
  location = useLocation()
  path = location.pathname
  subtab = if path.includes('/airframe')
    'airframe'
  else if path.includes('/wave')
    'wave'
  else
    'body'

  kernelOptions = (k) ->
    h 'button',
      type: 'button'
      key: k.id
      className:
        "orni-segment#{if draft.kernel is k.id then ' orni-segment-on' else ''}"
      onClick: -> orni.setKernel k.id
    ,
      h 'span', { className: 'orni-segment-glyph' }, k.glyph
      h 'span', null, k.label

  modeLabel = if orni.mode is 'sim' then 'SIMULATION' else 'DEVICE'
  saveDisabled = orni.mode is 'device' and not orni.loadedSession
  activeWave = draft.profiles[draft.activeProfile].waveform
  liveWave = tele.liveWaveform ? activeWave
  airDerived = airframeDerived draft.airframe

  h 'div', { className: 'ornithopter-view' },
    # ── Page head ──────────────────────────────────────
    h 'header', { className: 'orni-page-head' },
      h 'div', null,
        h 'h1', null, 'GRUNDKONFIGURATION'
        h 'p', { className: 'orni-hermes' },
          'Körperplan · Flugwerk · Schlagkurve. ' +
          'Die Antriebsseite des Vogels, eine Sicht pro Gelenk.'
      h 'div', { className: 'orni-toolbar' },
        h 'span', { className: "orni-mode-badge orni-mode-#{orni.mode}" },
          modeLabel
        h 'span',
          className:
            "orni-dirty#{if orni.dirty then ' orni-dirty-on' else ''}"
        , if orni.dirty then 'UNGESPEICHERT' else 'GESPEICHERT'
        h 'button',
          className: 'orni-action orni-action-save'
          type: 'button'
          disabled: saveDisabled
          onClick: -> orni.save()
        , 'Speichern'
        h 'button',
          className: 'orni-action'
          type: 'button'
          disabled: not orni.dirty
          onClick: -> orni.revert()
        , 'Verwerfen'

    # ── Körperplan ─────────────────────────────────────
    if subtab is 'body'
      h Section,
        glyph: '🪽'
        title: 'Körperplan'
        hermes:
          'Kernel und Mixer: wie der Antrieb den Flügel spannt — ' +
          'direkt ins Gelenk oder über ein Getriebe.'
      ,
        h 'div', { className: 'orni-grid' },
          h Field,
            { label: 'Modellname', hermes: 'Freitext, 32 Zeichen.' },
            h 'input',
              className: 'orni-input'
              type: 'text'
              maxLength: 32
              value: draft.modelName
              onChange: (e) -> orni.setModelName e.target.value
          h Field, { label: 'Kernel', hermes: 'Direktantrieb oder Getriebe.' },
            h 'div', { className: 'orni-segments' },
              kernelOptions k for k in KERNELS
          h Field,
            { label: 'Mixer-Profil',
              hermes: 'GPIO-Belegung laut Firmware.' },
            h 'select',
              className: 'orni-input'
              value: draft.profileId
              onChange: (e) -> orni.setProfileId Number e.target.value
            ,
              for p in profilesForKernel draft.kernel
                h 'option', { key: p.id, value: p.id },
                  "#{p.name} — #{p.servos} Servos"
          h Field, { label: 'GPIO-Map' },
            h 'div', { className: 'orni-map' }, profile.map
          h Field,
            label: 'Schlagzeit'
            hermes: 'Zeit eines 60°-Schlags.'
          ,
            h 'div', { className: 'orni-slider-row' },
              h 'input',
                className: 'orni-slider'
                type: 'range'
                min: 40
                max: 400
                value: draft.servoSpeed
                onChange: (e) -> orni.setServoSpeed Number e.target.value
              h 'span', { className: 'orni-value' },
                "#{(draft.servoSpeed / 1000).toFixed 2} s/60°"
            h 'select',
              className: 'orni-input orni-presets'
              value: ''
              onChange: (e) ->
                orni.applySpeedPreset e.target.value if e.target.value
            ,
              h 'option', { value: '' }, '— Tempo —'
              for p in SERVO_SPEED_PRESETS
                h 'option', { key: p.id, value: p.id }, p.label
        if trims.length
          h 'div', { className: 'orni-trims' },
            h 'h3', null, 'Trims'
            h 'p', { className: 'orni-hermes' },
              'Ruhelage jedes Gelenks bei neutralem Input.'
            h 'div', { className: 'orni-grid' },
              for t in trims
                do (t) ->
                  h Field, { key: t.prop, label: t.label },
                    h 'input',
                      className: 'orni-slider'
                      type: 'range'
                      min: -50
                      max: 50
                      value: draft.trims[t.prop]
                      onChange: (e) -> orni.setTrim t.prop, Number e.target.value

    # ── Flugwerk ──────────────────────────────────────
    if subtab is 'airframe'
      h Section,
        glyph: '📐'
        title: 'Flugwerk'
        hermes:
          'Spannweite, Masse und Schwerpunkt — die Zelle, ' +
          'die der Schlag trägt.'
      ,
        h 'div', { className: 'orni-grid' },
          for field in AIRFRAME_FIELDS
            do (field) ->
              limits = AIRFRAME_LIMITS[field.id]
              value = draft.airframe[field.id]
              h Field,
                key: field.id
                label: field.label
                hermes: field.hermes
              ,
                h 'div', { className: 'orni-slider-row' },
                  h 'input',
                    className: 'orni-slider'
                    type: 'range'
                    min: limits.min
                    max: limits.max
                    value: value
                    onChange: (e) ->
                      orni.setAirframeField field.id, Number e.target.value
                  h 'span', { className: 'orni-value' },
                    "#{signedValue value, limits} #{field.unit}"
        h 'div', { className: 'orni-derived' },
          h 'span', { className: 'orni-hermes' },
            "Flügelfläche #{airDerived.wingArea.toFixed 0} cm²"
          h 'span', { className: 'orni-hermes' },
            "Streckung #{airDerived.aspectRatio.toFixed 1}"
        h 'div', { className: 'orni-trims' },
          h 'h3', null, 'Servo-Montage'
          h 'p', { className: 'orni-hermes' },
            'Lage jedes Flügelpaars: Winkel, Station, Höhe.'
          h 'div', { className: 'orni-grid' },
            for i in [0...pairCount]
              do (i) ->
                h 'div', { key: i, className: 'orni-mount' },
                  h 'div', { className: 'orni-mount-head' }, "Paar #{i + 1}"
                  for field in MOUNT_FIELDS
                    do (field) ->
                      limits = MOUNT_LIMITS[field.id]
                      value = draft.airframe.mounts[i][field.id]
                      h Field, { key: field.id, label: field.label },
                        h 'div', { className: 'orni-slider-row' },
                          h 'input',
                            className: 'orni-slider'
                            type: 'range'
                            min: limits.min
                            max: limits.max
                            value: value
                            onChange: (e) ->
                              orni.setMountField(
                                i, field.id, Number e.target.value
                              )
                          h 'span', { className: 'orni-value' },
                            "#{signedValue value, limits} #{field.unit}"

    # ── Schlagkurve ───────────────────────────────────
    if subtab is 'wave'
      h Section,
        glyph: '🌊'
        title: 'Schlagkurve'
        hermes:
          'Abwärts und Aufwärts — je eigene Ferocity, je eigene ' +
          'Mitte. Die Kurve ist das Kommando, bevor es ins Gelenk fährt.'
      ,
        h 'div', { className: 'orni-wave-stage' },
          h WaveformWidget, { params: liveWave }
          h 'div', { className: 'orni-wave-caption' },
            h 'span', { className: 'orni-hermes' },
              "Profil #{draft.activeProfile + 1} — live geformt"
            h 'div', { className: 'orni-wave-legend' },
              h 'span', { className: 'orni-legend-dot orni-legend-stroke' },
                'Abwärts'
              h 'span', { className: 'orni-legend-dot orni-legend-return' },
                'Aufwärts'
        h 'div', { className: 'orni-grid' },
          for field in WAVEFORM_FIELDS
            do (field) ->
              limits = WAVEFORM_LIMITS[field.id]
              value = activeWave[field.id]
              h Field,
                key: field.id
                label: field.label
                hermes: field.hermes
              ,
                h 'div', { className: 'orni-slider-row' },
                  h 'input',
                    className: 'orni-slider'
                    type: 'range'
                    min: limits.min
                    max: limits.max
                    value: value
                    onChange: (e) ->
                      orni.setWaveformParam(
                        draft.activeProfile, field.id, Number e.target.value
                      )
                  h 'span', { className: 'orni-value' },
                    "#{if limits.min < 0 and value > 0 then '+' else ''}#{value}"

    h 'footer', { className: 'orni-foot' },
      h 'span', { className: 'orni-hermes' },
        'Körperplan im Studio · GPIOs in der Firmware · ' +
        'Flügel im Himmel.'

export default OrnithopterView
