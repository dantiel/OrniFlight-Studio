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

# delegate-then-reflect — run engine[action], then mirror engine[key]
# back into the store. Curried: (set) → (action, key) → (args…)
mirror = (set) -> (action, key) -> (args...) ->
  engine[action] args...
  set { "#{key}": { engine[key]... } }

useEngineStore = create (set) ->
  action = mirror set

  servos:             engine.servos
  pidGains:           engine.pidGains
  ondasParams:        engine.ondas
  sticks:             engine.sticks
  connected:          engine.connected
  arrangement:        engine.arrangement
  pairCount:          engine.pairCount
  servoMounts:        engine.servoMounts
  simParams:
    selfLevelGain:              engine.selfLevelGain
    yawAmpMix:                  engine.yawAmpMix
    aeroelasticFlapCoefficient: engine.aeroelasticFlapCoefficient
    aeroelasticGlideCoefficient: engine.aeroelasticGlideCoefficient
    servoTravelTimeMs:          engine.servoTravelTimeMs
  selectedServoIndex: 0

  selectServo:   (i) -> set { selectedServoIndex: i }
  setStick:      action 'setStick',      'sticks'
  setOndasParam: action 'setOndasParam', 'ondasParams'
  setPidGain:    action 'setPidGain',    'pidGains'
  setServoParam: action 'setServoParam', 'servos'

  applyPreset: (name) ->
    engine.applyPreset name
    set
      servos:   engine.servos.map (s) -> { s... }
      pidGains: { engine.pidGains... }

  applyArrangement: (name) ->
    engine.applyArrangement name
    set
      arrangement: engine.arrangement
      pairCount:   engine.pairCount
      servoMounts: engine.servoMounts.map (m) -> { m... }

  setSimulationParams: (params) ->
    engine.setSimulationParams params
    set
      simParams:
        selfLevelGain:              engine.selfLevelGain
        yawAmpMix:                  engine.yawAmpMix
        aeroelasticFlapCoefficient: engine.aeroelasticFlapCoefficient
        aeroelasticGlideCoefficient: engine.aeroelasticGlideCoefficient
        servoTravelTimeMs:          engine.servoTravelTimeMs

  bump: -> engine.bump()

export default useEngineStore