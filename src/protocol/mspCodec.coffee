HEADER_SIZE = 8
FRAME_OVERHEAD = 9
MAX_PAYLOAD = 0xffff

asBytes = (value = []) ->
  return value if value instanceof Uint8Array
  return new Uint8Array(value) if value instanceof ArrayBuffer
  Uint8Array.from value

crc8DvbS2 = (crc, value) ->
  crc ^= value
  for bit in [0...8]
    crc = if crc & 0x80 then ((crc << 1) ^ 0xd5) & 0xff else (crc << 1) & 0xff
  crc

encodeMspV2 = (command, payload = [], direction = '<', flags = 0) ->
  unless Number.isInteger(command) and command >= 0 and command <= 0xffff
    throw new RangeError 'MSPv2 command must fit in 16 bits'
  bytes = asBytes payload
  if bytes.length > MAX_PAYLOAD
    throw new RangeError 'MSPv2 payload must fit in 16 bits'
  unless direction in ['<', '>', '!']
    throw new TypeError 'MSPv2 direction must be <, >, or !'

  frame = new Uint8Array bytes.length + FRAME_OVERHEAD
  frame[0] = 0x24 # $
  frame[1] = 0x58 # X (native MSPv2)
  frame[2] = direction.charCodeAt 0
  frame[3] = flags & 0xff
  frame[4] = command & 0xff
  frame[5] = command >>> 8 & 0xff
  frame[6] = bytes.length & 0xff
  frame[7] = bytes.length >>> 8 & 0xff
  frame.set bytes, HEADER_SIZE

  crc = 0
  for index in [3...HEADER_SIZE]
    crc = crc8DvbS2 crc, frame[index]
  for value in bytes
    crc = crc8DvbS2 crc, value
  frame[frame.length - 1] = crc
  frame

class MspCrcError extends Error
  constructor: (command) ->
    super "MSPv2 CRC mismatch for command #{command}"
    @name = 'MspCrcError'
    @command = command

class MspV2Parser
  constructor: ->
    @buffer = new Uint8Array 0

  reset: -> @buffer = new Uint8Array 0

  push: (chunk) ->
    incoming = asBytes chunk
    merged = new Uint8Array @buffer.length + incoming.length
    merged.set @buffer
    merged.set incoming, @buffer.length
    @buffer = merged
    frames = []

    while @buffer.length >= 3
      start = -1
      for index in [0...@buffer.length - 1]
        if @buffer[index] == 0x24 and @buffer[index + 1] == 0x58
          start = index
          break

      if start < 0
        @buffer = if @buffer[@buffer.length - 1] == 0x24 then @buffer.slice(-1) else new Uint8Array 0
        break
      @buffer = @buffer.slice start if start > 0
      break if @buffer.length < FRAME_OVERHEAD

      direction = String.fromCharCode @buffer[2]
      unless direction in ['<', '>', '!']
        @buffer = @buffer.slice 1
        continue

      command = @buffer[4] | @buffer[5] << 8
      length = @buffer[6] | @buffer[7] << 8
      flags = @buffer[3]
      frameLength = FRAME_OVERHEAD + length
      break if @buffer.length < frameLength

      crc = 0
      for index in [3...HEADER_SIZE]
        crc = crc8DvbS2 crc, @buffer[index]
      for index in [HEADER_SIZE...HEADER_SIZE + length]
        crc = crc8DvbS2 crc, @buffer[index]

      receivedCrc = @buffer[frameLength - 1]
      payload = @buffer.slice HEADER_SIZE, HEADER_SIZE + length
      @buffer = @buffer.slice frameLength
      if crc != receivedCrc
        frames.push { error: new MspCrcError(command), command, direction }
      else
        frames.push { command, direction, flags, payload }

    frames

export {
  asBytes, crc8DvbS2, encodeMspV2, MspV2Parser, MspCrcError
  HEADER_SIZE, FRAME_OVERHEAD, MAX_PAYLOAD
}
