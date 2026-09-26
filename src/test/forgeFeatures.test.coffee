import { describe, it, expect } from 'vitest'
import {
  FORGE_FEATURES, FORGE_FEATURE_IDS, stripDefines
} from '../firmware/forgeFeatures.coffee'

# Worker whitelist for build defines (worker/src/index.js): forced
# uppercase, /^[A-Z0-9_]{2,40}$/, max 32 per build.
DEFINE_RE = /^[A-Z0-9_]{2,40}$/

describe 'forgeFeatures', ->
  it 'catalog is non-empty with unique ids', ->
    expect(FORGE_FEATURES.length).toBeGreaterThan 0
    ids = FORGE_FEATURES.map (f) -> f.id
    expect(new Set(ids).size).toBe ids.length
    expect(FORGE_FEATURE_IDS).toEqual ids

  it 'every define passes the worker whitelist shape', ->
    for f in FORGE_FEATURES
      expect(f.define).toMatch DEFINE_RE
      expect(f.label).toBeTruthy()
      expect(f.blurb).toBeTruthy()

  it 'stripDefines returns nothing when all features are included', ->
    expect(stripDefines FORGE_FEATURE_IDS).toEqual []

  it 'stripDefines emits the opt-out define of every excluded feature', ->
    excluded = FORGE_FEATURE_IDS.filter (id) -> id != 'osd'
    defines = stripDefines excluded
    expect(defines).toEqual ['WITHOUT_OSD']

  it 'stripDefines emits all defines when nothing is included', ->
    defines = stripDefines []
    expect(defines.length).toBe FORGE_FEATURES.length
    for f in FORGE_FEATURES
      expect(defines).toContain f.define
