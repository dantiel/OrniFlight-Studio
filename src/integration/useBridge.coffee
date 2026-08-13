###
# ORNIFLIGHT STUDIO — Integration Bridge
#
# Wires the connection lifecycle into the reactive core:
#   engine.connected → XState connection machine
#                    → app store connection mirror
#
# Telemetry does NOT flow through the bridge anymore — the
# simulation loop pushes frames directly (push, don't poll).
#
# Usage (call once in App.chaml):
#   useBridge()
###
import { useEffect } from 'react'
import useAppStore from '../stores/useAppStore.coffee'
import { getActor } from '../hooks/useConnection.coffee'
import { engine } from '../simulation/engine.coffee'

useBridge = ->
  setConnectionState = useAppStore (s) -> s.setConnectionState

  useEffect ->
    actor = getActor()
    if engine.connected
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY' }
      setConnectionState 'streaming', true
    else
      actor.send { type: 'DISCONNECTED' }
      setConnectionState 'disconnected', false
  , []

  null

export default useBridge
