###
# ORNIFLIGHT STUDIO — OrnithopterView (Grundkonfiguration)
#
# The drive-side body plan, split into two sub-views reached from
# the top menu: Körperplan (kernel + mixer + servo timing + trims),
# Flugwerk (airframe geometry + servo mounting). The stroke waveform
# lives in Schlagdynamik (per flight profile); flight profiles live in
# their own module.
###
import './OrnithopterView.sass'
import h from '../../../app/h.coffee'
import { useLocation, Link } from 'react-router-dom'
import Icon from '../../primitives/Icon/Icon.coffee'
import ModuleIcon from '../../primitives/ModuleIcon/ModuleIcon.coffee'
import useOrnithopterStore from '../../../stores/useOrnithopterStore.coffee'
import useDeviceStore from '../../../stores/useDeviceStore.coffee'
import {
  KERNELS, profilesForKernel, profileById
  SERVO_SPEED_PRESETS, trimsForProfile
} from '../../../lib/mixerCatalog.coffee'
import {
  AIRFRAME_FIELDS, AIRFRAME_LIMITS, MOUNT_FIELDS, MOUNT_LIMITS
  airframeDerived
} from '../../../lib/airframeCatalog.coffee'
import { getArrangement } from '../../../simulation/OrnithopterModel.coffee'

Section = (props) ->
  h 'section', { className: 'orni-panel' },
    h 'header', { className: 'orni-panel-head' },
      h Icon, { name: props.icon, className: 'orni-glyph', size: 16 }
      h 'div', null,
        h 'h2', null, props.title
        h 'p', { className: 'orni-hermes' }, props.hermes
    props.children

Field = (props) ->
  h 'div', { className: 'orni-field' },
    h 'div', { className: 'orni-field-label' },
      h 'b', null, props.label
      if props.meta?
        h 'span', { className: 'orni-field-meta' }, props.meta
      if props.hermes?
        h 'small', { className: 'orni-hermes' }, props.hermes
    h 'div', { className: 'orni-field-control' }, props.children

# Signed number — a + prefix only when the axis crosses zero.
signedValue = (value, limits) ->
  "#{if limits.min < 0 and value > 0 then '+' else ''}#{value}"

OrnithopterView = ->
  orni = useOrnithopterStore()
  identity = useDeviceStore (state) -> state.identity
  draft = orni.draft
  profile = profileById draft.profileId
  trims = trimsForProfile profile
  pairCount = getArrangement(profile.arrangement).pairs
  location = useLocation()
  path = location.pathname
  subtab = if path.includes('/airframe') then 'airframe' else 'body'

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
  airDerived = airframeDerived draft.airframe

  h 'div', { className: 'ornithopter-view' },
    # ── Page head ──────────────────────────────────────
    h 'header', { className: 'orni-page-head' },
      h 'div', { className: 'orni-head-row' },
        h 'div', { className: 'orni-head-text' },
          h 'h1', { className: 'orgone-display orgone-display-shimmer' },
            h ModuleIcon, { className: 'orni-head-glyph', size: 30 }
            h 'span', null, 'GRUNDKONFIGURATION'
          h 'p', { className: 'orni-hermes' },
            'Körperplan · Flugwerk. ' +
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
        icon: 'wing'
        title: 'Körperplan'
        hermes:
          'Kernel und Mixer: wie der Antrieb den Flügel spannt — ' +
          'direkt ins Gelenk oder über ein Getriebe.'
      ,
        h 'div', { className: 'orni-identity' },
          h 'div', { className: 'orni-identity-main' },
            h 'span', { className: 'orni-identity-label' }, 'CRAFT NAME'
            h 'strong', null,
              identity?.name ? "#{draft.modelName} (Simulation)"
            h 'span', { className: 'orni-hermes' },
              'Der Systemname wird vom Controller geführt (MSP_NAME, ' +
              '16 Zeichen) und in System → Gerät gepflegt.'
          h Link, { to: '/system/device', className: 'orni-identity-link' },
            'In System → Gerät bearbeiten'
        h 'div', { className: 'orni-grid' },
          h Field,
            { label: 'Kernel',
              hermes: 'Direktantrieb oder Getriebe.',
              meta: 'STUDIO' },
            h 'div', { className: 'orni-segments' },
              kernelOptions k for k in KERNELS
          h Field,
            { label: 'Mixer-Profil',
              hermes: 'GPIO-Belegung laut Firmware.',
              meta: 'STUDIO' },
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
            hermes:
              'servo_travel_time_ms der Firmware — Millisekunden ' +
              'pro 60°-Schlag (30–500).'
          ,
            h 'div', { className: 'orni-slider-row' },
              h 'input',
                className: 'orni-slider'
                type: 'range'
                min: 30
                max: 500
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
        icon: 'ruler'
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

    h 'footer', { className: 'orni-foot' },
      h 'span', { className: 'orni-hermes' },
        'Körperplan im Studio · GPIOs in der Firmware · ' +
        'Flügel im Himmel.'

export default OrnithopterView