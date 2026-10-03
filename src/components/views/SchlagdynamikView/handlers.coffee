###
# ORNIFLIGHT STUDIO — Schlagdynamik field handlers
#
# Stable ondas handlers (built once at module scope) so ParamRow's
# memoized identity survives renders. They reach the ornithopter store
# imperatively and edit the ACTIVE profile's ONDAS — the single soul.
###
import useOrnithopterStore from '../../../stores/useOrnithopterStore.coffee'
import { ONDAS_KEYS } from '../../../protocol/mspDecoders.coffee'

intSetter = (key) ->
  (event) ->
    state = useOrnithopterStore.getState()
    state.setOndasParam state.draft.activeProfile, key,
      parseInt event.target.value

ondasHandlers = {}
ondasHandlers[key] = intSetter key for key in ONDAS_KEYS

export { ondasHandlers }
