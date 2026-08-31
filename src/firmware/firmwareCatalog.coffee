###
# ORNIFLIGHT STUDIO — Firmware Catalog
#
# Pure discovery + normalization for firmware images. The manifest
# JSON at /public/firmware/manifest.json is the single source of
# truth; parseCatalog turns it into a sorted, normalized list.
###
import { Result } from '../lib/essential.coffee'

normalizeFirmware = (raw = {}) ->
  target = raw.target || 'ORNI-F4'
  version = raw.version || '0.0.0'
  {
    name:    raw.name || target
    target
    version
    mcu:     raw.mcu || 'STM32F405'
    channel: raw.channel || 'stable'
    file:    raw.file || ''
    size:    raw.size || 0
    sha256:  raw.sha256 || ''
    date:    raw.date || ''
    notes:   raw.notes || ''
    id:      "#{target}@#{version}"
  }

versionParts = (v) ->
  (String(v || '').replace(/[^0-9.]/g, '').split('.')).map (n) ->
    parseInt(n || '0', 10)

compareVersions = (a, b) ->
  pa = versionParts a.version
  pb = versionParts b.version
  len = Math.max pa.length, pb.length
  for i in [0...len]
    x = pa[i] ? 0
    y = pb[i] ? 0
    return y - x if x != y
  0

parseCatalog = (json) ->
  raw = if Array.isArray(json) then json else (json?.images || [])
  return Result.err 'Manifest contains no firmware images' unless raw.length
  catalog = raw.map(normalizeFirmware).sort(compareVersions)
  Result.ok catalog

fetchCatalog = (url = '/firmware/manifest.json') ->
  fetch(url)
    .then (res) ->
      if res.ok then res.json() else Promise.reject(new Error("HTTP #{res.status}"))
    .then (json) -> parseCatalog json
    .catch (e) -> Result.err e.message

# ── local image (user-picked .bin from disk) ──
# WebCrypto SHA-256 over raw bytes; null when the runtime lacks crypto.subtle.
sha256Hex = (bytes) ->
  unless globalThis.crypto?.subtle
    return null
  digest = await globalThis.crypto.subtle.digest 'SHA-256', bytes
  Array.from(new Uint8Array digest)
    .map((b) -> b.toString(16).padStart 2, '0')
    .join ''

# A firmware descriptor for an image that came from the local drive,
# not the remote manifest. Carries the raw bytes so transports can flash
# it without a fetch().
localFirmware = (file, bytes, sha256) ->
  {
    id: 'local'
    name: (file.name or 'local.bin').replace(/\.(bin|hex|elf)$/i, '') or 'local'
    target: 'LOCAL'
    version: 'custom'
    channel: 'local'
    file: ''
    size: bytes.length
    sha256: sha256 or ''
    date: ''
    notes: "Local image — #{file.name}"
    bytes
  }

fmtBytes = (n = 0) ->
  if n < 1024
    "#{n} B"
  else if n < 1024 * 1024
    "#{(n / 1024).toFixed(1)} KB"
  else
    "#{(n / (1024 * 1024)).toFixed(1)} MB"

export {
  normalizeFirmware, parseCatalog, fetchCatalog, compareVersions, fmtBytes
  sha256Hex, localFirmware
}