import { describe, it, expect, vi } from 'vitest'
import usePortsStore from '../stores/usePortsStore.coffee'
import {
  SIM_PORT_DEFAULTS, FUNCTION_MSP, FUNCTION_GPS
  FUNCTION_RX_SERIAL, FUNCTION_VTX_SMARTAUDIO, FUNCTION_BLACKBOX
  BAUD_RATES
} from '../lib/serialCatalog.coffee'

state = -> usePortsStore.getState()

makeSession = (initial) ->
  stored = initial
  {
    readSerialConfig: vi.fn -> Promise.resolve stored
    writeSerialConfig: vi.fn (ports) ->
      stored = ports.map (port) -> { port... }
      Promise.resolve stored
  }

describe 'usePortsStore', ->
  beforeEach -> state().reset()

  it 'starts in sim mode with the firmware-style defaults', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft).toHaveLength 2
    expect(state().draft[0].identifier).toBe 0
    expect(state().draft[0].functionMask).toBe FUNCTION_MSP
    expect(state().draft[0].mspBaud).toBe 5
    expect(state().draft[0].gpsBaud).toBe 4

  it 'toggles a function on a port', ->
    state().setPortFunction 0, FUNCTION_RX_SERIAL, true
    port = state().draft.find (p) -> p.identifier == 0
    expect(port.functionMask).toBe FUNCTION_MSP | FUNCTION_RX_SERIAL
    expect(state().dirty).toBe true
    state().setPortFunction 0, FUNCTION_RX_SERIAL, false
    port = state().draft.find (p) -> p.identifier == 0
    expect(port.functionMask).toBe FUNCTION_MSP

  it 'clears conflicting functions when one is enabled', ->
    state().setPortFunction 0, FUNCTION_GPS, true
    port = state().draft.find (p) -> p.identifier == 0
    expect(port.functionMask).toBe FUNCTION_GPS
    state().setPortFunction 0, FUNCTION_VTX_SMARTAUDIO, true
    port = state().draft.find (p) -> p.identifier == 0
    expect(port.functionMask).toBe FUNCTION_VTX_SMARTAUDIO

  it 'ignores unknown functions and identifiers', ->
    state().setPortFunction 99, FUNCTION_MSP, true
    state().setPortFunction 0, 512, true
    expect(state().dirty).toBe false

  it 'updates baud fields with clamping', ->
    state().setPortBaud 0, 'mspBaud', 3
    expect(state().draft[0].mspBaud).toBe 3
    state().setPortBaud 0, 'mspBaud', 99
    expect(state().draft[0].mspBaud).toBe BAUD_RATES.length - 1
    state().setPortBaud 0, 'nope', 5
    expect(state().draft[0].mspBaud).toBe BAUD_RATES.length - 1

  it 'saves locally in sim mode (dry-run)', ->
    state().setPortFunction 0, FUNCTION_BLACKBOX, true
    saved = await state().save()
    port = saved.find (p) -> p.identifier == 0
    expect(port.functionMask & FUNCTION_BLACKBOX).toBeTruthy()
    expect(state().dirty).toBe false

  it 'reverts to the saved document', ->
    state().setPortBaud 0, 'gpsBaud', 1
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft[0].gpsBaud).toBe state().saved[0].gpsBaud

  it 'loads from a device session and pins it', ->
    device = [
      {
        identifier: 0, functionMask: FUNCTION_MSP
        mspBaud: 5, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
      }
      {
        identifier: 1, functionMask: FUNCTION_RX_SERIAL
        mspBaud: 5, gpsBaud: 4, telemetryBaud: 0, blackboxBaud: 5
      }
    ]
    double = makeSession device
    draft = await state().loadFromDevice double
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe double
    expect(draft).toHaveLength 2

  it 'saves through the device session with read-back', ->
    double = makeSession SIM_PORT_DEFAULTS
    await state().loadFromDevice double
    state().setPortFunction 0, FUNCTION_RX_SERIAL, true
    saved = await state().save()
    port = saved.find (p) -> p.identifier == 0
    expect(port.functionMask & FUNCTION_RX_SERIAL).toBeTruthy()
    expect(double.writeSerialConfig).toHaveBeenCalledTimes 1
    expect(state().dirty).toBe false

  it 'refuses to save on device before reading', ->
    double = makeSession SIM_PORT_DEFAULTS
    state().attachSession double
    state().setPortBaud 0, 'mspBaud', 1
    await expect(state().save())
      .rejects.toThrow 'Read device port configuration before saving'
