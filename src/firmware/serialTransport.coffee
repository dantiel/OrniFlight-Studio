###
# ORNIFLIGHT STUDIO — WebSerial transport for STM32 USART bootloader
#
# Hardware soul behind the same run()/reboot() interface the
# simulation exposes. Owns the WebSerial port, fetches the image,
# and drives the AN3155 protocol with timeouts and progress.
#
#   isSupported()            -> boolean
#   requestPort()            -> Promise<SerialPort>
#   detect(port, onLog)      -> Promise<device info>
#   run(actor, fw, opts, log)  -> Promise (full flash)
#   reboot(actor, log, port) -> Promise (jump to app)
###
import * as dfu from './dfuProtocol.coffee'
import { sha256Hex } from './firmwareCatalog.coffee'

BAUD       = 115200
FLASH_BASE = 0x08000000
WRITE_CHUNK = 256
READ_CHUNK  = 256

# ── capability ───────────────────────────────
isSupported = ->
  !!globalThis.navigator?.serial

requestPort = ->
  unless isSupported()
    throw new Error 'WebSerial is not available in this browser'
  globalThis.navigator.serial.requestPort()

withTimeout = (promise, ms, label) ->
  timer = new Promise (_, reject) ->
    setTimeout (-> reject new Error "#{label} timed out after #{ms}ms"), ms
  Promise.race [promise, timer]

# ── port IO (buffered read, blocking) ────────
makePortIO = (port) ->
  reader = port.readable.getReader()
  writer = port.writable.getWriter()
  buffer = new Uint8Array 0

  read = (count) ->
    while buffer.length < count
      { value, done } = await reader.read()
      if done then throw new Error 'port closed before read completed'
      merged = new Uint8Array buffer.length + value.length
      merged.set buffer, 0
      merged.set value, buffer.length
      buffer = merged
    out = buffer.slice 0, count
    buffer = buffer.slice count
    out

  {
    read
    write: (bytes) -> writer.write bytes
    close: ->
      try await writer.close() catch e then null
      try await reader.releaseLock() catch e then null
      try await port.close() catch e then null
  }

openPort = (port, baud = BAUD) ->
  await port.open
    baudRate: baud
    dataBits: 8
    stopBits: 1
    parity: 'none'
    flowControl: 'none'
  makePortIO port

# sync with retry — the bootloader locks baud on the first clean 0x7F
syncWithRetry = (io) ->
  for attempt in [0...4]
    await io.write Uint8Array.from [0x7F]
    try
      b = (await withTimeout (io.read 1), 250, 'sync')[0]
      return if b is dfu.ACK
    catch e
      null
  throw new Error 'bootloader sync failed — not in bootloader mode?'

# ── crypto (sha256Hex imported from firmwareCatalog) ──
fetchFirmware = (fw) ->
  res = await fetch fw.file
  unless res.ok
    throw new Error "HTTP #{res.status} fetching #{fw.file}"
  new Uint8Array (await res.arrayBuffer())

# ── detection ────────────────────────────────
detect = (port, onLog = (->)) ->
  io = await openPort port
  try
    await syncWithRetry io
    idr = await withTimeout (dfu.getDeviceId io), 2000, 'getid'
    throw new Error idr.error unless idr.ok
    chipId = idr.value
    info = dfu.CHIP_IDS[chipId] or
      { target: 'STM32', mcu: "STM32 (0x#{chipId.toString 16})", flash: '?' }

    vr = await withTimeout (dfu.getVersion io), 2000, 'version'
    ver = if vr.ok then vr.value else '?'

    onLog 'INFO', "Bootloader sync OK — chip 0x#{chipId.toString 16} v#{ver}"
    onLog 'INFO', "Detected #{info.mcu} (#{info.flash})"

    {
      name: info.target
      target: info.target
      mcu: info.mcu
      flash: info.flash
      bootloader: 'STM32 USART'
      firmware: 'bootloader'
      uid: "chip 0x#{chipId.toString 16}"
      chipId
    }
  finally
    await io.close()

# ── erase ────────────────────────────────────
eraseRegion = (io, chipId, sizeBytes, fullErase) ->
  if fullErase
    r = await withTimeout (dfu.massErase io), 8000, 'mass erase'
    throw new Error r.error unless r.ok
  else
    pages = dfu.sectorsFor chipId, sizeBytes
    r = await withTimeout (dfu.erasePages io, pages), 8000, 'erase'
    throw new Error r.error unless r.ok

# ── write ────────────────────────────────────
writeImage = (io, image, onProgress) ->
  total = image.length
  offset = 0
  lastPct = -1
  while offset < total
    end = Math.min total, offset + WRITE_CHUNK
    chunk = image.subarray offset, end
    addr = FLASH_BASE + offset
    r = await withTimeout (dfu.writeMemory io, addr, chunk), 3000, 'write'
    throw new Error r.error unless r.ok
    offset = end
    pct = Math.round offset / total * 100
    if pct != lastPct
      onProgress pct
      lastPct = pct

# ── verify (read-back + hash) ────────────────
verifyImage = (io, image, onProgress) ->
  total = image.length
  readBack = new Uint8Array total
  offset = 0
  while offset < total
    end = Math.min total, offset + READ_CHUNK
    addr = FLASH_BASE + offset
    count = end - offset
    r = await withTimeout (dfu.readMemory io, addr, count), 3000, 'verify'
    throw new Error r.error unless r.ok
    readBack.set r.value, offset
    offset = end
    onProgress Math.round offset / total * 100
  digest = await sha256Hex readBack
  return { digest, readBack }

# ── full flash sequence ──────────────────────
run = (actor, fw, options = {}, onLog = (->), port) ->
  { verify = true, fullErase = false, reboot = true } = options
  io = await openPort port
  try
    source = if fw.bytes then 'local drive' else fw.file
    onLog 'FETCH', "Fetching #{fw.name} v#{fw.version} from #{source}…"
    image = if fw.bytes then fw.bytes else await fetchFirmware fw

    if fw.sha256
      digest = await sha256Hex image
      if digest and digest isnt fw.sha256
        throw new Error "image integrity failed: sha256 #{digest.slice 0, 16}…"
      onLog 'VERIFY', "Image sha256 #{fw.sha256.slice 0, 16}… ✓"

    onLog 'SYNC', 'Synchronizing bootloader…'
    await syncWithRetry io

    chipId = (await withTimeout (dfu.getDeviceId io), 2000, 'getid').value

    eraseMsg = if fullErase then 'Full chip erase…' else 'Erasing app region…'
    onLog 'ERASE', eraseMsg
    await eraseRegion io, chipId, image.length, fullErase
    actor.send { type: 'ERASE_DONE' }

    onLog 'WRITE', "Writing #{image.length} bytes…"
    report = (pct) -> actor.send { type: 'WRITE_PROGRESS', progress: pct }
    await writeImage io, image, report
    actor.send { type: 'WRITE_DONE' }

    if verify
      onLog 'VERIFY', 'Reading back and hashing…'
      result = await verifyImage io, image, (pct) ->
        actor.send { type: 'VERIFY_PROGRESS', progress: pct }
      expected = fw.sha256 or (await sha256Hex image)
      if result.digest isnt expected
        throw new Error "verify mismatch: flashed #{result.digest.slice 0, 16}…"
      onLog 'VERIFY', "Flashed sha256 #{result.digest.slice 0, 16}… ✓"
      actor.send { type: 'VERIFY_DONE' }

    onLog 'DONE', "#{fw.name} v#{fw.version} transmigrated."
    if reboot
      onLog 'REBOOT', 'Jumping to application…'
      actor.send { type: 'REBOOT' }
      gr = await withTimeout (dfu.go io, FLASH_BASE), 2000, 'go'
      throw new Error gr.error unless gr.ok
      actor.send { type: 'REBOOT_DONE' }
      onLog 'READY', 'The bird is ready.'
  finally
    await io.close()

reboot = (actor, onLog = (->), port) ->
  io = await openPort port
  try
    onLog 'REBOOT', 'Jumping to application…'
    gr = await withTimeout (dfu.go io, FLASH_BASE), 2000, 'go'
    throw new Error gr.error unless gr.ok
    actor.send { type: 'REBOOT_DONE' }
    onLog 'READY', 'The bird is ready.'
  finally
    await io.close()

export {
  isSupported, requestPort
  openPort, makePortIO
  detect
  run, reboot
  fetchFirmware, sha256Hex
  FLASH_BASE, BAUD
}