###
# ORNIFLIGHT STUDIO — STM32 USART bootloader protocol (AN3155)
#
# Pure wire grammar over a minimal byte-port abstraction:
#   read(count)  -> Promise<Uint8Array>  (exact count, or throw)
#   write(bytes) -> Promise<void>
#
# No DOM / WebSerial / React here — the transport owns the port,
# this module owns the protocol. Every command returns Result.
#
# Handshake: host sends 0x7F, bootloader answers 0x79 (ACK).
# Commands are sent as [cmd, ~cmd]; NACK is 0x1F.
###
import { Result } from '../lib/essential.coffee'

ACK  = 0x79
NACK = 0x1F

# ── byte helpers ─────────────────────────────
xorOf = (bytes) ->
  acc = 0
  for b in bytes
    acc ^= b
  acc

readByte = (port) ->
  (await port.read 1)[0]

expectAck = (port, b) ->
  if b is ACK then Result.ok null
  else Result.err "bootloader NACK (got 0x#{b?.toString 16})"

encodeAddress = (address) ->
  [
    address >> 24 & 0xFF
    address >> 16 & 0xFF
    address >> 8 & 0xFF
    address & 0xFF
  ]

# ── handshake + commands ─────────────────────
sync = (port) ->
  await port.write Uint8Array.from [0x7F]
  expectAck port, (await readByte port)

sendCommand = (port, cmd) ->
  await port.write Uint8Array.from [cmd, cmd ^ 0xFF]
  b = await readByte port
  if b is ACK
    Result.ok null
  else
    Result.err "command 0x#{cmd.toString 16} NACK (got 0x#{b?.toString 16})"

# 0x00 — supported commands (byte 0 = version, rest = command set)
getCommands = (port) ->
  r = await sendCommand port, 0x00
  return r unless r.ok
  n = await readByte port
  payload = await port.read n
  unless (await readByte port) is ACK
    return Result.err 'get: missing trailing ACK'
  Result.ok { version: payload[0], commands: Array.from payload.slice 1 }

# 0x01 — bootloader version
getVersion = (port) ->
  r = await sendCommand port, 0x01
  return r unless r.ok
  v = await readByte port
  await port.read 2                    # option bytes (not used)
  unless (await readByte port) is ACK
    return Result.err 'version: missing trailing ACK'
  Result.ok v

# 0x02 — product/device ID (little-endian PID)
getDeviceId = (port) ->
  r = await sendCommand port, 0x02
  return r unless r.ok
  n = await readByte port
  pid = Array.from await port.read n
  unless (await readByte port) is ACK
    return Result.err 'getid: missing trailing ACK'
  value = pid.reduce ((acc, b, i) -> acc + (b << (8 * i))), 0
  Result.ok value

# 0x11 — read memory
readMemory = (port, address, count) ->
  r = await sendCommand port, 0x11
  return r unless r.ok
  addr = encodeAddress address
  await port.write Uint8Array.from addr.concat [xorOf addr]
  unless (await readByte port) is ACK
    return Result.err 'read: address NACK'
  n = count - 1
  await port.write Uint8Array.from [n, n ^ 0xFF]
  unless (await readByte port) is ACK
    return Result.err 'read: count NACK'
  Result.ok (await port.read count)

# 0x31 — write memory (max 256 bytes per call)
writeMemory = (port, address, data) ->
  r = await sendCommand port, 0x31
  return r unless r.ok
  addr = encodeAddress address
  await port.write Uint8Array.from addr.concat [xorOf addr]
  unless (await readByte port) is ACK
    return Result.err 'write: address NACK'
  body = [data.length - 1].concat Array.from data
  await port.write Uint8Array.from body.concat [xorOf body]
  unless (await readByte port) is ACK
    return Result.err 'write: data NACK'
  Result.ok null

# 0x43 — erase pages (regular erase, ≤255 pages)
erasePages = (port, pages) ->
  r = await sendCommand port, 0x43
  return r unless r.ok
  body = [pages.length]
  for p in pages
    body.push (p >> 8) & 0xFF, p & 0xFF
  await port.write Uint8Array.from body.concat [xorOf body]
  unless (await readByte port) is ACK
    return Result.err 'erase: NACK'
  Result.ok null

# 0x44 — extended erase; N=0xFFFF is a global mass erase
massErase = (port) ->
  r = await sendCommand port, 0x44
  return r unless r.ok
  await port.write Uint8Array.from [0xFF, 0xFF, 0x00]
  unless (await readByte port) is ACK
    return Result.err 'mass erase: NACK'
  Result.ok null

# 0x21 — jump to address
go = (port, address) ->
  r = await sendCommand port, 0x21
  return r unless r.ok
  addr = encodeAddress address
  await port.write Uint8Array.from addr.concat [xorOf addr]
  unless (await readByte port) is ACK
    return Result.err 'go: NACK'
  Result.ok null

# ── chip knowledge ───────────────────────────
CHIP_IDS =
  0x413: { target: 'ORNI-F4', mcu: 'STM32F405RGT6', flash: '1 MB' }
  0x452: { target: 'ORNI-F7', mcu: 'STM32F722RET6', flash: '512 KB' }
  0x431: { target: 'ORNI-F4', mcu: 'STM32F411CEU6', flash: '512 KB' }
  0x433: { target: 'ORNI-F4', mcu: 'STM32F401CCU6', flash: '256 KB' }
  0x410: { target: 'ORNI-F1', mcu: 'STM32F103C8T6', flash: '64 KB' }
  0x412: { target: 'ORNI-F1', mcu: 'STM32F103CBT6', flash: '128 KB' }
  0x414: { target: 'ORNI-F1', mcu: 'STM32F103RET6', flash: '512 KB' }

# sector sizes in KiB, flash-layout order
SECTOR_MAP =
  0x413: [16, 16, 16, 16, 64, 128, 128, 128, 128, 128, 128, 128]
  0x452: [16, 16, 16, 16, 64, 128, 128, 128, 64]
  0x431: [16, 16, 16, 16, 64, 128, 128]
  0x433: [16, 16, 16, 16, 64, 128]
  0x410: (1 for _ in [0...64])
  0x412: (1 for _ in [0...128])
  0x414: [16, 16, 16, 16, 64, 128, 128, 128, 128, 128]

# page numbers covering `sizeBytes` from sector 0
sectorsFor = (chipId, sizeBytes) ->
  map = SECTOR_MAP[chipId] or (128 for _ in [0...8])
  sizeKb = Math.ceil sizeBytes / 1024
  sectors = []
  remaining = sizeKb
  for kb, i in map
    break if remaining <= 0
    sectors.push i
    remaining -= kb
  sectors

export {
  ACK, NACK
  xorOf
  sync, sendCommand
  getCommands, getVersion, getDeviceId
  readMemory, writeMemory, erasePages, massErase, go
  CHIP_IDS, SECTOR_MAP, sectorsFor
}