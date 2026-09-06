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

isHeaderAt = (bytes, offset) ->
  bytes[offset] == 0x24 and bytes[offset + 1] == 0x58

class MspV2Parser
  constructor: ->
    @buffer = new Uint8Array 0

  reset: -> @buffer = new Uint8Array 0

  push: (chunk) ->
    incoming = asBytes chunk
    merged =
      if @buffer.length == 0
        incoming
      else
        combined = new Uint8Array @buffer.length + incoming.length
        combined.set @buffer
        combined.set incoming, @buffer.length
        combined
    frames = []
    pos = 0

    loop
      # single left-to-right scan — skips advance pos without rescanning
      while pos + 1 < merged.length and not isHeaderAt(merged, pos)
        pos++
      break if pos + 1 >= merged.length # no $X pair left
      break if pos + FRAME_OVERHEAD > merged.length # incomplete header

      direction = String.fromCharCode merged[pos + 2]
      unless direction in ['<', '>', '!']
        pos++
        continue

      command = merged[pos + 4] | merged[pos + 5] << 8
      length = merged[pos + 6] | merged[pos + 7] << 8
      flags = merged[pos + 3]
      frameLength = FRAME_OVERHEAD + length
      break if pos + frameLength > merged.length # incomplete frame

      crc = 0
      for index in [pos + 3...pos + HEADER_SIZE]
        crc = crc8DvbS2 crc, merged[index]
      for index in [pos + HEADER_SIZE...pos + HEADER_SIZE + length]
        crc = crc8DvbS2 crc, merged[index]

      receivedCrc = merged[pos + frameLength - 1]
      payload = merged.slice pos + HEADER_SIZE, pos + HEADER_SIZE + length
      if crc != receivedCrc
        frames.push { error: new MspCrcError(command), command, direction }
      else
        frames.push { command, direction, flags, payload }
      pos += frameLength

    @buffer =
      if merged[pos] == 0x24
        if pos == 0 and merged != incoming then merged else merged.slice pos
      else
        new Uint8Array 0
    frames

export {
  asBytes, crc8DvbS2, encodeMspV2, MspV2Parser, MspCrcError
  HEADER_SIZE, FRAME_OVERHEAD, MAX_PAYLOAD
}