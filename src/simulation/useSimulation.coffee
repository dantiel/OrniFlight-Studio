import {
  useState, useEffect, useRef, useCallback, startTransition
} from 'react'
import { OrnithopterModel } from './OrnithopterModel.coffee'

# ═══════════════════════════════════════════════════════════════
# Singleton engine — one simulation per application.
# React hook pulls presentation-rate snapshots via rAF.
# ═══════════════════════════════════════════════════════════════

engine = new OrnithopterModel()
engine.connect()

export useSimulation = ->

  # Snapshot state updated at ~60fps
  [snapshot, setSnapshot] = useState -> engine.telemetry
  [selectedServoIndex, setSelectedServoIndex] = useState 0
  rafRef = useRef null
  lastTimeRef = useRef performance.now()

  # ── Animation loop ──────────────────────────────────────
  useEffect ->
    tick = (now) ->
      dt = Math.min((now - lastTimeRef.current) / 1000, 0.05)  # cap at 50ms
      lastTimeRef.current = now
      engine.step(dt)
      # Shallow-clone telemetry for React diff
      # startTransition: non-urgent update — React 18 keeps UI responsive
      tel = engine.telemetry
      startTransition -> setSnapshot
        attitude: { tel.attitude... }
        gyro: { tel.gyro... }
        wingAngleL: tel.wingAngleL
        wingAngleR: tel.wingAngleR
        flapFrequency: tel.flapFrequency
        amplitude: tel.amplitude
        batteryVoltage: tel.batteryVoltage
        servoPositions: [...tel.servoPositions]
        waveformHistory: tel.waveformHistory[...]
        t: engine.t
      rafRef.current = requestAnimationFrame tick

    rafRef.current = requestAnimationFrame tick
    -> cancelAnimationFrame rafRef.current if rafRef.current
  , []

  # ── Actions ─────────────────────────────────────────────
  setStick = useCallback (axis, value) ->
    engine.setStick axis, value
  , []

  setOndasParam = useCallback (name, value) ->
    engine.setOndasParam name, value
  , []

  setPidGain = useCallback (name, value) ->
    engine.setPidGain name, value
  , []

  setServoParam = useCallback (index, param, value) ->
    engine.setServoParam index, param, value
  , []

  bump = useCallback ->
    engine.bump()
  , []

  applyPreset = useCallback (name) ->
    engine.applyPreset name
  , []

  selectServo = useCallback (i) ->
    setSelectedServoIndex i
  , []

  # ── Return ──────────────────────────────────────────────
  {
    snapshot
    servos: engine.servos
    pidGains: engine.pidGains
    ondasParams: engine.ondas
    sticks: engine.sticks
    connected: engine.connected
    selectedServoIndex
    setStick
    setOndasParam
    setPidGain
    setServoParam
    selectServo
    bump
    applyPreset
  }