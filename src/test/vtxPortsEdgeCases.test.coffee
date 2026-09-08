import { describe, it, expect } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient from '../protocol/mspClient.coffee'
import OrniFlightSession from '../protocol/orniFlightSession.coffee'
import { MockMspTransport, scriptedResponder } from './mockMspTransport.coffee'
import {
  decodeVtxConfig, encodeVtxConfig
  decodeSerialConfig, encodeSerialConfig
} from '../protocol/mspDecoders.coffee'
import {
  SERIAL_CONFIG_BYTES, FUNCTION_MSP, FUNCTION_GPS
  FUNCTION_RX_SERIAL, FUNCTION_VTX_SMARTAUDIO, FUNCTION_BLACKBOX
  BAUD_RATES, clampBaud, toggleFunction, functionLabels, maskConflicts
  portLabel, baudLabel
} from '../lib/serialCatalog.coffee'
import {
  VTX_BAND_COUNT, VTX_CHANNEL_COUNT, VTX_BANDCHAN_CHKVAL
  packBandChannel, unpackBandChannel, lookupBandChannel
  clampFrequency, vtxValueFor, frequencyFor
  bandLabel, bandLetter, channelLabel
} from '../lib/vtxCatalog.coffee'

u16 = (value) -> [value & 0xff, value >> 8 & 0xff]

# ── Band/channel packing boundaries (the 63-value wire space) ──────
describe 'VTX band/channel boundaries', ->
  it 'packs the four corners of the 5×8 table', ->
    expect(packBandChannel 1, 1).toBe 0
    expect(packBandChannel 1, 8).toBe 7
    expect(packBandChannel 5, 1).toBe 32
    expect(packBandChannel 5, 8).toBe 39

  it 'rejects out-of-range and fractional indices', ->
    expect(packBandChannel 0, 1).toBe null
    expect(packBandChannel 6, 1).toBe null
    expect(packBandChannel 1, 0).toBe null
    expect(packBandChannel 1, 9).toBe null
    expect(packBandChannel 4.5, 1).toBe null
    expect(packBandChannel 4, 1.5).toBe null

  it 'unpacks corners and degrades outside the table', ->
    expect(unpackBandChannel 0).toEqual { band: 1, channel: 1 }
    expect(unpackBandChannel 7).toEqual { band: 1, channel: 8 }
    expect(unpackBandChannel 32).toEqual { band: 5, channel: 1 }
    expect(unpackBandChannel 39).toEqual { band: 5, channel: 8 }
    # 40..63 decompose into non-existent bands 6..8 — rejected.
    expect(unpackBandChannel 63).toBe null
    expect(unpackBandChannel 64).toBe null
    expect(unpackBandChannel -1).toBe null

  it 'truncates fractional and numeric-string values', ->
    expect(unpackBandChannel 24.9).toEqual { band: 4, channel: 1 }
    expect(unpackBandChannel '39').toEqual { band: 5, channel: 8 }
    expect(unpackBandChannel NaN).toBe null

# ── Frequency window (5600–5950 MHz) ───────────────────────────────
describe 'VTX frequency window boundaries', ->
  it 'clamps into the RTC6705 window and rounds', ->
    expect(clampFrequency 5600).toBe 5600
    expect(clampFrequency 5950).toBe 5950
    expect(clampFrequency 5599).toBe 5600
    expect(clampFrequency 5951).toBe 5950
    expect(clampFrequency 5949.6).toBe 5950
    expect(clampFrequency '5801').toBe 5801

  it 'collapses non-finite and null inputs to the floor', ->
    expect(clampFrequency NaN).toBe 5600
    expect(clampFrequency Infinity).toBe 5600
    expect(clampFrequency -Infinity).toBe 5600
    expect(clampFrequency null).toBe 5600
    expect(clampFrequency undefined).toBe 5600

  it 'looks up table frequencies losslessly, rejects the rest', ->
    expect(lookupBandChannel 5865).toEqual { band: 1, channel: 1 }
    expect(lookupBandChannel 5917).toEqual { band: 5, channel: 8 }
    expect(lookupBandChannel 5801).toBe null
    expect(lookupBandChannel NaN).toBe null
    expect(lookupBandChannel Infinity).toBe null

  it 'derives the wire value from a config document', ->
    expect(vtxValueFor { band: 5, channel: 8 }).toBe 39
    expect(vtxValueFor { band: 1, channel: 1 }).toBe 0
    expect(vtxValueFor { band: 0, channel: 0, freq: 5801 }).toBe 5801
    expect(vtxValueFor { band: 0, channel: 0, freq: 9999 }).toBe 5950
    expect(vtxValueFor { band: 0, channel: 0, freq: 100 }).toBe 5600
    expect(vtxValueFor { band: 0, channel: 0, freq: NaN }).toBe 5600
    expect(vtxValueFor {}).toBe 5600
    # invalid band falls through to the custom-frequency path
    expect(vtxValueFor { band: 6, channel: 1, freq: 5800 }).toBe 5800

  it 'labels out-of-range bands, letters and channels safely', ->
    expect(bandLabel -1).toBe 'CUSTOM'
    expect(bandLabel 0).toBe 'CUSTOM'
    expect(bandLabel 5).toBe 'RACEBAND'
    expect(bandLabel 6).toBe 'CUSTOM'
    expect(bandLetter 0).toBe '-'
    expect(bandLetter 5).toBe 'R'
    expect(bandLetter 99).toBe '-'
    expect(channelLabel 1).toBe '1'
    expect(channelLabel 8).toBe '8'
    expect(channelLabel 0).toBe ''
    expect(channelLabel 9).toBe ''

# ── Serial baud index clamping (0..15) ─────────────────────────────
describe 'serial baud boundaries', ->
  it 'clamps baud indices into the 16-entry table', ->
    expect(clampBaud -1).toBe 0
    expect(clampBaud 0).toBe 0
    expect(clampBaud 15).toBe 15
    expect(clampBaud 16).toBe 15
    expect(clampBaud 999).toBe 15
    expect(clampBaud '5').toBe 5

  it 'resets non-finite and missing inputs to AUTO', ->
    expect(clampBaud NaN).toBe 0
    expect(clampBaud undefined).toBe 0
    expect(clampBaud Infinity).toBe 0
    expect(clampBaud null).toBe 0

  it 'labels unknown identifiers and baud indices', ->
    expect(portLabel 0).toBe 'UART1'
    expect(portLabel 31).toBe 'SOFTSERIAL2'
    expect(portLabel 99).toBe 'PORT 99'
    expect(baudLabel 5).toBe '115200'
    expect(baudLabel 99).toBe 'AUTO'

# --- Function arbitration boundaries ---
describe 'serial function arbitration boundaries', ->
  it 'clears conflicts when enabling, keeps unset bits when disabling', ->
    expect(toggleFunction FUNCTION_MSP, FUNCTION_GPS, true).toBe FUNCTION_GPS
    expect(toggleFunction FUNCTION_GPS, FUNCTION_VTX_SMARTAUDIO, true)
      .toBe FUNCTION_VTX_SMARTAUDIO
    expect(toggleFunction FUNCTION_MSP, FUNCTION_RX_SERIAL, false)
      .toBe FUNCTION_MSP

  it 'ignores functions outside the curated set', ->
    expect(toggleFunction FUNCTION_MSP, 512, true).toBe FUNCTION_MSP

  it 'labels and derives conflicts from masks', ->
    expect(functionLabels 0).toEqual []
    expect(functionLabels undefined).toEqual []
    expect(functionLabels FUNCTION_MSP).toEqual ['MSP']
    expect(maskConflicts 0).toBe 0
    expect(maskConflicts undefined).toBe 0
    expect(maskConflicts FUNCTION_MSP)
      .toBe FUNCTION_GPS | FUNCTION_VTX_SMARTAUDIO | 8192

# ── Codec truncation and clamping ──────────────────────────────────
describe 'VTX/serial codec edge cases', ->
  it 'decodes partial VTX payloads without throwing', ->
    expect(decodeVtxConfig new Uint8Array [])
      .toEqual
        vtxType: 255, band: 0, channel: 0, power: 1, pitmode: 0
        freq: 0, deviceIsReady: 0, lowPowerDisarm: 0
    expect(decodeVtxConfig(new Uint8Array [1]).vtxType).toBe 1
    partial = decodeVtxConfig new Uint8Array [1, 4, 1, 2, 0]
    expect(partial.band).toBe 4
    expect(partial.channel).toBe 1
    expect(partial.power).toBe 2
    expect(partial.freq).toBe 0

  it 'clamps VTX option bytes into u8 range', ->
    payload = encodeVtxConfig {
      band: 4, channel: 1, power: 300, pitmode: 'x', lowPowerDisarm: NaN
    }
    expect(Array.from payload).toEqual [24, 0, 255, 0, 0]

  it 'decodes serial streams and drops trailing partial records', ->
    expect(decodeSerialConfig new Uint8Array []).toEqual []
    payload = new Uint8Array [
      0, u16(FUNCTION_MSP)..., 5, 4, 0, 5
      20, u16(FUNCTION_RX_SERIAL)..., 5, 4, 0
    ]
    ports = decodeSerialConfig payload
    expect(ports).toHaveLength 1
    expect(ports[0].identifier).toBe 0

  it 'clamps serial record fields into their wire widths', ->
    port = encodeSerialConfig {
      identifier: 300, functionMask: 0x1FFFF
      mspBaud: -5, gpsBaud: 300, telemetryBaud: NaN, blackboxBaud: undefined
    }
    expect(Array.from port).toEqual [
      255, u16(0xFFFF)..., 0, 255, 0, 0
    ]

# ── Session error scenarios (fail gracefully, never silently corrupt) ──
openSession = (responder) ->
  transport = new MockMspTransport { autoRespond: true, responder }
  client = new MspClient transport, { timeoutMs: 500 }
  await client.open()
  { transport, session: new OrniFlightSession(client) }

describe 'session VTX/serial error scenarios', ->
  it 'rejects empty and non-array serial documents', ->
    { session } = await openSession (-> null)
    await expect(session.writeSerialConfig [])
      .rejects.toThrow 'Serial port configuration missing'
    await expect(session.writeSerialConfig null)
      .rejects.toThrow 'Serial port configuration missing'

  it 'rejects a VTX write whose read-back disagrees', ->
    # Firmware reports band 1 channel 1 no matter what was written.
    stale = scriptedResponder {
      [MSP_CODES.VTX_CONFIG]: [1, 1, 1, 1, 0, u16(5865)..., 1, 0]
      [MSP_CODES.SET_VTX_CONFIG]: []
      [MSP_CODES.EEPROM_WRITE]: []
    }
    { session } = await openSession stale
    await expect(session.writeVtxConfig { band: 4, channel: 1, power: 1 })
      .rejects.toThrow 'VTX configuration read-back mismatch'

  it 'rejects a serial write when the firmware drops a record', ->
    # Read-back serves only UART1 — any UART2 write mismatches.
    dropping = scriptedResponder {
      [MSP_CODES.CF_SERIAL_CONFIG]: [0, u16(FUNCTION_MSP)..., 5, 4, 0, 5]
      [MSP_CODES.SET_CF_SERIAL_CONFIG]: []
      [MSP_CODES.EEPROM_WRITE]: []
    }
    { session } = await openSession dropping
    await expect(
      session.writeSerialConfig [
        {
          identifier: 0, functionMask: FUNCTION_MSP
          mspBaud: 5, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
        }
        {
          identifier: 1, functionMask: FUNCTION_GPS
          mspBaud: 0, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
        }
      ]
    ).rejects.toThrow 'Serial configuration read-back failed at identifier 1'
