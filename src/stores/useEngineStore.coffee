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
  aux:                engine.aux
  connected:          engine.connected
  arrangement:        engine.arrangement
  pairCount:          engine.pairCount
  servoMounts:        engine.servoMounts
  waveform:           engine.waveform
  flightProfiles:     engine.flightProfiles
  activeFlightProfile: engine.activeFlightProfile
  simParams:
    selfLevelGain:              engine.selfLevelGain
    yawAmpMix:                  engine.yawAmpMix
    aeroelasticFlapCoefficient: engine.aeroelasticFlapCoefficient
    aeroelasticGlideCoefficient: engine.aeroelasticGlideCoefficient
    servoTravelTimeMs:          engine.servoTravelTimeMs
  freqMod:
    auxChannel: engine.freqAuxChannel
    gain:       engine.freqAuxGain
  disturbForce:      engine.disturbForce
  selectedServoIndex: 0

  selectServo:   (i) -> set { selectedServoIndex: i }
  setStick:      action 'setStick',      'sticks'
  setAux: (index, value) ->
    engine.setAux index, value
    set { aux: engine.aux.slice() }
  setOndasParam: action 'setOndasParam', 'ondasParams'
  setPidGain:    action 'setPidGain',    'pidGains'
  setServoParam: action 'setServoParam', 'servos'

  setWaveformParam: (name, value) ->
    engine.setWaveformParam name, value
    set
      waveform:           { engine.waveform... }
      flightProfiles:     engine.flightProfiles.map (p) ->
        { p..., waveform: { p.waveform... } }

  setFlightProfileParam: (index, name, value) ->
    engine.setFlightProfileParam index, name, value
    set
      waveform:           { engine.waveform... }
      flightProfiles:     engine.flightProfiles.map (p) ->
        { p..., waveform: { p.waveform... } }

  applyFlightProfile: (index) ->
    engine.applyFlightProfile index
    set
      activeFlightProfile: engine.activeFlightProfile
      waveform:           { engine.waveform... }

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

  setFreqMod: (patch) ->
    engine.setFreqMod patch
    set { freqMod: { auxChannel: engine.freqAuxChannel, gain: engine.freqAuxGain } }

  bump: -> engine.bump()

  setDisturbForce: (value) ->
    engine.setDisturbForce value
    set { disturbForce: engine.disturbForce }

  disturb: (roll, pitch, yaw) ->
    # Drag-to-disturb injects raw projected screen deltas (clamped ±100);
    # the strength slider scales them, faithful to the configurator's
    # _applyDisturbDrag (f = disturb_force * 0.02).
    f = engine.disturbForce * 0.02
    engine.disturb roll * f, pitch * f, yaw * f

  resetAttitude: -> engine.resetAttitude()

export default useEngineStore