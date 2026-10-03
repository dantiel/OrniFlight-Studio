import './ProfileSelector.sass'
import h from '../../../app/h.coffee'
import useOrnithopterStore from '../../../stores/useOrnithopterStore.coffee'

# Shared flight-profile switcher — the face every per-profile view
# wears in its fixed header / sidebar. Four profiles (the firmware's
# ornithopterProfile_t slots); the active one highlights and every
# per-profile store field the view edits routes through it.
ProfileSelector = ({ className = '' }) ->
  activeProfile = useOrnithopterStore (state) -> state.draft.activeProfile
  count = useOrnithopterStore (state) -> state.draft.profiles.length
  setActiveProfile = useOrnithopterStore (state) -> state.setActiveProfile

  h 'div',
    {
      className: "profile-selector #{className}"
      role: 'tablist'
      'aria-label': 'Flugprofil'
    },
    [0...count].map (i) ->
      h 'button',
        key: i
        type: 'button'
        role: 'tab'
        'aria-selected': String(i is activeProfile)
        className:
          "profile-selector-chip#{if i is activeProfile then ' is-active' else ''}"
        onClick: (-> setActiveProfile i)
      , [
        h('span', { className: 'profile-selector-dot' }, String(i + 1))
        h('span', { className: 'profile-selector-name' }, "Profil #{i + 1}")
      ]

export default ProfileSelector