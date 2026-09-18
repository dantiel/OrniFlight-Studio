###
# ORNIFLIGHT STUDIO — FlightProfilesView
#
# The CH7 flight profiles — glide angle and stroke centre per profile,
# with the active face live. Split out of the old OrnithopterView so
# the drive-side body plan stays lean.
###
import './FlightProfilesView.sass'
import h from '../../../app/h.coffee'
import useOrnithopterStore from '../../../stores/useOrnithopterStore.coffee'

FlightProfilesView = ->
  orni = useOrnithopterStore()
  draft = orni.draft

  h 'div', { className: 'flight-profiles-view' },
    h 'header', { className: 'fp-head' },
      h 'div', null,
        h 'h1', null, 'FLUGPROFILE'
        h 'p', { className: 'fp-hermes' },
          'Drei Profile, gewählt über CH7. Jedes trägt Gleitwinkel ' +
          'und Schlagmitte.'
      h 'div', { className: 'fp-ch7-badge' }, 'CH7 · WÄHLT'

    h 'div', { className: 'fp-active-strip' },
      h 'span', { className: 'fp-hermes' }, 'AKTIV'
      h 'span', { className: 'fp-active-face' }, "Profil #{draft.activeProfile + 1}"

    h 'div', { className: 'fp-faces' },
      for i in [0...3]
        do (i) ->
          active = i is draft.activeProfile
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
                  min: -15
                  max: 15
                  value: draft.profiles[i].glideAngle
                  onChange: (e) -> orni.setGlideAngle i, Number e.target.value
                h 'span', { className: 'fp-value' },
                  "#{if draft.profiles[i].glideAngle > 0 then '+' else ''}" +
                  "#{draft.profiles[i].glideAngle}°"
              h 'div', { className: 'fp-slider-row' },
                h 'div', { className: 'fp-label' }, 'Schlag-Mitte'
                h 'input',
                  className: 'fp-slider'
                  type: 'range'
                  min: -15
                  max: 15
                  value: draft.profiles[i].flappingAngle
                  onChange: (e) ->
                    orni.setFlappingAngle i, Number e.target.value
                h 'span', { className: 'fp-value' },
                  "#{if draft.profiles[i].flappingAngle > 0 then '+' else ''}" +
                  "#{draft.profiles[i].flappingAngle}°"
              h 'div', { className: 'fp-face-wave' },
                "Schlag #{draft.profiles[i].waveform.strokeFerocity} · " +
                "Rück #{draft.profiles[i].waveform.returnFerocity} · " +
                "Mix #{draft.profiles[i].waveform.ferocityShapeMix}"
            h 'p', { className: 'fp-hermes' },
              if active
                'Aktives Profil, gewählt über CH7.'
              else
                'Inaktiv — CH7 wählt dieses Profil.'

export default FlightProfilesView
