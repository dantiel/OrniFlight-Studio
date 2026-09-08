import { describe, it, expect } from 'vitest'
import {
  VTX_BANDS, VTX_BAND_COUNT, VTX_CHANNEL_COUNT, VTX_BANDCHAN_CHKVAL
  VTX_FREQ_MIN, VTX_FREQ_MAX, VTX_MAX_FREQUENCY_MHZ, VTX_DEFAULT_POWER
  DEFAULT_VTX_CONFIG, BAND_LETTERS, VTX_TYPE_LABELS, VTX_POWER_LEVELS
  bandLabel, bandLetter, channelLabel, frequencyFor
  packBandChannel, unpackBandChannel, lookupBandChannel
  clampFrequency, vtxValueFor
} from '../lib/vtxCatalog.coffee'

describe 'vtxCatalog codec', ->
  it 'mirrors the firmware vtx58frequencyTable exactly', ->
    expect(VTX_BANDS.length).toBe VTX_BAND_COUNT
    expect(VTX_BANDS[0].frequencies).toEqual [
      5865, 5845, 5825, 5805, 5785, 5765, 5745, 5725
    ]
    expect(VTX_BANDS[1].frequencies).toEqual [
      5733, 5752, 5771, 5790, 5809, 5828, 5847, 5866
    ]
    expect(VTX_BANDS[2].frequencies).toEqual [
      5705, 5685, 5665, 5645, 5885, 5905, 5925, 5945
    ]
    expect(VTX_BANDS[3].frequencies).toEqual [
      5740, 5760, 5780, 5800, 5820, 5840, 5860, 5880
    ]
    expect(VTX_BANDS[4].frequencies).toEqual [
      5658, 5695, 5732, 5769, 5806, 5843, 5880, 5917
    ]

  it 'exposes the firmware wire constants', ->
    expect(VTX_BANDCHAN_CHKVAL).toBe 63
    expect(VTX_MAX_FREQUENCY_MHZ).toBe 5999
    expect(VTX_FREQ_MIN).toBe 5600
    expect(VTX_FREQ_MAX).toBe 5950
    expect(VTX_DEFAULT_POWER).toBe 1
    expect(BAND_LETTERS).toBe '-ABEFR'

  it 'matches the firmware default config', ->
    expect(DEFAULT_VTX_CONFIG.band).toBe 4
    expect(DEFAULT_VTX_CONFIG.channel).toBe 1
    expect(DEFAULT_VTX_CONFIG.freq).toBe 5740
    expect(DEFAULT_VTX_CONFIG.power).toBe 1
    expect(DEFAULT_VTX_CONFIG.pitmode).toBe 0
    expect(DEFAULT_VTX_CONFIG.lowPowerDisarm).toBe 0
    expect(VTX_TYPE_LABELS[1]).toBe 'RTC6705'
    expect(VTX_TYPE_LABELS[255]).toBe 'Unknown'
    expect(VTX_POWER_LEVELS).toHaveLength 3

  it 'packs band/channel into the wire value and back', ->
    expect(packBandChannel 4, 1).toBe 24
    expect(packBandChannel 1, 1).toBe 0
    expect(packBandChannel 5, 8).toBe 39
    expect(packBandChannel 0, 1).toBe null
    expect(packBandChannel 6, 1).toBe null
    expect(unpackBandChannel 24).toEqual { band: 4, channel: 1 }
    expect(unpackBandChannel 0).toEqual { band: 1, channel: 1 }
    expect(unpackBandChannel 39).toEqual { band: 5, channel: 8 }
    # 40..63 decompose to non-existent bands 6..8 — outside the table.
    expect(unpackBandChannel 63).toBe null
    expect(unpackBandChannel 64).toBe null

  it 'looks up frequencies and channels losslessly', ->
    expect(frequencyFor 4, 1).toBe 5740
    expect(frequencyFor 5, 8).toBe 5917
    expect(frequencyFor 0, 1).toBe null
    expect(frequencyFor 1, 9).toBe null
    expect(lookupBandChannel 5740).toEqual { band: 4, channel: 1 }
    expect(lookupBandChannel 5917).toEqual { band: 5, channel: 8 }
    expect(lookupBandChannel 5801).toBe null

  it 'clamps custom frequencies into the RTC6705 window', ->
    expect(clampFrequency 5801).toBe 5801
    expect(clampFrequency 100).toBe 5600
    expect(clampFrequency 9999).toBe 5950
    expect(clampFrequency NaN).toBe 5600

  it 'derives the u16 wire value from a config document', ->
    expect(vtxValueFor { band: 4, channel: 1, freq: 5740 }).toBe 24
    expect(vtxValueFor { band: 0, channel: 0, freq: 5801 }).toBe 5801
    expect(vtxValueFor { band: 0, channel: 0, freq: 9999 }).toBe 5950
    expect(vtxValueFor { band: 0, channel: 0, freq: 100 }).toBe 5600

  it 'labels bands, channels and letters', ->
    expect(bandLabel 4).toBe 'FATSHARK'
    expect(bandLabel 0).toBe 'CUSTOM'
    expect(bandLabel 9).toBe 'CUSTOM'
    expect(bandLetter 4).toBe 'F'
    expect(bandLetter 0).toBe '-'
    expect(channelLabel 3).toBe '3'
    expect(channelLabel 0).toBe ''