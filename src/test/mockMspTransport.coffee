# In-memory transport double for MSP tests. Implements the runtime
# transport interface — open()/close()/write(bytes)/onData()/onDisconnect()
# — so MspClient and OrniFlightSession can be exercised without hardware.
# This is the polymorphic proof: the MSP layer never touches WebSerial.
import { encodeMspV2 } from '../protocol/mspCodec.coffee'

scriptedResponder = (script) ->
  # script: command -> payload bytes | 'unsupported' | null (no response)
  (bytes) ->
    command = bytes[4] | bytes[5] << 8
    return null unless Object::hasOwnProperty.call script, command
    spec = script[command]
    return null unless spec?
    if spec == 'unsupported'
      { command, direction: '!', payload: [] }
    else
      { command, direction: '>', payload: spec }

class MockMspTransport
  constructor: (options = {}) ->
    @writes = []
    @dataHandlers = new Set()
    @disconnectHandlers = new Set()
    @opened = false
    @closed = false
    @autoRespond = options.autoRespond ? false
    @responder = options.responder ? null
    @writeImpl = options.write ? (-> Promise.resolve())

  open: -> @opened = true; Promise.resolve()
  close: -> @closed = true; @opened = false; Promise.resolve()

  onData: (handler) -> @dataHandlers.add handler
  onDisconnect: (handler) -> @disconnectHandlers.add handler

  write: (bytes) ->
    @writes.push Array.from bytes
    if @autoRespond
      response = @responder?(bytes)
      if response
        Promise.resolve().then =>
          @emit encodeMspV2 response.command, response.payload, response.direction
    @writeImpl bytes

  emit: (bytes) ->
    @dataHandlers.forEach (handler) -> handler bytes

  emitFrame: (command, payload = [], direction = '>') ->
    @emit encodeMspV2 command, payload, direction

  disconnect: (error = null) ->
    @disconnectHandlers.forEach (handler) -> handler error

  commandOf: (writeIndex = 0) ->
    bytes = @writes[writeIndex]
    return null unless bytes?
    bytes[4] | bytes[5] << 8

  payloadOf: (writeIndex = 0) ->
    bytes = @writes[writeIndex]
    return null unless bytes?
    length = bytes[6] | bytes[7] << 8
    bytes.slice 8, 8 + length

export default MockMspTransport
export { MockMspTransport, scriptedResponder }
