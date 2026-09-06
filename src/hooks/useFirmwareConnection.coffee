import useConnection, { getActor } from './useConnection.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'
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

setConnectedCraftName = (name) ->
  throw new Error 'No flight controller is connected' unless _session
  identity = await _session.setCraftName name
  useDeviceStore.getState().setDevice identity
  identity

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
  }

export default useFirmwareConnection
export {
  connectFirmware, disconnectFirmware, setConnectedCraftName
  publishTelemetry
}