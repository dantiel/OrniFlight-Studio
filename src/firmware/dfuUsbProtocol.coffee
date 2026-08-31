###
# ORNIFLIGHT STUDIO — USB DFU 1.1 Protocol (pure WebUSB)
#
# Implements the USB-DFU class protocol for STM32 and compatible MCUs.
# This is the wire layer — no DOM, no WebUSB handles, just protocol.
# Used by webUsbTransport.coffee
#
# Spec: USB Device Firmware Upgrade Specification, Revision 1.1
# AN3156: USB DFU protocol used in the STM32 bootloader
###

# ── DFU class constants ─────────────────────────────────────
DFU_CLASS    = 0xFE
DFU_SUBCLASS = 0x01
DFU_PROTOCOL = 0x02   # Runtime protocol (switches to DFU mode)

# ── DFU requests (bmRequestType = 0x21 class, interface = 0) ───
DFU_DETACH    = 0
DFU_DNLOAD    = 1
DFU_UPLOAD    = 2
DFU_GETSTATUS = 3
DFU_CLRSTATUS = 4
DFU_GETSTATE  = 5
DFU_ABORT     = 6

# ── DFU states ──────────────────────────────────────────────
STATE_APPIDLE        = 0
STATE_APPDETACH     = 1
STATE_DFU_IDLE      = 2
STATE_DFU_DOWNLOAD  = 3
STATE_DFU_MANIFEST  = 4
STATE_DFU_MANIFEST_WAIT_RESET = 5
STATE_DFU_UPLOAD_IDLE = 6
STATE_DFU_ERROR     = 7

# ── DFU status codes ─────────────────────────────────────────
STATUS_OK              = 0x00
STATUS_ERR_TARGET      = 0x01
STATUS_ERR_FILE        = 0x02
STATUS_ERR_WRITE       = 0x03
STATUS_ERR_ERASE       = 0x04
STATUS_ERR_CHECK_ERASED = 0x05
STATUS_ERR_PROG        = 0x06
STATUS_ERR_VERIFY      = 0x07
STATUS_ERR_ADDRESS     = 0x08
STATUS_ERR_NOTDONE     = 0x09
STATUS_ERR_FIRMWARE    = 0x0A
STATUS_ERR_VENDOR      = 0x0B
STATUS_ERR_USBR        = 0x0C
STATUS_ERR_POR         = 0x0D
STATUS_ERR_UNKNOWN     = 0x0E
STATUS_ERR_STALLEDPKT  = 0x0F

# ── STM32-specific commands (AN3156) ─────────────────────────
# DFU DNLOAD payloads for STM32:
#   [0x41 | addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF, (addr >> 24) & 0xFF]
#   0x41 = SET_ADDRESS_POINTER
#   0x43 = ERASE_PAGE, payload = page + 0x43 || 0xFFFF for mass erase
#   0x21 = WRITE_MEMORY (followed by data)

CMD_SET_ADDR  = 0x21
CMD_ERASE     = 0x43
CMD_MASS_ERASE = 0xFFFF

# ── Chip ID map (subset) ───────────────────────────────────────
CHIP_IDS =
  # F3 family
  0x422: { target: 'STM32F302', mcu: 'STM32F302xB/C', flash: '128 KB' }
  0x439: { target: 'STM32F303', mcu: 'STM32F303xB/C', flash: '256 KB' }
  0x438: { target: 'STM32F303', mcu: 'STM32F303xD/E', flash: '512 KB' }
  0x440: { target: 'STM32F303', mcu: 'STM32F303xC',   flash: '256 KB' }
  # F4 family (shared with USART bootloader)
  0x413: { target: 'STM32F405', mcu: 'STM32F405xG',   flash: '1 MB' }
  0x419: { target: 'STM32F427', mcu: 'STM32F427xG',   flash: '1 MB' }
  0x431: { target: 'STM32F411', mcu: 'STM32F411xC/E', flash: '512 KB' }
  # F7 family
  0x449: { target: 'STM32F745', mcu: 'STM32F745xG',   flash: '1 MB' }
  0x451: { target: 'STM32F76x', mcu: 'STM32F767xG',   flash: '1 MB' }

# ── Sector maps (page sizes, start addresses) ─────────────────
# F303CC: 256 KB, 2 KB pages = 128 pages (0-127)
# F405RG: 1 MB,  128 KB sectors, then 4× 16 KB, then 1× 64 KB, rest 128 KB
SECTORS =
  'STM32F302': { pageSize: 2048, pages: 64,  size: 128 * 1024 }
  'STM32F303': { pageSize: 2048, pages: 256, size: 512 * 1024 }
  'STM32F405': { pageSize: 16384, pages: 12, size: 1 * 1024 * 1024 }
  'STM32F427': { pageSize: 16384, pages: 12, size: 1 * 1024 * 1024 }
  'STM32F76x': { pageSize: 32768, pages: 32, size: 1 * 1024 * 1024 }

FLASH_BASE = 0x08000000

# ── Protocol helpers ────────────────────────────────────────
makeResult = (ok, value, error) -> { ok, value, error }

# ── Low-level DFU operations ──────────────────────────────────
# All device.controlTransferIn/Out are async, take a WebUSB device
# We assume interface 0 is the DFU interface

# GETSTATUS: returns { state, status, pollTimeout }
getStatus = (device, iface = 0) ->
  result = await device.controlTransferIn
    requestType: 'class'
    recipient: 'interface'
    request: DFU_GETSTATUS
    value: 0
    index: iface
    length: 6
  unless result.status is 'ok' and result.data?
    return makeResult false, null, 'GETSTATUS failed'
  buf = result.data
  status = buf[0]
  pollTimeout = (buf[1] | (buf[2] << 8) | (buf[3] << 16))
  state = buf[4]
  makeResult true, { status, state, pollTimeout }

# Clear status (CLRSTATUS)
clearStatus = (device, iface = 0) ->
  result = await device.controlTransferOut
    requestType: 'class'
    recipient: 'interface'
    request: DFU_CLRSTATUS
    value: 0
    index: iface
  makeResult true, null, null

# Get state (GETSTATE)
getState = (device, iface = 0) ->
  result = await device.controlTransferIn
    requestType: 'class'
    recipient: 'interface'
    request: DFU_GETSTATE
    value: 0
    index: iface
    length: 1
  unless result.status is 'ok' and result.data?
    return makeResult false, null, 'GETSTATE failed'
  makeResult true, result.data[0]

# Wait for state to be dfuIDLE or timeout
waitIdle = (device, iface = 0, timeout = 30000) ->
  start = Date.now()
  while true
    sr = await getStatus device, iface
    return sr unless sr.ok
    { state, pollTimeout } = sr.value
    await new Promise (r) -> setTimeout r, Math.min pollTimeout, 100
    if state is STATE_DFU_IDLE
      return makeResult true, 'idle', null
    if state is STATE_DFU_ERROR
      await clearStatus device, iface
      return makeResult false, null, 'DFU error state'
    if Date.now() - start > timeout
      return makeResult false, null, 'DFU waitIdle timeout'

# ── STM32 DFU commands ───────────────────────────────────────

# Set address pointer (0x21)
setAddress = (device, addr, iface = 0) ->
  # DNLOAD with wBlockNum = 0, data = [0x21, addr...
  payload = new Uint8Array [CMD_SET_ADDR, addr & 0xFF, (addr >> 8) & 0xFF, (addr >> 16) & 0xFF, (addr >> 24) & 0xFF]
  result = await device.controlTransferOut
    requestType: 'class'
    recipient: 'interface'
    request: DFU_DNLOAD
    value: 0
    index: iface
    length: payload.length
  , payload
  unless result.status is 'ok'
    return makeResult false, null, 'setAddress DNLOAD failed'
  # Wait for completion (GETSTATUS throws pollTimeout)
  sr = await getStatus device, iface
  return sr unless sr.ok
  await new Promise (r) -> setTimeout r, sr.value.pollTimeout
  makeResult true, null, null

# Erase page (0x43, page number) or mass erase (0xFFFF)
erasePage = (device, page, iface = 0) ->
  # DNLOAD with wBlockNum = 0, data = [0x43, page & 0xFF, (page >> 8) & 0xFF, 0, 0]
  payload = new Uint8Array [CMD_ERASE, page & 0xFF, (page >> 8) & 0xFF, 0, 0]
  result = await device.controlTransferOut
    requestType: 'class'
    recipient: 'interface'
    request: DFU_DNLOAD
    value: 0
    index: iface
    length: payload.length
  , payload
  unless result.status is 'ok'
    return makeResult false, null, 'erasePage DNLOAD failed'
  sr = await getStatus device, iface
  return sr unless sr.ok
  await new Promise (r) -> setTimeout r, sr.value.pollTimeout
  makeResult true, null, null

massErase = (device, iface = 0) ->
  # DNLOAD with wBlockNum = 0, data = [0x43, 0xFF, 0xFF, 0, 0]
  payload = new Uint8Array [CMD_ERASE, 0xFF, 0xFF, 0, 0]
  result = await device.controlTransferOut
    requestType: 'class'
    recipient: 'interface'
    request: DFU_DNLOAD
    value: 0
    index: iface
    length: payload.length
  , payload
  unless result.status is 'ok'
    return makeResult false, null, 'massErase DNLOAD failed'
  sr = await getStatus device, iface
  return sr unless sr.ok
  await new Promise (r) -> setTimeout r, sr.value.pollTimeout
  makeResult true, null, null

# Write chunk to address (DNLOAD with blockNum > 1)
# Block numbering: wBlockNum = 2 + (address - FLASH_BASE) / transferSize
# For simplicity, we use address directly: wValue = (address - FLASH_BASE) / 2 + 2
writeChunk = (device, addr, data, iface = 0) ->
  # Calculate block number: 2 + (addr - FLASH_BASE) / maxPacketSize
  # Normally, we'd use the flash address directly
  block = 2 + (addr - FLASH_BASE) // 2
  result = await device.controlTransferOut
    requestType: 'class'
    recipient: 'interface'
    request: DFU_DNLOAD
    value: block
    index: iface
    length: data.length
  , new Uint8Array data
  unless result.status is 'ok'
    return makeResult false, null, 'writeChunk DNLOAD failed'
  sr = await getStatus device, iface
  return sr unless sr.ok
  await new Promise (r) -> setTimeout r, sr.value.pollTimeout
  makeResult true, null, null

# Read chunk (UPLOAD, but STM32 DFU typically doesn't support UPLOAD in bootloader)
# We'll skip readback for now and rely on checksum verification

# ── High-level operations ───────────────────────────────────────

# Erase flash region (pages or full)
eraseRegion = (device, chipId, totalBytes, fullErase = false, onProgress = (->)) ->
  info = CHIP_IDS[chipId] or { target: 'STM32' }
  sectors = SECTORS[info.target] or { pageSize: 2048, pages: 256 }
  pages = Math.ceil totalBytes / sectors.pageSize
  if fullErase
    await massErase device
    onProgress 100
  else
    for p in [0...pages]
      await erasePage device, p
      onProgress Math.round (p + 1) / pages * 100

# Write entire image
writeImage = (device, image, onProgress = (->)) ->
  # We must send address first, then data in chunks
  total = image.length
  offset = 0
  chunkSize = 2048  # Safe for DFU
  lastPct = -1
  while offset < total
    addr = FLASH_BASE + offset
    # Set address every chunk (conservative)
    if offset is 0 or addr % 0x1000 is 0
      await setAddress device, addr
    end = Math.min total, offset + chunkSize
    chunk = image.subarray offset, end
    r = await writeChunk device, addr, chunk
    return r unless r.ok
    offset = end
    pct = Math.round offset / total * 100
    if pct != lastPct
      onProgress pct
      lastPct = pct

export {
  DFU_CLASS, DFU_SUBCLASS, DFU_PROTOCOL
  CHIP_IDS, SECTORS, FLASH_BASE
  getStatus, clearStatus, getState, waitIdle
  setAddress, erasePage, massErase, writeChunk
  eraseRegion, writeImage
}
