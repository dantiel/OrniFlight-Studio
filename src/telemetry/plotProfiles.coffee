clonePlots = (plots) -> plots.map (plot) ->
  { plot..., curves: plot.curves[...] }

DEFAULTS =
  airframe:
    full: [
      { id: 'flight-envelope', title: 'Flight envelope', curves: ['wingL', 'wingR', 'gyroPitch'] }
    ]
    split: [
      { id: 'wing-motion', title: 'Wing motion', curves: ['wingL', 'wingR'] }
      { id: 'wing-servos', title: 'Wing servos', curves: ['servo1', 'servo2'] }
    ]
    compact: [
      { id: 'left-drive', title: 'Left drive', curves: ['wingL', 'servo1'] }
      { id: 'right-drive', title: 'Right drive', curves: ['wingR', 'servo2'] }
      { id: 'airframe-rates', title: 'Body rates', curves: ['gyroRoll', 'gyroPitch'] }
    ]
  control:
    full: [
      { id: 'control-response', title: 'Control response', curves: ['gyroRoll', 'gyroPitch', 'gyroYaw'] }
    ]
    split: [
      { id: 'body-response', title: 'Body response', curves: ['gyroRoll', 'gyroPitch', 'gyroYaw'] }
      { id: 'control-output', title: 'Control output', curves: ['servo1', 'servo2', 'servo3', 'servo4'] }
    ]
    compact: [
      { id: 'roll-loop', title: 'Roll loop', curves: ['rcRoll', 'gyroRoll'] }
      { id: 'pitch-loop', title: 'Pitch loop', curves: ['rcPitch', 'gyroPitch'] }
      { id: 'yaw-loop', title: 'Yaw loop', curves: ['rcYaw', 'gyroYaw'] }
    ]
  sensors:
    full: [
      { id: 'gyro-all', title: 'Gyroscope', curves: ['gyroRoll', 'gyroPitch', 'gyroYaw'] }
    ]
    split: [
      { id: 'gyro-rp', title: 'Roll + pitch rates', curves: ['gyroRoll', 'gyroPitch'] }
      { id: 'gyro-yaw', title: 'Yaw rate', curves: ['gyroYaw'] }
    ]
    compact: [
      { id: 'gyro-roll', title: 'Roll', curves: ['gyroRoll'] }
      { id: 'gyro-pitch', title: 'Pitch', curves: ['gyroPitch'] }
      { id: 'gyro-yaw-compact', title: 'Yaw', curves: ['gyroYaw'] }
    ]
  receiver:
    full: [
      { id: 'receiver-inputs', title: 'Receiver inputs', curves: ['rcThrottle', 'rcRoll', 'rcPitch', 'rcYaw'] }
    ]
    split: [
      { id: 'primary-channels', title: 'Primary channels', curves: ['rcRoll', 'rcPitch', 'rcYaw'] }
      { id: 'receiver-link', title: 'Receiver link', curves: ['linkQuality', 'rssi'] }
    ]
    compact: [
      { id: 'sticks', title: 'Stick channels', curves: ['rcRoll', 'rcPitch', 'rcYaw'] }
      { id: 'throttle-channel', title: 'Throttle', curves: ['rcThrottle'] }
      { id: 'link-health', title: 'Link health', curves: ['linkQuality', 'rssi'] }
    ]

profileKey = (workspace, mode) -> "#{workspace}:#{mode}"

defaultPlots = (workspace, mode) ->
  group = DEFAULTS[workspace] or DEFAULTS.airframe
  clonePlots group[mode] or group.split

export { DEFAULTS, profileKey, defaultPlots, clonePlots }
