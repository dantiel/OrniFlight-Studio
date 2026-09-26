###
# ORNIFLIGHT STUDIO · The Forge — Cloud Build Store (Zustand)
#
# UI state for the cloud firmware build panel: worker readiness, build
# history, the active build run (dispatch → poll → ready) and the forged
# image descriptor handed to the flash pipeline.
###
import { create } from 'zustand'
import {
  configured, TARGETS
  health, startBuild, buildStatus, downloadBuild, buildManifest
  buildHistory, cancelBuild, cloudFirmware
} from '../firmware/cloudForge.coffee'
import useFirmwareStore from './useFirmwareStore.coffee'

POLL_INTERVAL = 4000
POLL_FIRST = 1200

useCloudForgeStore = create (set, get) ->
  online: null            # null = unknown | true | false
  configured: configured  # worker base URL present?
  targets: TARGETS
  checking: false
  history: []
  loadingHistory: false
  current: null          # active run descriptor (normalized)
  building: false
  built: null            # forged firmware descriptor (bytes-backed)
  loading: false
  error: null
  timer: null

  checkHealth: ->
    unless get().configured
      set { checking: false, online: false, configured: false }
      return { ok: false, configured: false, reason: 'unconfigured' }
    set { checking: true }
    h = await health()
    next = { checking: false, online: h.ok, configured: h.configured }
    if h.ok and h.data?.targets?.length
      next.targets = h.data.targets
    set next
    if h.ok then get().loadHistory()
    h
  loadHistory: ->
    return unless get().configured
    set { loadingHistory: true }
    try
      data = await buildHistory()
      set { history: data.builds or [], loadingHistory: false }
    catch e
      set { loadingHistory: false, error: e.message }

  startBuild: (target, versionTag = '') ->
    set { building: true, error: null, current: null, built: null }
    try
      data = await startBuild target, versionTag
      get().startPolling data.run_id
      set { current: { runId: data.run_id, htmlUrl: data.html_url, status: data.status } }
    catch e
      set { building: false, error: e.message }

  startPolling: (runId) ->
    get().stopPolling()
    tick = ->
      { current } = get()
      return unless current?.runId is runId
      try
        status = await buildStatus runId
        next = {
          runId: status.run_id ? runId
          htmlUrl: status.html_url ? current.htmlUrl
          status: status.status
          conclusion: status.conclusion
          ready: status.ready
          artifact: status.artifact
          manifest: status.manifest
          error: status.error
        }
        if status.ready
          set { current: next, building: false }
          if status.conclusion isnt 'success' and not next.error
            set { error: "Build #{status.conclusion or 'failed'}." }
        else
          set { current: next, timer: setTimeout(tick, POLL_INTERVAL) }
      catch e
        set { building: false, error: e.message }
    set { timer: setTimeout(tick, POLL_FIRST) }

  stopPolling: ->
    if get().timer then clearTimeout get().timer
    set { timer: null }

  loadBuild: (runId) ->
    set { loading: true, error: null }
    try
      manifest = await buildManifest(runId).catch -> null
      bytes = await downloadBuild runId, 'bin'
      fw = cloudFirmware manifest, bytes
      set { built: fw, loading: false }
      useFirmwareStore.getState().setCloudImage fw
      fw
    catch e
      set { loading: false, error: e.message }
      null

  cancel: (runId) ->
    try
      await cancelBuild runId
      get().stopPolling()
      set { building: false }
      set { current: { ...get().current, status: 'cancelled', ready: true } }
    catch e
      set { error: e.message }

  reset: ->
    get().stopPolling()
    set { current: null, built: null, error: null, building: false, loading: false }

export default useCloudForgeStore