###
# ORNIFLIGHT STUDIO — Simulation Loop
#
# useSimulation() mounts the engine's rAF loop and pushes every
# telemetry frame into the reactive core (RxJS stream + Zustand
# telemetry store). Push, don't poll: the loop is the single
# producer, every consumer reads the stores.
#
# Returns nothing — the hook exists for its effect only. Call it
# once in App.chaml. No component receives snapshot props anymore.
###
import { useEffect, useRef } from 'react'
import { engine } from './engine.coffee'
import { pushTelemetry } from '../streams/telemetryStream.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'

useSimulation = ->
  rafRef  = useRef null
  lastRef = useRef performance.now()

  useEffect ->
    tick = (now) ->
      dt = Math.min((now - lastRef.current) / 1000, 0.05)
      lastRef.current = now
      engine.step dt

      tel = engine.telemetry
      frame =
        t:               engine.t
        gyroRoll:        tel.gyro.roll
        gyroPitch:       tel.gyro.pitch
        gyroYaw:         tel.gyro.yaw
        attitude:        { tel.attitude... }
        wingAngleL:      tel.wingAngleL
        wingAngleR:      tel.wingAngleR
        amplitude:       tel.amplitude
        batteryVoltage:  tel.batteryVoltage
        flapFrequency:   tel.flapFrequency
        servos:          tel.servoPositions[...]
        waveformHistory: tel.waveformHistory[...]
        rssi:            0
        linkQuality:     0

      pushTelemetry frame
      useTelemetryStore.getState().update frame
      rafRef.current = requestAnimationFrame tick

    rafRef.current = requestAnimationFrame tick
    ->
      cancelAnimationFrame rafRef.current if rafRef.current
  , []

  null

export { useSimulation }
