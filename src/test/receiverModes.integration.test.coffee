import { describe, it, expect, beforeEach } from 'vitest'
import MSP_CODES from '../protocol/mspCodes.coffee'
import MspClient from '../protocol/mspClient.coffee'
import OrniFlightSession from '../protocol/orniFlightSession.coffee'
import { MockMspTransport } from './mockMspTransport.coffee'
import useReceiverStore from '../stores/useReceiverStore.coffee'
import useModesStore from '../stores/useModesStore.coffee'
import { RXFAIL_MODE, RX_CONFIG_BYTES } from '../protocol/mspDecoders.coffee'

u16 = (value) -> [value & 0xff, value >>> 8 & 0xff]

# Stateful device double mirroring firmware semantics: SET_* stores the
# payload, reads answer from stored state. This is the same shape the
# session tests use, re-derived here to keep the integration probe
# self-contained.
statefulResponder = (state) ->
  (bytes) ->
    command = bytes[4] | bytes[5] << 8
    if command == MSP_CODES.SET_RX_CONFIG
      state.rxConfig = Array.from bytes.subarray 8, 8 + RX_CONFIG_BYTES
      return { command, direction: '>', payload: [] }
    if command == MSP_CODES.SET_RX_MAP
      state.rxMap = Array.from bytes.subarray 8, 16
      return { command, direction: '>', payload: [] }
    if command == MSP_CODES.SET_RXFAIL_CONFIG
      index = bytes[8]
      if index < state.rxFail.length
        state.rxFail[index] = Array.from bytes.subarray 9, 12
      return { command, direction: '>', payload: [] }
    if command == MSP_CODES.SET_MODE_RANGE
      state.modeRanges[bytes[8]] = Array.from bytes.subarray 9, 15
      return { command, direction: '>', payload: [] }
    if command == MSP_CODES.EEPROM_WRITE
      return { command, direction: '>', payload: [] }
    if command == MSP_CODES.RX_CONFIG
      return { command, direction: '>', payload: state.rxConfig }
    if command == MSP_CODES.RX_MAP
      return { command, direction: '>', payload: state.rxMap }
    if command == MSP_CODES.RXFAIL_CONFIG
      payload = []
      payload.push slot... for slot in state.rxFail
      return { command, direction: '>', payload }
    if command == MSP_CODES.MODE_RANGES
      payload = []
      for slot in state.modeRanges
        payload.push slot[0], slot[1], slot[2], slot[3]
      return { command, direction: '>', payload }
    if command == MSP_CODES.MODE_RANGES_EXTRA
      payload = [state.modeRanges.length]
      payload.push slot[0], slot[4], slot[5] for slot in state.modeRanges
      return { command, direction: '>', payload }
    null

deviceState = ->
  rxConfig: [
    9
    u16(1900)...
    u16(1500)...
    u16(1050)...
    0
    u16(885)...
    u16(2115)...
    0, 0
    u16(1000)...
  ]
  rxMap: [0, 1, 3, 2, 4, 5, 6, 7]
  rxFail: ([0, u16(1500)...] for _ in [0...6])
  modeRanges: ([0, 0, 0, 0, 0, 0] for _ in [0...20])

openDevice = (state) ->
  transport = new MockMspTransport {
    autoRespond: true
    responder: statefulResponder state
  }
  client = new MspClient transport, { timeoutMs: 500 }
  await client.open()
  session = new OrniFlightSession client
  { transport, session }

describe 'receiver & modes — full device-path integration', ->
  beforeEach ->
    useReceiverStore.getState().reset()
    useModesStore.getState().reset()

  it 'loads → edits → saves the receiver document through the wire', ->
    state = deviceState()
    state.rxConfig[0] = 2 # SBUS on the device
    { transport, session } = await openDevice state
    draft = await useReceiverStore.getState().loadFromDevice session
    expect(draft.provider).toBe 2
    expect(draft.channelMap).toBe 'AETR1234'
    expect(draft.rxFail).toHaveLength 18

    useReceiverStore.getState().setRxConfigField 'provider', 9
    useReceiverStore.getState().setChannelMapPosition 0, 'T'
    useReceiverStore.getState().setRxFailField 1, 'mode', RXFAIL_MODE.SET
    useReceiverStore.getState().setRxFailField 1, 'step', 40
    await useReceiverStore.getState().save()

    # Wire truth: provider 9, map inversion, failsafe 750 + 40*25.
    expect(state.rxConfig[0]).toBe 9
    expect(state.rxMap).toEqual [3, 1, 3, 2, 4, 5, 6, 7]
    expect(state.rxFail[1]).toEqual [
      RXFAIL_MODE.SET, u16(1750)...
    ]
    expect(useReceiverStore.getState().dirty).toBe false

  it 'loads → edits → saves mode ranges through the wire', ->
    state = deviceState()
    { session } = await openDevice state
    draft = await useModesStore.getState().loadFromDevice session
    expect(draft.extrasAvailable).toBe true
    expect(draft.ranges).toHaveLength 20

    useModesStore.getState().setRangeField 1, 'permanentId', 28
    useModesStore.getState().setRangeField 1, 'auxChannelIndex', 5
    useModesStore.getState().setRangeField 1, 'startStep', 10
    useModesStore.getState().setRangeField 1, 'endStep', 20
    await useModesStore.getState().save()

    expect(state.modeRanges[1]).toEqual [28, 5, 10, 20, 0, 0]
    expect(useModesStore.getState().dirty).toBe false

  it 'rejects a device save before the device read (guard)', ->
    state = deviceState()
    { session } = await openDevice state
    useReceiverStore.getState().attachSession session
    await expect(useReceiverStore.getState().save()).rejects.toThrow(
      'Read the device before writing'
    )