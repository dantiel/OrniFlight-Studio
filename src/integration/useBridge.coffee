###
# ORNIFLIGHT STUDIO — Integration Bridge
#
# Sidecar pattern: hooks into the existing simulation engine
# and pushes data to the new architecture layers without
# modifying any existing component code.
#
# Architecture: Simulation → Bridge → { RxJS, Zustand, XState }
#                                         ↓
#                                   Components (future consumers)
#
# The bridge is opt-in. Components continue to receive data
# via props from App.chaml. Components that want to use the
# new reactive streams import directly from:
#   - useTelemetryStore for latest values
#   - telemetryStream for RxJS observables
#   - useConnection for connection state
###
import { useEffect } from 'react'
import { pushTelemetry } from '../streams/telemetryStream.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'
import useAppStore from '../stores/useAppStore.coffee'
import { getActor } from '../hooks/useConnection.coffee'

###
# useBridge — call in App.chaml to pipe simulation data
# into the reactive architecture.
#
# Usage (add to App.chaml after useSimulation):
#   useBridge sim, snap
#
# This pushes telemetry frames to RxJS, updates Zustand stores,
# and synchronizes the XState connection machine.
###
useBridge = (sim, snap) ->
  updateTelemetry = useTelemetryStore (s) -> s.update
  setConnectionState = useAppStore (s) -> s.setConnectionState
  setBattery = useAppStore (s) -> s.setBattery

  # Push telemetry frames to RxJS stream
  useEffect ->
    return unless snap.t
    frame =
      t:              snap.t
      gyroRoll:       snap.gyro?.roll  || 0
      gyroPitch:      snap.gyro?.pitch || 0
      gyroYaw:        snap.gyro?.yaw   || 0
      servos:         snap.servos      || []
      batteryVoltage: snap.batteryVoltage || 0
      flapFrequency:  snap.flapFrequency  || 0
    pushTelemetry frame
    updateTelemetry frame
    setConnectionState (if sim.connected then 'streaming' else 'disconnected'), sim.connected
    setBattery snap.batteryVoltage || 0, snap.flapFrequency || 0
  , [snap.t]

  # Mirror connection state to XState machine
  useEffect ->
    actor = getActor()
    if sim.connected
      snap = actor.getSnapshot()
      if snap?.value isnt 'streaming'
        actor.send { type: 'CONNECT' }
        actor.send { type: 'CONNECTED' }
        actor.send { type: 'FIRMWARE_READY' }
    else
      actor.send { type: 'DISCONNECTED' }
  , [sim.connected]

  null

export default useBridge
