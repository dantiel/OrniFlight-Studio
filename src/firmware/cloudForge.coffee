###
# ORNIFLIGHT STUDIO · The Forge — Cloud Firmware Build Client
#
# Talks to the Cloudflare Worker (worker/) that holds the GitHub token
# and drives the cloud-build.yml workflow in the firmware repo. No
# secrets ever live in the browser.
#
# The worker base URL resolves from (highest precedence first):
#   1. ?forge=<url>            runtime override
#   2. VITE_FORGE_API_BASE     baked in at build time
#   3. localStorage            persisted override
#   4. DEFAULT_FORGE_BASE      the production deployment
###

TARGETS = ['TINYFISH', 'OMNIBUSF4', 'SPRACINGF7DUAL', 'BETAFLIGHTF3']
DEFAULT_FORGE_BASE = 'https://orniflight-forge.orniflight-cloud-forge.workers.dev'

stripSlash = (s) -> (s or '').replace /\/$/, ''

readStorage = ->
  try localStorage.getItem 'orniflight-forge-api'
  catch
    null

resolveForgeBase = ->
  query = new URLSearchParams(globalThis.location?.search or '')
  fromQuery = query.get 'forge'
  return stripSlash fromQuery if fromQuery
  fromEnv = import.meta.env?.VITE_FORGE_API_BASE
  return stripSlash fromEnv if fromEnv
  fromStorage = stripSlash readStorage()
  return fromStorage if fromStorage
  DEFAULT_FORGE_BASE

setForgeBase = (url) ->
  try localStorage.setItem 'orniflight-forge-api', stripSlash url
  catch
    null

FORGE_API_BASE = resolveForgeBase()
configured = FORGE_API_BASE isnt ''

# fetch JSON, normalizing error bodies into thrown Error messages.
apiFetch = (path, init = {}) ->
  resp = await fetch "#{FORGE_API_BASE}#{path}", init
  text = await resp.text()
  data = null
  try data = JSON.parse text catch
  if not resp.ok
    msg = data?.error or data?.message or text or "HTTP #{resp.status}"
    throw new Error msg
  data

# fetch raw bytes for the download endpoint.
apiDownload = (path) ->
  resp = await fetch "#{FORGE_API_BASE}#{path}"
  unless resp.ok
    text = await resp.text()
    data = null
    try data = JSON.parse text catch
    throw new Error data?.error or data?.message or text or "HTTP #{resp.status}"
  new Uint8Array await resp.arrayBuffer()

health = ->
  unless configured
    return { ok: false, configured: false, reason: 'unconfigured', targets: TARGETS }
  try
    data = await apiFetch '/api/health'
    { ok: true, configured: true, data }
  catch e
    { ok: false, configured: true, reason: e.message, targets: TARGETS }

startBuild = (target, versionTag = '', options = []) ->
  apiFetch '/api/build',
    method: 'POST'
    headers: { 'Content-Type': 'application/json' }
    body: JSON.stringify { target, version_tag: versionTag, options }

buildStatus = (runId) -> apiFetch "/api/build/#{runId}"

downloadBuild = (runId, format = 'bin') ->
  apiDownload "/api/build/#{runId}/download?format=#{format}"

buildManifest = (runId) -> apiFetch "/api/build/#{runId}/manifest"

buildHistory = -> apiFetch '/api/builds'

cancelBuild = (runId) ->
  apiFetch "/api/build/#{runId}/cancel", method: 'POST'

# A bytes-backed firmware descriptor for a freshly forged image, shaped to
# flow through the existing flash pipeline (same contract as localFirmware).
cloudFirmware = (manifest, bytes) ->
  bin = manifest?.bin or {}
  {
    id: 'cloud'
    name: manifest?.target or 'ORNI-F4'
    target: manifest?.target or 'ORNI-F4'
    version: manifest?.version or '0.0.0'
    channel: 'cloud'
    file: ''
    size: bytes.length
    sha256: bin.sha256 or ''
    date: manifest?.built_at?.slice(0, 10) or ''
    notes: "Cloud build · #{manifest?.head_sha?.slice(0, 7) or 'unknown'}"
    bytes
  }

export {
  TARGETS, FORGE_API_BASE, DEFAULT_FORGE_BASE, configured
  resolveForgeBase, setForgeBase
  health, startBuild, buildStatus, downloadBuild, buildManifest
  buildHistory, cancelBuild, cloudFirmware
}