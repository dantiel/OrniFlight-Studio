###
# ORNIFLIGHT STUDIO — Reactotron Bridge
#
# This module is imported dynamically in dev mode only
# (see src/main.coffee). It connects all existing stores
# and machines to Reactotron without modifying them.
#
# The stores themselves stay pure — Reactotron subscribes
# from the outside. This is the "external observer" pattern.
###
import { attachStore, attachMachine, registerCommand } from './reactotron.coffee'
import useAppStore from '../stores/useAppStore.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'
import { getActor } from '../hooks/useConnection.coffee'

# ── Zustand stores ──

attachStore 'AppStore',       useAppStore
attachStore 'TelemetryStore', useTelemetryStore

# ── XState connection machine ──

try
  actor = getActor()
  attachMachine 'ConnectionMachine', actor
catch e
  # Actor not started yet — silent (app hasn't mounted)
  null

# ── Custom commands ──

registerCommand 'injectSpike', 'Sim: Inject Telemetry Spike', ->
  useTelemetryStore.getState().update
    t:              performance.now()
    gyroRoll:       Math.random() * 30 - 15
    gyroPitch:      Math.random() * 20 - 10
    gyroYaw:        Math.random() * 10 - 5
    servos:         (Math.random() * 0.3 for i in [0...16])
    batteryVoltage: 11.1 + Math.random() * 1.0
    flapFrequency:  5 + Math.random() * 3
    rssi:           Math.floor(Math.random() * 100)
    linkQuality:    Math.floor(Math.random() * 100)

registerCommand 'resetTelemetry', 'Sim: Reset Telemetry', ->
  useTelemetryStore.getState().update
    t:              0
    gyroRoll:       0
    gyroPitch:      0
    gyroYaw:        0
    servos:         (0 for i in [0...16])
    batteryVoltage: 0
    flapFrequency:  0
    rssi:           0
    linkQuality:    0

registerCommand 'toggleView', 'UI: Cycle View Mode', ->
  store = useAppStore.getState()
  modes = ['split', 'full', 'compact']
  idx = modes.indexOf(store.viewMode)
  store.setViewMode modes[(idx + 1) % modes.length]
