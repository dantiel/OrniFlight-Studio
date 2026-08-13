###
# ORNIFLIGHT STUDIO — Engine Store (Zustand)
#
# Architectural role: mutable engine configuration (servos, PID
# gains, ONDAS params, sticks) exposed reactively. Every action
# delegates to the simulation engine and mirrors the result into
# the store, so subscribers re-render on config changes without
# polling the engine.
###
import { create } from 'zustand'
import { engine } from '../simulation/engine.coffee'

useEngineStore = create (set) ->
  servos:             engine.servos
  pidGains:           engine.pidGains
  ondasParams:        engine.ondas
  sticks:             engine.sticks
  connected:          engine.connected
  selectedServoIndex: 0

  selectServo: (i) ->
    set { selectedServoIndex: i }

  setStick: (axis, value) ->
    engine.setStick axis, value
    set { sticks: { engine.sticks... } }

  setOndasParam: (name, value) ->
    engine.setOndasParam name, value
    set { ondasParams: { engine.ondas... } }

  setPidGain: (name, value) ->
    engine.setPidGain name, value
    set { pidGains: { engine.pidGains... } }

  setServoParam: (index, param, value) ->
    engine.setServoParam index, param, value
    set { servos: engine.servos.map (s) -> { s... } }

  applyPreset: (name) ->
    engine.applyPreset name
    set
      servos:   engine.servos.map (s) -> { s... }
      pidGains: { engine.pidGains... }

  bump: ->
    engine.bump()

export default useEngineStore
