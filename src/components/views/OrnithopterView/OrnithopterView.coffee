###
# ORNIFLIGHT STUDIO — OrnithopterView (unified body plan)
#
# One scrollable page, no subpages — the whole bird reveals
# itself as the æther scrolls: Der Kern (kernel + mixer body
# plan), Die Drei Gesichter (flight profiles, CH7), and Der
# Virtuelle Puls (channel test). Polymorphic: in sim mode the
# sticks drive the engine directly; on a device the live RC
# channels answer instead.
###
import './OrnithopterView.sass'
import h from '../../../app/h.coffee'
import { useEffect, useRef, useState } from 'react'
import useOrnithopterStore from '../../../stores/useOrnithopterStore.coffee'
import useEngineStore from '../../../stores/useEngineStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import {
  KERNELS, profilesForKernel, profileById
  SERVO_SPEED_PRESETS, trimsForProfile
} from '../../../lib/mixerCatalog.coffee'
import {
  sampleWave, WAVEFORM_FIELDS, WAVEFORM_LIMITS
} from '../../../simulation/waveform.coffee'

STICK_CHANNELS = [
  ['throttle', 'THR']
  ['roll', 'ROL']
  ['pitch', 'PIT']
  ['yaw', 'YAW']
]

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
  sim = useEngineStore()
  tele = useTelemetryStore()
  draft = orni.draft
  profile = profileById draft.profileId
  trims = trimsForProfile profile
  [sweeping, setSweeping] = useState false
  sweepRef = useRef null

  # Der Atemzug — one full sweep of every virtual channel.
  stopSweep = ->
    clearInterval sweepRef.current if sweepRef.current
    sweepRef.current = null
    setSweeping false
    sim.setStick ch, 1500 for [ch] in STICK_CHANNELS

  useEffect (-> stopSweep), []

  runSweep = ->
    return stopSweep() if sweeping
    setSweeping true
    t0 = performance.now()
    sweepRef.current = setInterval ->
      t = (performance.now() - t0) / 1000
      if t > 2.4
        return stopSweep()
      for [ch], i in STICK_CHANNELS
        phase = (t / 2.4) + i * 0.25
        value = Math.round 1500 + 480 * Math.sin 2 * Math.PI * phase
        sim.setStick ch, value
    , 33

  sweepClass =
    "orni-sweep#{if sweeping then ' orni-sweep-on' else ''}"

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
  deviceChannels = if orni.mode is 'device' then tele.rcChannels else null
  activeWave = draft.profiles[draft.activeProfile].waveform
  liveWave = tele.liveWaveform ? activeWave

  h 'div', { className: 'ornithopter-view' },
    # ── Page head ──────────────────────────────────────
    h 'header', { className: 'orni-page-head' },
      h 'div', null,
        h 'h1', null, 'ORNITHOPTER'
        h 'p', { className: 'orni-hermes' },
          'Der Vogel ist ein Dokument. Diese Seite trägt seinen ' +
          'Körperplan, seine drei Gesichter und seinen Puls — ' +
          'kein Unterspiel, nur Offenbarung beim Scrollen.'
      h 'div', { className: 'orni-toolbar' },
        h 'span', { className: "orni-mode-badge orni-mode-#{orni.mode}" },
          modeLabel
        h 'span',
          className:
            "orni-dirty#{if orni.dirty then ' orni-dirty-on' else ''}"
        , if orni.dirty then 'DIRTY' else 'REIN'
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

    # ── Der Kern ───────────────────────────────────────
    h Section,
      glyph: '🪽'
      title: 'Der Kern'
      hermes:
        'Der Kern entscheidet, ob der Flügel Muskel ist oder ' +
        'Gestänge — ob der Wille direkt ins Gelenk fährt oder ' +
        'durch ein Getriebe übersetzt wird.'
    ,
      h 'div', { className: 'orni-grid' },
        h Field,
          { label: 'Name des Vogels', hermes: 'Wie die Lüfte ihn rufen.' },
          h 'input',
            className: 'orni-input'
            type: 'text'
            maxLength: 32
            value: draft.modelName
            onChange: (e) -> orni.setModelName e.target.value
        h Field, { label: 'Kern', hermes: 'Muskel oder Übersetzung.' },
          h 'div', { className: 'orni-segments' },
            kernelOptions k for k in KERNELS
        h Field,
          { label: 'Körperplan',
            hermes: 'Die Firmware spannt die GPIOs danach.' },
          h 'select',
            className: 'orni-input'
            value: draft.profileId
            onChange: (e) -> orni.setProfileId Number e.target.value
          ,
            for p in profilesForKernel draft.kernel
              h 'option', { key: p.id, value: p.id },
                "#{p.name} — #{p.servos} Servos"
        h Field, { label: 'Servo-Karte' },
          h 'div', { className: 'orni-map' }, profile.map
        h Field,
          label: 'Schlagzeit'
          hermes:
            'Die Zeit eines 60°-Schlags — langsam ist Gebet, ' +
            'schnell ist Instinkt.'
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
            h 'option', { value: '' }, '— Tempo-Presets —'
            for p in SERVO_SPEED_PRESETS
              h 'option', { key: p.id, value: p.id }, p.label
      if trims.length
        h 'div', { className: 'orni-trims' },
          h 'h3', null, 'Gelenk-Ruhe'
          h 'p', { className: 'orni-hermes' },
            'Die Mitte jedes Glieds — wie der Vogel ruht, wenn ' +
            'kein Wille ihn bewegt.'
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

    # ── Die Drei Gesichter ─────────────────────────────
    h Section,
      glyph: '🎭'
      title: 'Die Drei Gesichter'
      hermes:
        'Drei Stimmungen desselben Vogels — CH7 am Empfänger wählt, ' +
        'welches Gesicht fliegt. Jedes trägt seinen eigenen Gleitwinkel.'
    ,
      h 'div', { className: 'orni-profile-strip' },
        h 'span', { className: 'orni-ch7' }, 'CH7'
        h 'span', { className: 'orni-hermes' },
          'trägt gerade'
        h 'span', { className: 'orni-active-face' },
          "Gesicht #{draft.activeProfile + 1}"
      h 'div', { className: 'orni-faces' },
        for i in [0...3]
          do (i) ->
            active = i is draft.activeProfile
            h 'div',
              key: i
              className: "orni-face#{if active then ' orni-face-on' else ''}"
              onClick: -> orni.setActiveProfile i
            ,
              h 'div', { className: 'orni-face-head' },
                h 'span', { className: 'orni-face-n' }, "Gesicht #{i + 1}"
                if active
                  h 'span', { className: 'orni-face-live' }, 'FLIEGT'
              h 'div', { className: 'orni-face-body' },
                h 'div', { className: 'orni-face-label' },
                  'Gleitwinkel'
                h 'input',
                  className: 'orni-slider'
                  type: 'range'
                  min: -15
                  max: 15
                  value: draft.profiles[i].glideAngle
                  onChange: (e) -> orni.setGlideAngle i, Number e.target.value
                h 'span', { className: 'orni-value' },
                  "#{if draft.profiles[i].glideAngle > 0 then '+' else ''}" +
                  "#{draft.profiles[i].glideAngle}°"
                h 'div', { className: 'orni-face-label' },
                  'Schlag-Mitte'
                h 'input',
                  className: 'orni-slider'
                  type: 'range'
                  min: -15
                  max: 15
                  value: draft.profiles[i].flappingAngle
                  onChange: (e) ->
                    orni.setFlappingAngle i, Number e.target.value
                h 'span', { className: 'orni-value' },
                  "#{if draft.profiles[i].flappingAngle > 0 then '+' else ''}" +
                  "#{draft.profiles[i].flappingAngle}°"
                h 'div', { className: 'orni-face-wave' },
                  "Schlag #{draft.profiles[i].waveform.strokeFerocity} · " +
                  "Rück #{draft.profiles[i].waveform.returnFerocity} · " +
                  "Mix #{draft.profiles[i].waveform.ferocityShapeMix}"
              h 'p', { className: 'orni-hermes' },
                if i is draft.activeProfile
                  'Die Ruhe zwischen zwei Schlägen, die trägt.'
                else
                  'Schlummernd — CH7 weckt dieses Gesicht.'

    # ── Die Welle ─────────────────────────────────────
    h Section,
      glyph: '🌊'
      title: 'Die Welle'
      hermes:
        'Die Seele des Schlags. Zwei Hälften — Abwärts und Aufwärts — ' +
        'jede mit eigener Härte, eigener Mitte. Die Kurve ist der Wille, ' +
        'bevor er ins Gelenk fährt.'
    ,
      h 'div', { className: 'orni-wave-stage' },
        h WaveformWidget, { params: liveWave }
        h 'div', { className: 'orni-wave-caption' },
          h 'span', { className: 'orni-hermes' },
            "Gesicht #{draft.activeProfile + 1} — live geformt"
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

    # ── Der Virtuelle Puls ─────────────────────────────
    h Section,
      glyph: '⚡'
      title: 'Der Virtuelle Puls'
      hermes:
        'Beweg die Sticks — die Servos antworten, bevor der Himmel ' +
        'es tut. Auf einem Gerät spricht der Empfänger selbst.'
    ,
      h 'div', { className: 'orni-grid orni-pulse-grid' },
        if orni.mode is 'sim'
          for [ch, label] in STICK_CHANNELS
            do (ch, label) ->
              h Field, { key: ch, label },
                h 'div', { className: 'orni-slider-row' },
                  h 'input',
                    className: 'orni-slider'
                    type: 'range'
                    min: 1000
                    max: 2000
                    value: sim.sticks[ch]
                    onChange: (e) -> sim.setStick ch, Number e.target.value
                  h 'span', { className: 'orni-value' }, "#{sim.sticks[ch]}"
        else
          for ch, i in (deviceChannels ? [])
            h Field, { key: i, label: "CH#{i + 1}" },
              h 'div', { className: 'orni-slider-row' },
                h 'div', { className: 'orni-meter' },
                  h 'div',
                    className: 'orni-meter-fill'
                    style:
                      width: "#{Math.min 100, Math.max 0, ((ch - 1000) / 10)}%"
                h 'span', { className: 'orni-value' }, "#{ch}"
        h 'div', { className: 'orni-pulse-side' },
          h 'div', { className: 'orni-channel-read' },
            h 'b', null, 'Servo-Antwort'
            h 'div', { className: 'orni-servo-bars' },
              for value, i in (tele.servos ? [])[0...8]
                h 'div', { key: i, className: 'orni-servo-bar-row' },
                  h 'span', { className: 'orni-servo-bar-ch' }, "S#{i + 1}"
                  h 'div', { className: 'orni-meter' },
                    h 'div',
                      className: 'orni-meter-fill orni-meter-servo'
                      style:
                        width:
                          "#{Math.min 100, Math.max 0, ((value - 1000) / 10)}%"
                  h 'span', { className: 'orni-value' }, "#{value or 0}"
          if orni.mode is 'sim'
            h 'button',
              className: "orni-action #{sweepClass}"
              type: 'button'
              onClick: runSweep
            , if sweeping then 'Stoppe Atemzug' else 'Atemzug — alle Kanäle'
          else
            h 'p', { className: 'orni-hermes' },
              'Device-Modus: Der Atemzug ist sim-only — ' +
              'die Kanäle gehören dem Empfänger.'

    h 'footer', { className: 'orni-foot' },
      h 'span', { className: 'orni-hermes' },
        'Wie oben, so unten — der Körperplan im Studio, die GPIOs ' +
        'in der Firmware, der Flügel im Himmel.'

export default OrnithopterView