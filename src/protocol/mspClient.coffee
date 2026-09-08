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
    @rawListener = null

  open: ->
    return @opening if @opening
    @opening = do =>
      return if @opened
      @transport.onData (bytes) => @_route bytes
      @transport.onDisconnect (error) => @_disconnected error
      await @transport.open()
      @opened = true
    try
      await @opening
    finally
      @opening = null

  close: ->
    @opened = false
    @rawListener = null
    @_rejectPending new MspDisconnectedError()
    @parser.reset()
    await @transport.close()

  # ═══ CLI takeover ═══════════════════════════════════════════
  # detach() hands the byte stream to a raw listener (the CLI text
  # channel); attach() restores MSP frame routing. The transport
  # data slot stays bound once — this client is the single routing
  # authority. Pending MSP requests are cancelled silently: the
  # session is stopped at this point and must never see a failure.
  detach: (rawListener) ->
    throw new Error 'A raw data listener is required' unless rawListener?
    @rawListener = rawListener
    @_cancelPending()
    @parser.reset()
    null

  attach: ->
    @rawListener = null
    null

  isDetached: -> @rawListener?

  _cancelPending: ->
    return unless @pending
    clearTimeout @pending.timer
    @pending = null

  _route: (bytes) ->
    if @rawListener then @rawListener bytes else @_receive bytes

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

  # Fire-and-forget write: one-shot commands (ACC_CALIBRATION,
  # MAG_CALIBRATION) never produce a firmware answer, so no pending
  # request is registered and no response is awaited.
  send: (command, payload = []) ->
    throw new MspDisconnectedError() unless @opened
    frame = encodeMspV2 command, payload
    @transport.write frame

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
        @_dispatch @errorListeners, frame.error
        continue
      @_dispatch @frameListeners, frame
      continue unless @pending?.command == frame.command
      if frame.direction == '!'
        @pending.reject new MspUnsupportedError(frame.command)
      else if frame.direction == '>'
        @pending.resolve frame.payload

  # Listener exceptions must never tear down the transport read loop.
  # forEach — not `for..in` — because these are Sets without .length.
  _dispatch: (listeners, argument) ->
    listeners.forEach (listener) ->
      try
        listener argument
      catch error
        null

  _rejectPending: (error) -> @pending?.reject error

  _disconnected: (error) ->
    wasOpen = @opened
    @opened = false
    @rawListener = null
    @_rejectPending error or new MspDisconnectedError()
    @_dispatch @errorListeners, error if wasOpen

export default MspClient
export {
  MspClient, MspTimeoutError, MspUnsupportedError, MspDisconnectedError
}