import useConnection, { getActor } from './useConnection.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'
import useConfigurationStore from '../stores/useConfigurationStore.coffee'
import useTuningStore from '../stores/useTuningStore.coffee'
import useTelemetryStore from '../stores/useTelemetryStore.coffee'
import { pushTelemetry } from '../streams/telemetryStream.coffee'
import WebSerialRuntimeTransport, {
  isWebSerialSupported, requestRuntimePort
} from '../transport/webSerialRuntimeTransport.coffee'
import MspClient from '../protocol/mspClient.coffee'
import OrniFlightSession from '../protocol/orniFlightSession.coffee'

_session = null
_client = null
_closing = false
_cliErrorUnsubscribe = null
CLI_ENTER_GUARD_MS = 300

delay = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

publishTelemetry = (frame) ->
  pushTelemetry frame
  useTelemetryStore.getState().update frame
  useTelemetryStore.getState().setConnected true
  useDeviceStore.getState().setLiveData frame.rcChannels, frame.servos

cleanup = ->
  session = _session
  client = _client
  _session = null
  _client = null
  _cliErrorUnsubscribe?()
  _cliErrorUnsubscribe = null
  useConfigurationStore.getState().attachSession null
  useConfigurationStore.getState().setMode 'sim'
  useTuningStore.getState().attachSession null
  useTuningStore.getState().setMode 'sim'
  session?.stop()
  try
    if session then await session.close() else await client?.close()
  catch error
    null

failConnection = (error) ->
  return if _closing
  state = useDeviceStore.getState()
  state.setError error
  useTelemetryStore.getState().setConnected false
  getActor().send { type: 'CONNECTION_FAILED', error: error?.message or 'connection_failed' }
  await cleanup()

connectFirmware = ->
  return false if _session or _client
  actor = getActor()
  store = useDeviceStore.getState()
  actor.send { type: 'CONNECT' }
  store.setConnecting()

  try
    port = await requestRuntimePort()
    transport = new WebSerialRuntimeTransport port
    client = new MspClient transport, { timeoutMs: 1000 }
    _client = client
    await client.open()
    actor.send { type: 'CONNECTED', portInfo: transport.info() }

    session = new OrniFlightSession client,
      onTelemetry: publishTelemetry
      onStatus: (status) -> useDeviceStore.getState().setStatus status
      onFailure: (error) -> failConnection error
    _session = session
    identity = await session.handshake()
    store.setDevice identity
    actor.send { type: 'FIRMWARE_READY', version: identity.api.version }
    session.start()
    useConfigurationStore.getState().attachSession session
    useConfigurationStore.getState().setMode 'device'
    useTuningStore.getState().attachSession session
    useTuningStore.getState().setMode 'device'
    true
  catch error
    # A cancelled browser picker is a normal return to offline mode.
    if error?.name == 'NotFoundError'
      store.setSimulation()
      actor.send { type: 'DISCONNECTED' }
      await cleanup()
    else
      await failConnection error
    false

disconnectFirmware = ->
  _closing = true
  try
    await cleanup()
    useDeviceStore.getState().setSimulation()
    useTelemetryStore.getState().setConnected false
    getActor().send { type: 'DISCONNECTED' }
  finally
    _closing = false
  true

# ═══ CLI takeover bridge ══════════════════════════════════════
# enterCli stops the MSP session, detaches the MspClient's byte
# routing to the CLI listener, waits out the firmware's 100ms
# idle guard, then sends the raw '#' that enters CLI mode.
# Disconnects while the CLI owns the stream route through
# failConnection — the session is stopped and cannot see them.
enterCli = (onData) ->
  unless _session and _client
    throw new Error 'No flight controller is connected'
  _session.stop()
  _client.detach onData
  _cliErrorUnsubscribe = _client.onError (error) -> failConnection error
  await delay CLI_ENTER_GUARD_MS
  await _client.transport.write new Uint8Array [0x23]
  true

# Restores MSP routing and telemetry. Returns false when the
# connection is already gone (the firmware reboots on CLI exit,
# so the common return path is a transport disconnect instead).
leaveCli = ->
  _cliErrorUnsubscribe?()
  _cliErrorUnsubscribe = null
  client = _client
  session = _session
  return false unless client
  client.attach()
  session?.start()
  true

writeCliBytes = (bytes) ->
  unless _client?.isDetached?()
    throw new Error 'CLI channel is not open'
  await _client.transport.write bytes

isCliOwned = -> Boolean _client?.isDetached?()

setConnectedCraftName = (name) ->
  throw new Error 'No flight controller is connected' unless _session
  identity = await _session.setCraftName name
  useDeviceStore.getState().setDevice identity
  identity

readConnectedServoConfigurations = ->
  throw new Error 'No flight controller is connected' unless _session
  await _session.readServoConfigurations()

writeConnectedServoConfiguration = (index, config = {}) ->
  throw new Error 'No flight controller is connected' unless _session
  await _session.writeServoConfiguration index, config

useFirmwareConnection = ->
  connection = useConnection()
  source = useDeviceStore (state) -> state.source
  identity = useDeviceStore (state) -> state.identity
  lastError = useDeviceStore (state) -> state.lastError
  {
    connection..., source, identity, lastError
    supported: isWebSerialSupported()
    connect: connectFirmware
    disconnect: disconnectFirmware
    setCraftName: setConnectedCraftName
    readServoConfigurations: readConnectedServoConfigurations
    writeServoConfiguration: writeConnectedServoConfiguration
  }

export default useFirmwareConnection
export {
  connectFirmware, disconnectFirmware, setConnectedCraftName
  readConnectedServoConfigurations, writeConnectedServoConfiguration
  enterCli, leaveCli, writeCliBytes, isCliOwned
  publishTelemetry
}