###
# ORNIFLIGHT STUDIO — useTelemetry Hook
#
# Bridge between RxJS telemetry stream and React.
#
# Pattern: useEffect subscription → useState
#   The hook subscribes to the BehaviorSubject on mount,
#   updates React state on each emission, and unsubscribes
#   on unmount. This is the standard React ↔ RxJS bridge.
#
#   For derived streams (gyroStream, servoStream), use the
#   named streams directly. For the full frame, use the
#   telemetrySubject.
#
# Usage:
#   telemetry = useTelemetry()           # full frame
#   gyro      = useTelemetry(gyroStream)  # gyro only (re-renders less)
###
import { useState, useEffect } from 'react'
import { telemetrySubject } from '../streams/telemetryStream.coffee'

useTelemetry = (stream = null) ->
  source = stream || telemetrySubject
  [value, setValue] = useState -> source.getValue()

  useEffect ->
    sub = source.subscribe setValue
    -> sub.unsubscribe()
  , [source]

  value

export default useTelemetry
