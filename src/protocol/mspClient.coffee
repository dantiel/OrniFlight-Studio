import { encodeMspV2, MspV2Parser } from './mspCodec.coffee'

class MspTimeoutError extends Error
  constructor: (command, timeoutMs) ->
    super "MSP command #{command} timed out after #{timeoutMs}ms"
    @name = 'MspTimeoutError'
    @command = command

class MspUnsupportedError extends Error
  constructor: (command) ->
    super "MSP command #{command} is not supported by this target"
    @name = 'MspUnsupportedError'
    @command = command

class MspDisconnectedError extends Error
  constructor: (message = 'MSP transport disconnected') ->
    super message
    @name = 'MspDisconnectedError'

class MspClient
  constructor: (@transport, options = {}) ->
    @timeoutMs = options.timeoutMs or 1000
    @parser = new MspV2Parser()
    @pending = null
    @queue = Promise.resolve()
    @opened = false
    @frameListeners = new Set()
    @errorListeners = new Set()

  open: ->
    return if @opened
    @transport.onData (bytes) => @_receive bytes
    @transport.onDisconnect (error) => @_disconnected error
    await @transport.open()
    @opened = true

  close: ->
    @opened = false
    @_rejectPending new MspDisconnectedError()
    @parser.reset()
    await @transport.close()

  onFrame: (listener) ->
    @frameListeners.add listener
    -> @frameListeners.delete listener

  onError: (listener) ->
    @errorListeners.add listener
    -> @errorListeners.delete listener

  request: (command, payload = [], options = {}) ->
    run = => @_request command, payload, options
    result = @queue.then run, run
    @queue = result.catch -> null
    result

  requestOptional: (command, payload = [], options = {}) ->
    try
      await @request command, payload, options
    catch error
      return null if error instanceof MspUnsupportedError
      throw error

  _request: (command, payload, options) ->
    throw new MspDisconnectedError() unless @opened
    timeoutMs = options.timeoutMs or @timeoutMs
    frame = encodeMspV2 command, payload

    new Promise (resolve, reject) =>
      finish = (fn, value) =>
        return unless @pending?.command == command
        clearTimeout @pending.timer
        @pending = null
        fn value

      timer = setTimeout (=>
        finish reject, new MspTimeoutError(command, timeoutMs)
      ), timeoutMs
      @pending =
        command: command
        resolve: (value) -> finish resolve, value
        reject: (error) -> finish reject, error
        timer: timer
      Promise.resolve()
        .then((=> @transport.write(frame)))
        .catch (error) => finish reject, error

  _receive: (bytes) ->
    for frame in @parser.push bytes
      if frame.error
        @errorListeners.forEach (listener) -> listener frame.error
        continue
      @frameListeners.forEach (listener) -> listener frame
      continue unless @pending?.command == frame.command
      if frame.direction == '!'
        @pending.reject new MspUnsupportedError(frame.command)
      else if frame.direction == '>'
        @pending.resolve frame.payload

  _rejectPending: (error) -> @pending?.reject error

  _disconnected: (error) ->
    wasOpen = @opened
    @opened = false
    @_rejectPending error or new MspDisconnectedError()
    if wasOpen
      @errorListeners.forEach (listener) -> listener error

export default MspClient
export {
  MspClient, MspTimeoutError, MspUnsupportedError, MspDisconnectedError
}