###
# ORNIFLIGHT STUDIO — FlightProfilesView
#
# The four firmware flight profiles (ORNITHOPTER_PROFILE_COUNT),
# switched by the ornithopter-profile AUX box (BOXORNITHOPTERPROFILE).
# Each profile carries a glide angle, its stroke shape and the
# 18-parameter ONDAS stabilization suite. Schlagdynamik always edits
# the ACTIVE profile, so every face links straight into it — here the
# overview shows each profile's waveform, stroke shape and how many
# stabilization stages are actually engaged.
###
import './FlightProfilesView.sass'
import h from '../../../app/h.coffee'
import { Link } from 'react-router-dom'
import ModuleIcon from '../../primitives/ModuleIcon/ModuleIcon.coffee'
import { useI18n } from '../../../i18n/index.coffee'
import { strokePreviewPath } from '../../../lib/mathSuite.coffee'
import useOrnithopterStore, {
  PROFILE_COUNT
} from '../../../stores/useOrnithopterStore.coffee'

# How many ONDAS gains are off their neutral (0) — a rough read of how
# "tuned" the profile's stabilization is.
countActiveStages = (ondas = {}) ->
  n = 0
  for key, value of ondas
    n += 1 if Number(value) isnt 0
  n

FlightProfilesView = ->
  orni = useOrnithopterStore()
  draft = orni.draft
  { t } = useI18n()

  h 'div', { className: 'flight-profiles-view' },
    h 'header', { className: 'fp-head' },
      h 'div', { className: 'fp-head-row' },
        h 'div', { className: 'fp-head-text' },
          h 'h1', { className: 'orgone-display orgone-display-shimmer' },
            h ModuleIcon, { className: 'fp-head-glyph', size: 30 }
            h 'span', null, t('profiles.kicker')
          h 'p', { className: 'fp-hermes' }, t('profiles.hermes')
      h 'div', { className: 'fp-ch7-badge' }, t('profiles.auxBadge')

    h 'div', { className: 'fp-active-strip' },
      h 'span', { className: 'fp-hermes' }, t('profiles.active')
      h 'span', { className: 'fp-active-face' },
        t('profiles.profile', { n: draft.activeProfile + 1 })

    h 'div', { className: 'fp-faces' },
      for i in [0...PROFILE_COUNT]
        do (i) ->
          active = i is draft.activeProfile
          wave = draft.profiles[i].waveform
          ondas = draft.profiles[i].ondas
          name = draft.profiles[i].name
          stages = countActiveStages ondas
          h 'div',
            key: i
            className: "fp-face#{if active then ' fp-face-on' else ''}"
            onClick: -> orni.setActiveProfile i
          ,
            h 'div', { className: 'fp-face-head' },
              h 'input', {
                className: 'fp-face-name'
                type: 'text'
                value: name
                maxLength: 24
                placeholder: t('profiles.profile', { n: i + 1 })
                'aria-label': t('profiles.nameAria', { n: i + 1 })
                onClick: (e) -> e.stopPropagation()
                onChange: (e) -> orni.setProfileName i, e.target.value
              }
              if active
                h 'span', { className: 'fp-face-live' }, t('profiles.active')
            h 'div', { className: 'fp-face-body' },
              h 'svg', { className: 'fp-wave-preview', viewBox: '0 0 160 44', 'aria-hidden': 'true' },
                h 'path', { d: strokePreviewPath(wave.strokeFerocity, wave.returnFerocity, 160, 44) }
              h 'div', { className: 'fp-slider-row' },
                h 'div', { className: 'fp-label' }, t('profiles.glide')
                h 'input',
                  className: 'fp-slider'
                  type: 'range'
                  min: -90
                  max: 90
                  value: draft.profiles[i].glideAngle
                  onChange: (e) ->
                    orni.setGlideAngle i, Number e.target.value
                h 'span', { className: 'fp-value' },
                  "#{if draft.profiles[i].glideAngle > 0 then '+' else ''}" +
                  "#{draft.profiles[i].glideAngle}°"
              h 'div', { className: 'fp-meta' },
                h 'span', { className: 'fp-meta-label' }, t('profiles.strokeShape')
                h 'span', { className: 'fp-meta-value' },
                  t('profiles.stroke',
                    { stroke: wave.strokeFerocity, ret: wave.returnFerocity, mix: wave.ferocityShapeMix })
              h 'div', { className: 'fp-meta' },
                h 'span', { className: 'fp-meta-label' }, t('schlagdynamik.title')
                h 'span', { className: 'fp-meta-value' }, t('profiles.stages', { n: stages })
            h 'div', { className: 'fp-face-foot' },
              h Link,
                to: '/control/strokedynamics'
                className: 'fp-face-link'
                onClick: -> orni.setActiveProfile i
              , if active
                t('profiles.editActive')
              else
                t('profiles.editInactive')
            h 'p', { className: 'fp-hermes' },
              if active
                t('profiles.activeNote')
              else
                t('profiles.inactiveNote')

export default FlightProfilesView