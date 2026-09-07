import MSP_CODES from './mspCodes.coffee'
import {
  decodeApiVersion, decodeVariant, decodeVersion, decodeBuildInfo
  decodeBoardInfo, decodeUid, decodeName, decodeStatus, decodeRawImu
  decodeAttitude, decodeChannels, decodeRxMap, decodeServos
  decodeAnalog, decodeBatteryState, encodeName
  decodeServoConfigurations, encodeServoConfiguration, MAX_SERVO_CONFIGS
  decodePidTuning, encodePidTuning, PID_AXES, PID_TERMS
  decodeRcTuning, encodeRcTuning
  decodeFilterConfig, encodeFilterConfig
  decodeOndas, encodeOndas, ONDAS_DEFAULTS, TUNING_FALLBACKS
} from './mspDecoders.coffee'

POLL_INTERVAL_MS = 100
STATUS_EVERY_ROUNDS = 5

class FirmwareCompatibilityError extends Error
  constructor: (message, details = {}) ->
    super message
    @name = 'FirmwareCompatibilityError'
    Object.assign this, details

class OrniFlightSession
  constructor: (@client, callbacks = {}) ->
    @onTelemetry = callbacks.onTelemetry or (->)
    @onStatus = callbacks.onStatus or (->)
    @onFailure = callbacks.onFailure or (->)
    @running = false
    @timer = null
    @round = 0
    @identity = null
    @lastStatus = null
    @lastAnalog = { voltage: 0, rssiRaw: 0, amperage: 0, consumedMah: 0 }
    @lastBattery = null
    @rxMap = []

  handshake: ->
    api = decodeApiVersion await @client.request MSP_CODES.API_VERSION, [], { timeoutMs: 1500 }
    unless api.major == 1
      throw new FirmwareCompatibilityError "Unsupported MSP API major #{api.major}", { api }

    variant = decodeVariant await @client.request MSP_CODES.FC_VARIANT
    unless variant == 'ORNI'
      throw new FirmwareCompatibilityError "Expected OrniFlight firmware, received #{variant}", { variant, api }

    firmware = decodeVersion await @client.request MSP_CODES.FC_VERSION
    build = decodeBuildInfo await @client.request MSP_CODES.BUILD_INFO
    board = decodeBoardInfo await @client.request MSP_CODES.BOARD_INFO
    uidPayload = await @client.requestOptional MSP_CODES.UID
    namePayload = await @client.requestOptional MSP_CODES.NAME
    status = decodeStatus await @client.request(MSP_CODES.STATUS_EX), true
    rxMapPayload = await @client.requestOptional MSP_CODES.RX_MAP
    @rxMap = if rxMapPayload then decodeRxMap(rxMapPayload) else []
    @lastStatus = status

    @identity = {
      api, variant, firmware, build, board, status
      uid: if uidPayload then decodeUid(uidPayload) else null
      name: if namePayload then decodeName(namePayload) else ''
      rxMap: @rxMap
      capabilities:
        vcp: Boolean(board.targetCapabilities & 1)
        softSerial: Boolean(board.targetCapabilities & 2)
        unifiedTarget: Boolean(board.targetCapabilities & 4)
        sensors: status.sensors
    }
    @onStatus status
    @identity

  start: ->
    return if @running
    throw new Error 'Handshake must complete before telemetry starts' unless @identity
    @running = true
    @round = 0
    @_poll()

  stop: ->
    @running = false
    clearTimeout @timer if @timer
    @timer = null

  close: ->
    @stop()
    await @client.close()

  setCraftName: (name) ->
    throw new Error 'Cannot write configuration while armed' if @lastStatus?.armed
    value = String(name or '').trim()
    throw new Error 'Craft name must contain 1–24 characters' unless value.length in [1..24]
    await @client.request MSP_CODES.SET_NAME, encodeName(value)
    await @client.request MSP_CODES.EEPROM_WRITE
    readBack = decodeName await @client.request MSP_CODES.NAME
    unless readBack == value
      throw new Error "Craft name read-back failed: expected #{value}, received #{readBack}"
    @identity = { @identity..., name: readBack }
    @identity

  readServoConfigurations: ->
    payload = await @client.requestOptional MSP_CODES.SERVO_CONFIGURATIONS
    if payload then decodeServoConfigurations(payload) else []

  writeServoConfiguration: (index, config = {}) ->
    throw new Error 'Cannot write configuration while armed' if @lastStatus?.armed
    unless Number.isInteger(index) and 0 <= index < MAX_SERVO_CONFIGS
      throw new Error "Servo index out of range: #{index}"
    payload = encodeServoConfiguration index, config
    await @client.request MSP_CODES.SET_SERVO_CONFIGURATION, payload
    await @client.request MSP_CODES.EEPROM_WRITE
    stored = await @readServoConfigurations()
    written = stored[index]
    expected =
      min: config.min ? 1000
      max: config.max ? 2000
      middle: config.middle ? 1500
    matches = written? and written.min == expected.min and
      written.max == expected.max and written.middle == expected.middle
    unless matches
      throw new Error(
        "Servo configuration read-back failed at index #{index}"
      )
    { index, config: written }

  readTuning: ->
    pidPayload = await @client.requestOptional MSP_CODES.PID
    ratePayload = await @client.requestOptional MSP_CODES.RC_TUNING
    filterPayload = await @client.requestOptional MSP_CODES.FILTER_CONFIG
    ondasPayload = await @client.requestOptional MSP_CODES.ONDAS
    {
      pid: if pidPayload
        decodePidTuning pidPayload
      else
        { TUNING_FALLBACKS.pid... }
      rate: if ratePayload
        decodeRcTuning ratePayload
      else
        { TUNING_FALLBACKS.rate... }
      ondas: if ondasPayload
        decodeOndas ondasPayload
      else
        { ONDAS_DEFAULTS... }
      filter: if filterPayload
        decodeFilterConfig filterPayload
      else
        { TUNING_FALLBACKS.filter... }
    }

  writeTuning: (tuning) ->
    throw new Error 'Cannot write configuration while armed' if @lastStatus?.armed
    await @client.request MSP_CODES.SET_PID, encodePidTuning tuning.pid
    await @client.request MSP_CODES.SET_RC_TUNING, encodeRcTuning tuning.rate
    await @client.request MSP_CODES.SET_FILTER_CONFIG, encodeFilterConfig tuning.filter
    await @client.request MSP_CODES.SET_ONDAS, encodeOndas tuning.ondas
    await @client.request MSP_CODES.EEPROM_WRITE
    readBack = await @readTuning()
    for section in ['pid', 'rate', 'ondas', 'filter']
      unless tuningSectionMatches section, tuning[section], readBack[section]
        throw new Error "Tuning read-back failed: #{section}"
    readBack

  _poll: ->
    return unless @running
    try
      rawImu = decodeRawImu await @client.request MSP_CODES.RAW_IMU
      attitude = decodeAttitude await @client.request MSP_CODES.ATTITUDE
      channels = decodeChannels await @client.request MSP_CODES.RC
      servoPayload = await @client.requestOptional MSP_CODES.SERVO
      servos = if servoPayload then decodeServos(servoPayload) else []

      if @round % STATUS_EVERY_ROUNDS == 0
        @lastStatus = decodeStatus await @client.request(MSP_CODES.STATUS_EX), true
        analogPayload = await @client.requestOptional MSP_CODES.ANALOG
        @lastAnalog = decodeAnalog(analogPayload) if analogPayload
        batteryPayload = await @client.requestOptional MSP_CODES.BATTERY_STATE
        @lastBattery = decodeBatteryState(batteryPayload) if batteryPayload
        @onStatus @lastStatus

      voltage = @lastBattery?.voltage or @lastAnalog.voltage or 0
      rssi = Math.max 0, Math.min 100, @lastAnalog.rssiRaw / 1023 * 100
      [roll, pitch, yaw] = rawImu.gyroscope
      [accelX, accelY, accelZ] = rawImu.acceleration
      channel = (logicalIndex) =>
        sourceIndex = @rxMap[logicalIndex]
        sourceIndex = logicalIndex unless Number.isInteger sourceIndex
        channels[sourceIndex] or 0

      @onTelemetry {
        t: (globalThis.performance?.now?() or Date.now()) / 1000
        gyroRoll: roll, gyroPitch: pitch, gyroYaw: yaw
        attitude, accelX, accelY, accelZ
        magnetometer: rawImu.magnetometer
        servos
        rcChannels: channels
        rcRoll: channel(0), rcPitch: channel(1), rcYaw: channel(2), rcThrottle: channel(3)
        batteryVoltage: voltage
        amperage: @lastBattery?.amperage or @lastAnalog.amperage or 0
        consumedMah: @lastBattery?.consumedMah or @lastAnalog.consumedMah or 0
        rssi, linkQuality: 0
        wingAngleL: 0, wingAngleR: 0, amplitude: 0, flapFrequency: 0
        source: 'device'
      }
      @round += 1
      @timer = setTimeout (=> @_poll()), POLL_INTERVAL_MS if @running
    catch error
      @stop()
      @onFailure error

# Section-wise comparison for tuning read-back verification. PID gains
# compare at wire precision (×1000); the remaining sections are integer
# documents compared structurally.
tuningSectionMatches = (section, expected = {}, actual = {}) ->
  if section == 'pid'
    for axis in PID_AXES
      for term in PID_TERMS
        a = Math.round (actual[axis]?[term] ? 0) * 1000
        e = Math.round (expected[axis]?[term] ? 0) * 1000
        return false unless a == e
    true
  else
    JSON.stringify(actual) == JSON.stringify(expected)

export default OrniFlightSession
export { OrniFlightSession, FirmwareCompatibilityError, POLL_INTERVAL_MS }