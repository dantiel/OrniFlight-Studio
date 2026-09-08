import { describe, it, expect } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient from '../protocol/mspClient.coffee'
import OrniFlightSession from '../protocol/orniFlightSession.coffee'
import { MockMspTransport } from './mockMspTransport.coffee'
import {
  decodeVtxConfig, encodeVtxConfig
  decodeSerialConfig, encodeSerialConfig
} from '../protocol/mspDecoders.coffee'
import {
  SERIAL_CONFIG_BYTES, FUNCTION_MSP, FUNCTION_RX_SERIAL
  FUNCTION_VTX_SMARTAUDIO, FUNCTION_GPS
} from '../lib/serialCatalog.coffee'
import {
  frequencyFor, unpackBandChannel
} from '../lib/vtxCatalog.coffee'

u16 = (value) -> [value & 0xff, value >> 8 & 0xff]

describe 'VTX codecs', ->
  it 'decodes the 8-byte MSP 88 document', ->
    payload = new Uint8Array [
      1, 4, 1, 2, 0, u16(5740)..., 1, 0
    ]
    expect(decodeVtxConfig payload).toEqual {
      vtxType: 1, band: 4, channel: 1, power: 2, pitmode: 0
      freq: 5740, deviceIsReady: 1, lowPowerDisarm: 0
    }

  it 'degrades gracefully on short payloads', ->
    config = decodeVtxConfig new Uint8Array [1, 4]
    expect(config.vtxType).toBe 1
    expect(config.band).toBe 4
    expect(config.freq).toBe 0
    expect(config.deviceIsReady).toBe 0

  it 'encodes band/channel as the u16 wire value + 3 option bytes', ->
    payload = encodeVtxConfig {
      band: 4, channel: 1, power: 2, pitmode: 1, lowPowerDisarm: 1
    }
    expect(Array.from payload).toEqual [24, 0, 2, 1, 1]

  it 'encodes custom frequencies with band 0 semantics', ->
    payload = encodeVtxConfig {
      band: 0, channel: 0, freq: 5801, power: 1
      pitmode: 0, lowPowerDisarm: 0
    }
    expect(Array.from payload).toEqual [u16(5801)..., 1, 0, 0]

describe 'serial port codecs', ->
  it 'decodes a stream of 7-byte records', ->
    payload = new Uint8Array [
      0, u16(FUNCTION_MSP)..., 5, 4, 0, 5
      20, u16(FUNCTION_MSP | FUNCTION_VTX_SMARTAUDIO)..., 5, 4, 0, 5
    ]
    ports = decodeSerialConfig payload
    expect(ports).toHaveLength 2
    expect(ports[0]).toEqual {
      identifier: 0, functionMask: FUNCTION_MSP
      mspBaud: 5, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
    }
    expect(ports[1].identifier).toBe 20
    expect(ports[1].functionMask).toBe FUNCTION_MSP | FUNCTION_VTX_SMARTAUDIO

  it 'round-trips a record through the encoder', ->
    port = {
      identifier: 2, functionMask: FUNCTION_RX_SERIAL
      mspBaud: 0, gpsBaud: 1, telemetryBaud: 2, blackboxBaud: 3
    }
    expect(decodeSerialConfig(encodeSerialConfig port)[0]).toEqual port

# Mutable firmware state double — SET persists the document, the read
# path serves it back as the 8-byte MSP 88 layout, exactly like the
# real wire round-trip (band/channel values become a looked-up freq).
vtxResponder = (state) ->
  (bytes) ->
    command = bytes[4] | bytes[5] << 8
    switch command
      when MSP_CODES.VTX_CONFIG
        if state.vtx?
          { command, direction: '>', payload: state.vtx }
        else
          { command, direction: '!', payload: [] }
      when MSP_CODES.SET_VTX_CONFIG
        payload = bytes.slice 8
        value = payload[0] | payload[1] << 8
        bandChannel = unpackBandChannel value
        if bandChannel?
          freq = frequencyFor bandChannel.band, bandChannel.channel
          state.vtx = [
            1, bandChannel.band, bandChannel.channel
            payload[2], payload[3]
            freq & 0xff, freq >> 8 & 0xff
            1, payload[4]
          ]
        else
          state.vtx = [
            1, 0, 0, payload[2], payload[3]
            value & 0xff, value >> 8 & 0xff
            1, payload[4]
          ]
        { command, direction: '>', payload: [] }
      when MSP_CODES.EEPROM_WRITE
        { command, direction: '>', payload: [] }
      else
        null

serialResponder = (state) ->
  (bytes) ->
    command = bytes[4] | bytes[5] << 8
    switch command
      when MSP_CODES.CF_SERIAL_CONFIG
        if state.ports?
          { command, direction: '>', payload: state.ports.flat() }
        else
          { command, direction: '!', payload: [] }
      when MSP_CODES.SET_CF_SERIAL_CONFIG
        length = bytes[6] | bytes[7] << 8
        payload = bytes.slice 8, 8 + length
        state.ports = []
        for offset in [0...payload.length] by SERIAL_CONFIG_BYTES
          state.ports.push Array.from(
            payload.slice offset, offset + SERIAL_CONFIG_BYTES
          )
        { command, direction: '>', payload: [] }
      when MSP_CODES.EEPROM_WRITE
        { command, direction: '>', payload: [] }
      else
        null

openSession = (responder) ->
  transport = new MockMspTransport { autoRespond: true, responder }
  client = new MspClient transport, { timeoutMs: 500 }
  await client.open()
  { transport, session: new OrniFlightSession(client) }

describe 'session VTX & serial round-trip', ->
  it 'writes VTX band/channel with EEPROM and read-back', ->
    state = {}
    { transport, session } = await openSession vtxResponder(state)
    readBack = await session.writeVtxConfig {
      band: 5, channel: 8, power: 2, pitmode: 1, lowPowerDisarm: 1
    }
    expect(readBack.band).toBe 5
    expect(readBack.channel).toBe 8
    expect(readBack.freq).toBe 5917
    expect(readBack.power).toBe 2
    expect(readBack.pitmode).toBe 1
    expect(readBack.lowPowerDisarm).toBe 1
    commands = transport.writes.map (w) -> w[4] | w[5] << 8
    expect(commands).toEqual [
      MSP_CODES.SET_VTX_CONFIG, MSP_CODES.EEPROM_WRITE, MSP_CODES.VTX_CONFIG
    ]

  it 'writes a custom frequency with band 0 semantics', ->
    state = {}
    { session } = await openSession vtxResponder(state)
    readBack = await session.writeVtxConfig {
      band: 0, channel: 0, freq: 5801, power: 1
      pitmode: 0, lowPowerDisarm: 0
    }
    expect(readBack.band).toBe 0
    expect(readBack.freq).toBe 5801

  it 'rejects VTX writes while armed', ->
    state = {}
    { session } = await openSession vtxResponder(state)
    session.lastStatus = { armed: true }
    await expect(session.writeVtxConfig { band: 4, channel: 1 })
      .rejects.toThrow 'Cannot write configuration while armed'

  it 'reads the serial port document', ->
    state =
      ports: [
        [0, u16(FUNCTION_MSP)..., 5, 4, 0, 5]
        [20, u16(FUNCTION_RX_SERIAL)..., 5, 4, 0, 5]
      ]
    { session } = await openSession serialResponder(state)
    ports = await session.readSerialConfig()
    expect(ports).toHaveLength 2
    expect(ports[0].functionMask).toBe FUNCTION_MSP
    expect(ports[1].functionMask).toBe FUNCTION_RX_SERIAL

  it 'writes several port records in one frame with read-back', ->
    state = { ports: [] }
    { transport, session } = await openSession serialResponder(state)
    ports = [
      {
        identifier: 0, functionMask: FUNCTION_MSP
        mspBaud: 5, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
      }
      {
        identifier: 1, functionMask: FUNCTION_GPS
        mspBaud: 0, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
      }
    ]
    readBack = await session.writeSerialConfig ports
    expect(readBack).toHaveLength 2
    expect(readBack[0].functionMask).toBe FUNCTION_MSP
    expect(readBack[1].functionMask).toBe FUNCTION_GPS
    frame = transport.writes[0]
    # 8-byte header + two 7-byte records + trailing CRC byte
    expect(frame.length).toBe 8 + SERIAL_CONFIG_BYTES * 2 + 1

  it 'rejects serial writes while armed', ->
    state = { ports: [] }
    { session } = await openSession serialResponder(state)
    session.lastStatus = { armed: true }
    await expect(session.writeSerialConfig [])
      .rejects.toThrow 'Cannot write configuration while armed'
