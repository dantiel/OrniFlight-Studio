import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import {
  TARGETS, configured, DEFAULT_FORGE_BASE, resolveForgeBase, cloudFirmware
} from '../firmware/cloudForge.coffee'
import useCloudForgeStore from '../stores/useCloudForgeStore.coffee'

describe 'cloudForge', ->
  it 'exports a curated target list', ->
    expect(TARGETS).toContain 'TINYFISH'
    expect(TARGETS).toContain 'SPRACINGF7DUAL'

  it 'defaults to the production forge deployment', ->
    expect(configured).toBe true
    expect(resolveForgeBase()).toBe DEFAULT_FORGE_BASE
    expect(DEFAULT_FORGE_BASE).toMatch /^https:\/\/orniflight-forge\./

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