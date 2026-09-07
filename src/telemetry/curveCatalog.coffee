# Telemetry curve metadata is kept outside the renderer so firmware-backed
# sources can extend the catalog later without changing the plot component.

CURVE_CATALOG = [
  { id: 'wingL', label: 'Left wing', shortLabel: 'Wing L', group: 'Wing motion', unit: '°', color: '#f0883e', domain: [-60, 60], workspaces: ['airframe', 'control'] }
  { id: 'wingR', label: 'Right wing', shortLabel: 'Wing R', group: 'Wing motion', unit: '°', color: '#58a6ff', domain: [-60, 60], workspaces: ['airframe', 'control'] }
  { id: 'gyroRoll', label: 'Gyro roll', shortLabel: 'Roll', group: 'Gyroscope', unit: '°/s', color: '#f85149', domain: [-720, 720], workspaces: ['airframe', 'control', 'sensors'] }
  { id: 'gyroPitch', label: 'Gyro pitch', shortLabel: 'Pitch', group: 'Gyroscope', unit: '°/s', color: '#3fb950', domain: [-720, 720], workspaces: ['airframe', 'control', 'sensors'] }
  { id: 'gyroYaw', label: 'Gyro yaw', shortLabel: 'Yaw', group: 'Gyroscope', unit: '°/s', color: '#bc8cff', domain: [-720, 720], workspaces: ['airframe', 'control', 'sensors'] }
  { id: 'servo1', label: 'Servo 1', shortLabel: 'S1', group: 'Servo outputs', unit: 'µs', color: '#f0a040', domain: [1000, 2000], workspaces: ['airframe', 'control', 'receiver'] }
  { id: 'servo2', label: 'Servo 2', shortLabel: 'S2', group: 'Servo outputs', unit: 'µs', color: '#39d2c0', domain: [1000, 2000], workspaces: ['airframe', 'control', 'receiver'] }
  { id: 'servo3', label: 'Servo 3', shortLabel: 'S3', group: 'Servo outputs', unit: 'µs', color: '#d29922', domain: [1000, 2000], workspaces: ['airframe', 'control', 'receiver'] }
  { id: 'servo4', label: 'Servo 4', shortLabel: 'S4', group: 'Servo outputs', unit: 'µs', color: '#db61a2', domain: [1000, 2000], workspaces: ['airframe', 'control', 'receiver'] }
  { id: 'rcThrottle', label: 'Throttle channel', shortLabel: 'Throttle', group: 'Receiver channels', unit: 'µs', color: '#f0a040', domain: [1000, 2000], workspaces: ['receiver', 'control'] }
  { id: 'rcRoll', label: 'Roll channel', shortLabel: 'RC Roll', group: 'Receiver channels', unit: 'µs', color: '#f85149', domain: [1000, 2000], workspaces: ['receiver', 'control'] }
  { id: 'rcPitch', label: 'Pitch channel', shortLabel: 'RC Pitch', group: 'Receiver channels', unit: 'µs', color: '#3fb950', domain: [1000, 2000], workspaces: ['receiver', 'control'] }
  { id: 'rcYaw', label: 'Yaw channel', shortLabel: 'RC Yaw', group: 'Receiver channels', unit: 'µs', color: '#bc8cff', domain: [1000, 2000], workspaces: ['receiver', 'control'] }
  { id: 'batteryVoltage', label: 'Battery voltage', shortLabel: 'Voltage', group: 'Power', unit: 'V', color: '#f0a040', domain: [0, 26], workspaces: ['airframe', 'control', 'power'] }
  { id: 'linkQuality', label: 'Link quality', shortLabel: 'LQ', group: 'Receiver link', unit: '%', color: '#39d2c0', domain: [0, 100], workspaces: ['receiver'] }
  { id: 'rssi', label: 'RSSI', shortLabel: 'RSSI', group: 'Receiver link', unit: '%', color: '#58a6ff', domain: [0, 100], workspaces: ['receiver'] }
  # These are capability-gated. They become selectable as soon as a future
  # firmware or log source contributes the corresponding sample keys.
  { id: 'accelX', label: 'Acceleration X', shortLabel: 'Accel X', group: 'Accelerometer', unit: 'g', color: '#f0883e', domain: [-4, 4], workspaces: ['sensors'], requiresData: true }
  { id: 'accelY', label: 'Acceleration Y', shortLabel: 'Accel Y', group: 'Accelerometer', unit: 'g', color: '#58a6ff', domain: [-4, 4], workspaces: ['sensors'], requiresData: true }
  { id: 'accelZ', label: 'Acceleration Z', shortLabel: 'Accel Z', group: 'Accelerometer', unit: 'g', color: '#3fb950', domain: [-4, 4], workspaces: ['sensors'], requiresData: true }
]

byId = CURVE_CATALOG.reduce ((index, curve) ->
  index[curve.id] = curve
  index
), {}

curveFor = (id) -> byId[id]

curvesForWorkspace = (workspace, history = []) ->
  latest = history[history.length - 1] or {}
  CURVE_CATALOG.filter (curve) ->
    return false unless workspace in curve.workspaces
    return true unless curve.requiresData
    Number.isFinite latest[curve.id]

groupCurves = (curves) ->
  curves.reduce ((groups, curve) ->
    groups[curve.group] ?= []
    groups[curve.group].push curve
    groups
  ), {}

export { CURVE_CATALOG, curveFor, curvesForWorkspace, groupCurves }
