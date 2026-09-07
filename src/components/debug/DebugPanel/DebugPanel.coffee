import './DebugPanel.sass'
import { useEffect, useState } from 'react'
import useAppStore from '../../../stores/useAppStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import h from '../../../app/h.coffee'

DebugPanel = ->
  return null unless import.meta.env.DEV
  [open, setOpen] = useState false
  app = useAppStore()
  telemetry = useTelemetryStore()
  useEffect ->
    handler = (e) ->
      if (e.metaKey || e.ctrlKey) && e.shiftKey && e.key.toLowerCase() == 'd'
        e.preventDefault()
        setOpen (v) -> !v
    launcher = -> setOpen (v) -> !v
    window.addEventListener 'keydown', handler
    window.addEventListener 'orniflight:debug', launcher
    ->
      window.removeEventListener 'keydown', handler
      window.removeEventListener 'orniflight:debug', launcher
  , []
  return null unless open
  payload =
    route: window.location.pathname
    app:
      connectionState: app.connectionState
      connected: app.connected
      viewMode: app.viewMode
      waveCurves: app.waveCurves
      gyroCurves: app.gyroCurves
    telemetry:
      batteryVoltage: telemetry.batteryVoltage
      flapFrequency: telemetry.flapFrequency
      gyro: telemetry.gyro
  h 'aside', { className: 'debug-panel', 'aria-label': 'Developer state panel' },
    h 'header', null,
      h 'strong', null, 'LIVE STATE'
      h 'button', { type: 'button', onClick: (-> setOpen false), 'aria-label': 'Close debug panel' }, '×'
    h 'pre', null, JSON.stringify(payload, null, 2)

export default DebugPanel
