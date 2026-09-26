import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  TARGETS, configured, DEFAULT_FORGE_BASE, resolveForgeBase, cloudFirmware
  startBuild as forgeStartBuild
} from '../firmware/cloudForge.coffee'
import { FORGE_FEATURE_IDS, stripDefines } from '../firmware/forgeFeatures.coffee'
import useCloudForgeStore from '../stores/useCloudForgeStore.coffee'

describe 'cloudForge', ->
  it 'exports a curated target list', ->
    expect(TARGETS).toContain 'TINYFISH'
    expect(TARGETS).toContain 'SPRACINGF7DUAL'

  it 'defaults to the production forge deployment', ->
    expect(configured).toBe true
    expect(resolveForgeBase()).toBe DEFAULT_FORGE_BASE
    expect(DEFAULT_FORGE_BASE).toMatch /^https:\/\/orniflight-forge\./

  it 'mirrors configured in the store initial state', ->
    # A bare `configured` key in a CoffeeScript object literal compiles to a
    # no-op statement, silently dropping the field from the store. The store
    # must carry the module-level flag so checkHealth() takes the network path.
    expect(useCloudForgeStore.getState().configured).toBe true

  it 'builds a bytes-backed descriptor from a manifest', ->
    bytes = new Uint8Array [0x01, 0x02, 0x03]
    manifest =
      target: 'TINYFISH'
      version: '4.0.7'
      head_sha: 'abcdef1234567890'
      built_at: '2026-09-26T00:00:00Z'
      bin: { sha256: 'deadbeef', size: 3 }
    fw = cloudFirmware manifest, bytes
    expect(fw.id).toBe 'cloud'
    expect(fw.channel).toBe 'cloud'
    expect(fw.target).toBe 'TINYFISH'
    expect(fw.version).toBe '4.0.7'
    expect(fw.size).toBe 3
    expect(fw.sha256).toBe 'deadbeef'
    expect(fw.bytes).toBe bytes
    expect(fw.notes).toContain 'abcdef1'

  it 'posts the stripped build defines as options', ->
    payload = { run_id: 7, html_url: 'u', status: 'queued' }
    fetchSpy = vi.fn ->
      Promise.resolve {
        ok: true
        text: -> Promise.resolve JSON.stringify payload
      }
    vi.stubGlobal 'fetch', fetchSpy
    data = await forgeStartBuild 'TINYFISH', 'rc1', ['WITHOUT_OSD']
    expect(data.run_id).toBe 7
    call = fetchSpy.mock.calls[0]
    expect(call[0]).toMatch /\/api\/build$/
    body = JSON.parse call[1].body
    expect(body).toEqual {
      target: 'TINYFISH'
      version_tag: 'rc1'
      options: ['WITHOUT_OSD']
    }

describe 'useCloudForgeStore', ->
  beforeEach ->
    useCloudForgeStore.setState
      online: null
      configured: false
      current: null
      built: null
      error: null
      history: []
      building: false

  afterEach ->
    useCloudForgeStore.getState().stopPolling()
    vi.unstubAllGlobals()

  it 'resolves unconfigured health synchronously (no network)', ->
    fetchSpy = vi.fn()
    vi.stubGlobal 'fetch', fetchSpy
    result = useCloudForgeStore.getState().checkHealth()
    # Unconfigured path resolves without touching the network.
    expect(fetchSpy).not.toHaveBeenCalled()
    expect(useCloudForgeStore.getState().online).toBe false
    expect(useCloudForgeStore.getState().configured).toBe false
    expect(result).toBeDefined()

  it 'defaults to every feature included and toggles them', ->
    st = useCloudForgeStore.getState()
    expect(st.features).toEqual FORGE_FEATURE_IDS
    st.toggleFeature 'osd'
    expect(useCloudForgeStore.getState().features).not.toContain 'osd'
    st.toggleFeature 'osd'
    next = useCloudForgeStore.getState().features
    expect(next).toContain 'osd'
    expect(next.length).toBe FORGE_FEATURE_IDS.length

  it 'forwards stripped defines when dispatching a build', ->
    useCloudForgeStore.setState { configured: true, features: ['osd'] }
    fetchSpy = vi.fn (url) ->
      body =
        if url.match /\/api\/build\/\d+$/
          { run_id: 1, ready: true, conclusion: 'success', status: 'completed' }
        else
          { run_id: 1, html_url: 'u', status: 'queued' }
      Promise.resolve {
        ok: true
        text: -> Promise.resolve JSON.stringify body
      }
    vi.stubGlobal 'fetch', fetchSpy
    await useCloudForgeStore.getState().startBuild 'TINYFISH', ''
    body = JSON.parse fetchSpy.mock.calls[0][1].body
    expect(body.options).toEqual stripDefines ['osd']
    expect(body.options).toContain 'WITHOUT_BLACKBOX'
    useCloudForgeStore.getState().stopPolling()
    useCloudForgeStore.setState { features: FORGE_FEATURE_IDS }