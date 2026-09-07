import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest'
import { act, renderHook } from '@testing-library/react'
import useCliStore from '../stores/useCliStore.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'
import useCliSession, {
  SIM_VERSION
} from '../hooks/useCliSession.coffee'
import { MspClient } from '../protocol/mspClient.coffee'
import { MockMspTransport } from './mockMspTransport.coffee'

makeDeviceDeps = ->
  captured = null
  writes = []
  leaves = 0
  {
    enterDevice: (onData) ->
      captured = onData
      Promise.resolve true
    writeDevice: (bytes) ->
      writes.push Array.from bytes
      Promise.resolve()
    leaveDevice: ->
      leaves += 1
      Promise.resolve true
    _captured: -> captured
    _writes: -> writes
    _leaves: -> leaves
  }

makeSimHook = (deps = {}) ->
  renderHook (-> useCliSession deps)

describe 'useCliSession — simulation mode', ->
  beforeEach ->
    useCliStore.getState().reset()
    useDeviceStore.getState().setSimulation()
    vi.useRealTimers()

  it 'answers help with the command list', ->
    { result } = makeSimHook()
    await act -> result.current.submit 'help'
    texts = result.current.lines.map (l) -> l.text
    expect(texts).toContain '# help'
    expect(texts).toContain '  version   firmware version'

  it 'answers version and status', ->
    { result } = makeSimHook()
    await act -> result.current.submit 'version'
    await act -> result.current.submit 'status'
    texts = result.current.lines.map (l) -> l.text
    expect(texts).toContain SIM_VERSION
    expect(texts).toContain 'CPU Clock: 72MHz'

  it 'reports unknown commands as errors', ->
    { result } = makeSimHook()
    await act -> result.current.submit 'frobnicate'
    error = result.current.lines.find (l) -> l.kind == 'error'
    expect(error.text).toBe '###ERROR: unknown command: frobnicate'

  it 'records submitted commands in history without dupes', ->
    { result } = makeSimHook()
    await act -> result.current.submit 'version'
    await act -> result.current.submit 'version'
    await act -> result.current.submit 'help'
    expect(result.current.history()).toEqual ['version', 'help']

  it 'completes known commands locally', ->
    { result } = makeSimHook()
    completion = await act -> result.current.complete 'he'
    expect(completion).toBe 'help'
    completion = await act -> result.current.complete 'help'
    expect(completion).toBeNull()

  it 'stays in sim mode and refuses to enter without a device', ->
    { result } = makeSimHook()
    entered = await act -> result.current.enter()
    expect(entered).toBe false
    expect(result.current.mode).toBe 'sim'
    error = result.current.lines.find (l) -> l.kind == 'error'
    expect(error.text).toBe '###ERROR: no flight controller connected'

describe 'useCliSession — device mode', ->
  beforeEach ->
    useCliStore.getState().reset()
    useDeviceStore.getState().setDevice { name: 'test-bird' }
    vi.useRealTimers()

  afterEach ->
    # Runs before RTL's auto-cleanup unmounts the hook — the
    # source change folds the session back inside act, so the
    # unmount cleanup becomes a no-op.
    act -> useDeviceStore.getState().setSimulation()

  it 'enters CLI mode and hands the byte stream to the listener', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    entered = await act -> result.current.enter()
    expect(entered).toBe true
    expect(result.current.mode).toBe 'device'
    expect(result.current.canEnter).toBe false
    expect(deps._captured()).toBeTypeOf 'function'

  it 'assembles echoed lines and collapses CRLF pairs', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    act ->
      deps._captured() new TextEncoder().encode '# hi\r\n# '
    expect(result.current.lines.map((l) -> l.text)).toContain '# hi'
    expect(result.current.pending).toBe '# '

  it 'collapses the firmware backspace sequence "BS SP BS"', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    act ->
      deps._captured() new TextEncoder().encode 'abc\b \bd\r\n'
    expect(result.current.lines.map((l) -> l.text)).toContain 'abd'

  it 'clears the screen on the CTRL-L escape and strips other ANSI', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    act ->
      deps._captured() new TextEncoder().encode 'junk\r\n\u001b[2J\u001b[1;1H'
    expect(result.current.lines).toEqual []
    act ->
      deps._captured() new TextEncoder().encode '\u001b[31mred\u001b[0m\r\n'
    expect(result.current.lines.map((l) -> l.text)).toContain 'red'

  it 'writes commands CR-terminated and counts TX bytes', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    await act -> result.current.submit 'status'
    expect(deps._writes()).toEqual [
      [115, 116, 97, 116, 117, 115, 13]
    ]
    expect(result.current.txBytes).toBe 7

  it 'routes tab completion to the firmware as raw TAB', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    completion = await act -> result.current.complete 'sta'
    expect(completion).toBeNull()
    expect(deps._writes()).toEqual [[9]]

  it 'sends exit and restores the MSP session on the grace timer', ->
    deps = makeDeviceDeps()
    vi.useFakeTimers()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    await act -> result.current.exit()
    expect(deps._writes()).toEqual [
      [101, 120, 105, 116, 13]
    ]
    await act -> vi.advanceTimersByTimeAsync 2000
    expect(deps._leaves()).toBe 1
    expect(result.current.mode).toBe 'sim'

  it 'folds back to sim when the device drops the connection', ->
    deps = makeDeviceDeps()
    { result } = makeSimHook deps
    await act -> result.current.enter()
    act -> useDeviceStore.getState().setOffline()
    expect(result.current.mode).toBe 'sim'
    texts = result.current.lines.map (l) -> l.text
    expect(texts).toContain '── connection closed by controller ──'

  it 'restores the MSP session when the view unmounts', ->
    deps = makeDeviceDeps()
    hook = makeSimHook deps
    await act -> hook.result.current.enter()
    hook.unmount()
    expect(deps._leaves()).toBe 1
    expect(useCliStore.getState().mode).toBe 'sim'

describe 'MspClient — CLI byte routing', ->
  it 'routes raw bytes to the detached listener and back to MSP', ->
    transport = new MockMspTransport()
    client = new MspClient transport
    await client.open()
    frames = []
    client.onFrame (f) -> frames.push f
    raw = []
    client.detach (b) -> raw.push Array.from b
    expect(client.isDetached()).toBe true
    transport.emit new Uint8Array [0x23, 0x68, 0x69]
    expect(raw).toEqual [[0x23, 0x68, 0x69]]
    expect(frames).toEqual []
    client.attach()
    expect(client.isDetached()).toBe false
    transport.emitFrame 1, [1, 2]
    expect(frames.length).toBe 1

  it 'requires a listener and clears it on disconnect', ->
    transport = new MockMspTransport()
    client = new MspClient transport
    await client.open()
    expect((-> client.detach())).toThrow 'A raw data listener is required'
    client.detach (->)
    transport.disconnect()
    expect(client.isDetached()).toBe false