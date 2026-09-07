###
# ORNIFLIGHT STUDIO — Integration Bridge
#
# Mirrors the XState connection lifecycle into the low-frequency app store.
# Transport/session services own transitions; the bridge never invents a
# connection from simulation state.
#
# Usage (call once in App.chaml):
#   useBridge()
###
import { useEffect } from 'react'
import useAppStore from '../stores/useAppStore.coffee'
import { getActor } from '../hooks/useConnection.coffee'

useBridge = ->
  setConnectionState = useAppStore (s) -> s.setConnectionState

  useEffect ->
    actor = getActor()
    sync = (snapshot) ->
      state = snapshot.value or 'disconnected'
      connected = state in ['streaming', 'stalled', 'reconnecting']
      setConnectionState state, connected
    sync actor.getSnapshot()
    subscription = actor.subscribe sync
    -> subscription.unsubscribe()
  , [setConnectionState]

  null

export default useBridge
