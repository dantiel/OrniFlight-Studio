class ByteReader
  constructor: (bytes) ->
    @bytes = if bytes instanceof Uint8Array then bytes else Uint8Array.from(bytes or [])
    @view = new DataView @bytes.buffer, @bytes.byteOffset, @bytes.byteLength
    @offset = 0

  remaining: -> @bytes.length - @offset

  require: (count) ->
    if @remaining() < count
      throw new RangeError "MSP payload truncated: need #{count}, have #{@remaining()}"

  u8: ->
    @require 1
    @view.getUint8 @offset++

  i8: ->
    @require 1
    value = @view.getInt8 @offset
    @offset += 1
    value

  u16: ->
    @require 2
    value = @view.getUint16 @offset, true
    @offset += 2
    value

  i16: ->
    @require 2
    value = @view.getInt16 @offset, true
    @offset += 2
    value

  u32: ->
    @require 4
    value = @view.getUint32 @offset, true
    @offset += 4
    value

  take: (count) ->
    @require count
    value = @bytes.slice @offset, @offset + count
    @offset += count
    value

  ascii: (count) ->
    Array.from(@take(count)).map((value) -> String.fromCharCode value).join ''

  lengthPrefixedAscii: -> @ascii @u8()

export default ByteReader
export { ByteReader }
