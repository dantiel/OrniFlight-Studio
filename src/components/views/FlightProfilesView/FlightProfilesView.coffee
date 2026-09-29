###
# ORNIFLIGHT STUDIO — FlightProfilesView
#
# The four firmware flight profiles (ORNITHOPTER_PROFILE_COUNT),
# switched by the ornithopter-profile AUX box (BOXORNITHOPTERPROFILE).
# Each profile carries glide angle (-90..+90°, int8) and its stroke
# shape; the Math suite always edits the ACTIVE profile, so every
# face links straight into it.
###
import './FlightProfilesView.sass'
import h from '../../../app/h.coffee'
import { Link } from 'react-router-dom'
import useOrnithopterStore, {
  PROFILE_COUNT
} from '../../../stores/useOrnithopterStore.coffee'

FlightProfilesView = ->
  orni = useOrnithopterStore()
  draft = orni.draft

  h 'div', { className: 'flight-profiles-view' },
    h 'header', { className: 'fp-head' },
      h 'div', null,
        h 'h1', { className: 'orgone-display orgone-display-shimmer' },
          'FLUGPROFILE'
        h 'p', { className: 'fp-hermes' },
          'Vier Profile, gewählt über den Ornithopter-Profil-Modus ' +
          '(AUX-Box). Jedes trägt Gleitwinkel und Schlagform — die ' +
          'Math-Suite wirkt immer auf das aktive Profil.'
      h 'div', { className: 'fp-ch7-badge' }, 'AUX · BOX WÄHLT'

    h 'div', { className: 'fp-active-strip' },
      h 'span', { className: 'fp-hermes' }, 'AKTIV'
      h 'span', { className: 'fp-active-face' },
        "Profil #{draft.activeProfile + 1}"

    h 'div', { className: 'fp-faces' },
      for i in [0...PROFILE_COUNT]
        do (i) ->
          active = i is draft.activeProfile
          wave = draft.profiles[i].waveform
          h 'div',
            key: i
            className: "fp-face#{if active then ' fp-face-on' else ''}"
            onClick: -> orni.setActiveProfile i
          ,
            h 'div', { className: 'fp-face-head' },
              h 'span', { className: 'fp-face-n' }, "Profil #{i + 1}"
              if active
                h 'span', { className: 'fp-face-live' }, 'AKTIV'
            h 'div', { className: 'fp-face-body' },
              h 'div', { className: 'fp-slider-row' },
                h 'div', { className: 'fp-label' }, 'Gleitwinkel'
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
              h 'div', { className: 'fp-face-wave' },
                "Schlag #{wave.strokeFerocity} · " +
                "Rück #{wave.returnFerocity} · " +
                "Mix #{wave.ferocityShapeMix}"
            h 'div', { className: 'fp-face-foot' },
              h Link,
                to: '/control/math'
                className: 'fp-face-link'
                onClick: -> orni.setActiveProfile i
              , if active
                'Math-Suite dieses Profils bearbeiten →'
              else
                'Aktivieren & Math-Suite →'
            h 'p', { className: 'fp-hermes' },
              if active
                'Aktives Profil — ONDAS-Gains und Schlagform wirken jetzt.'
              else
                'Inaktiv — die AUX-Box wählt dieses Profil.'

export default FlightProfilesView
