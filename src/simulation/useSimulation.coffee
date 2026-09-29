###
# ORNIFLIGHT STUDIO — Simulation Loop
#
# useSimulation() mounts the engine's rAF loop and pushes every
# telemetry frame into the reactive core (RxJS stream + Zustand
# telemetry store). Push, don't poll: the loop is the single
# producer, every consumer reads the stores.
#
# snapshot(engine) is the pure projection engine → frame; the
# loop is pure effect. No component receives snapshot props anymore.
###
import { useEffect, useRef } from 'react'
import { engine } from './engine.coffee'
import { pushTelemetry } from '../streams/telemetryStream.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'
import useCliStore from '../stores/useCliStore.coffee'
import { getActor } from '../hooks/useConnection.coffee'

# Pure projection: simulation engine → one telemetry frame
snapshot = (engine) ->
  tel = engine.telemetry
  t:               engine.t
  gyroRoll:        tel.gyro.roll
  gyroPitch:       tel.gyro.pitch
  gyroYaw:         tel.gyro.yaw
  attitude:        { tel.attitude... }
  wingAngleL:      tel.wingAngleL
  wingAngleR:      tel.wingAngleR
  flapPhase:       tel.flapPhase
  pairCount:       tel.pairCount
  servoMounts:     tel.servoMounts[...]
  amplitude:       tel.amplitude
  batteryVoltage:  tel.batteryVoltage
  flapFrequency:   tel.flapFrequency
  liveWaveform:    { tel.liveWaveform... }
  servos:          tel.servoPositions[...]
  waveformHistory: tel.waveformHistory[...]
  rssi:            0
  linkQuality:     0

useSimulation = ->
  rafRef  = useRef null
  lastRef = useRef performance.now()
  source = useDeviceStore (state) -> state.source
  cliMode = useCliStore (state) -> state.mode

  useEffect ->
    # Real hardware owns the channel when a device session is live or
    # the CLI holds a direct link — simulated frames must never mix
    # with craft truth.
    return unless source == 'simulation' and cliMode != 'device'
    # The simulation is a polymorphic transport like WebSerial: when it
    # becomes the active source it drives the connection machine to
    # streaming, exactly as a real device handshake would.
    actor = getActor()
    unless actor.getSnapshot().value == 'streaming'
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: 'sim' }
    tick = (now) ->
      dt = Math.min((now - lastRef.current) / 1000, 0.05)
      lastRef.current = now
      engine.step dt
      frame = snapshot engine
      pushTelemetry frame
      useTelemetryStore.getState().update frame
      rafRef.current = requestAnimationFrame tick

    rafRef.current = requestAnimationFrame tick
    ->
      cancelAnimationFrame rafRef.current if rafRef.current
  , [source, cliMode]

  null

export { useSimulation, snapshot }