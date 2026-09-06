DEFAULT_BAUD = 115200

isWebSerialSupported = (serialApi = globalThis.navigator?.serial) -> Boolean serialApi

requestRuntimePort = (filters = [], serialApi = globalThis.navigator?.serial) ->
  unless isWebSerialSupported serialApi
    throw new Error 'WebSerial is not available in this browser'
  options = if filters.length then { filters } else {}
  serialApi.requestPort options

class WebSerialRuntimeTransport
  constructor: (@port, options = {}) ->
    throw new TypeError 'A SerialPort is required' unless @port
    @baudRate = options.baudRate or DEFAULT_BAUD
    @serialApi = options.serialApi or globalThis.navigator?.serial
    @dataHandler = ->
    @disconnectHandler = ->
    @reader = null
    @writer = null
    @opened = false
    @reading = false
    @closing = false
    @disconnectListener = (event) =>
      eventPort = event.port or event.target
      @_notifyDisconnect(new Error('Flight controller disconnected')) if eventPort == @port

  onData: (handler) -> @dataHandler = handler or (->)
  onDisconnect: (handler) -> @disconnectHandler = handler or (->)

  info: ->
    usb = @port.getInfo?() or {}
    { usbVendorId: usb.usbVendorId, usbProductId: usb.usbProductId, baudRate: @baudRate }

  open: ->
    return if @opened
    @closing = false
    await @port.open
      baudRate: @baudRate
      dataBits: 8
      stopBits: 1
      parity: 'none'
      flowControl: 'none'
    @writer = @port.writable.getWriter()
    @opened = true
    @reading = true
    @serialApi?.addEventListener? 'disconnect', @disconnectListener
    @_readLoop()

  write: (bytes) ->
    throw new Error 'Runtime serial transport is not open' unless @opened and @writer
    @writer.write bytes

  close: ->
    return unless @opened or @reader or @writer
    @closing = true
    @reading = false
    @serialApi?.removeEventListener? 'disconnect', @disconnectListener
    try await @reader?.cancel() catch error then null
    try @reader?.releaseLock() catch error then null
    @reader = null
    try await @writer?.close() catch error then null
    try @writer?.releaseLock() catch error then null
    @writer = null
    try await @port.close() catch error then null
    @opened = false
    @closing = false

  _readLoop: ->
    try
      @reader = @port.readable.getReader()
      while @reading
        { value, done } = await @reader.read()
        break if done
        @dataHandler value if value?.length
      @_notifyDisconnect(new Error('Flight controller closed the serial stream')) if @reading
    catch error
      @_notifyDisconnect error if @reading
    finally
      try @reader?.releaseLock() catch error then null
      @reader = null

  _notifyDisconnect: (error) ->
    return if @closing or not @opened
    @reading = false
    @opened = false
    @disconnectHandler error

export default WebSerialRuntimeTransport
export {
  WebSerialRuntimeTransport, isWebSerialSupported, requestRuntimePort
  DEFAULT_BAUD
}
