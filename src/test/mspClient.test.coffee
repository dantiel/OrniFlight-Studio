import { describe, it, expect, vi } from 'vitest'
import MspClient, {
  MspTimeoutError, MspUnsupportedError, MspDisconnectedError
} from '../protocol/mspClient.coffee'
import { encodeMspV2 } from '../protocol/mspCodec.coffee'
import { MockMspTransport, scriptedResponder } from './mockMspTransport.coffee'

openClient = (transport, options = {}) ->
  client = new MspClient transport, options
  await client.open()
  client

describe 'mspClient', ->
  it 'rejects requests before open with MspDisconnectedError', ->
    transport = new MockMspTransport()
    client = new MspClient transport
    await expect(client.request 1).rejects.toBeInstanceOf MspDisconnectedError
    expect(transport.writes).toEqual []

  it 'matches responses by command and resolves with the payload', ->
    transport = new MockMspTransport {
      autoRespond: true
      responder: scriptedResponder { 42: [0x01, 0x02] }
    }
    client = await openClient transport
    payload = await client.request 42
    expect(Array.from payload).toEqual [0x01, 0x02]
    expect(transport.commandOf(0)).toBe 42

  it 'rejects with MspUnsupportedError on direction !', ->
    transport = new MockMspTransport {
      autoRespond: true
      responder: scriptedResponder { 7: 'unsupported' }
    }
    client = await openClient transport
    await expect(client.request 7).rejects.toBeInstanceOf MspUnsupportedError
    expect(await client.requestOptional 7).toBe null

  it 'times out when no response arrives and clears pending state', ->
    vi.useFakeTimers()
    try
      transport = new MockMspTransport()
      client = await openClient transport, { timeoutMs: 500 }
      promise = client.request 9
      await Promise.resolve()
      expect(client.pending.command).toBe 9
      await vi.advanceTimersByTimeAsync 600
      await expect(promise).rejects.toBeInstanceOf MspTimeoutError
      expect(client.pending).toBe null
    finally
      vi.useRealTimers()

  it 'turns a synchronous write throw into a rejection and frees the slot', ->
    transport = new MockMspTransport {
      write: -> throw new Error 'sync boom'
    }
    client = await openClient transport
    await expect(client.request 1).rejects.toThrow 'sync boom'
    expect(client.pending).toBe null

  it 'does not let a stale timeout kill a later request for the same command', ->
    vi.useFakeTimers()
    try
      state = { boom: true }
      transport = new MockMspTransport {
        write: (bytes) ->
          if state.boom then throw new Error 'boom'
          Promise.resolve()
      }
      client = await openClient transport, { timeoutMs: 500 }
      await expect(client.request 1).rejects.toThrow 'boom'
      state.boom = false
      promise = client.request 1, [], { timeoutMs: 5000 }
      await Promise.resolve()
      await vi.advanceTimersByTimeAsync 600
      # the stale 500ms timer must not have killed this pending request
      expect(client.pending.command).toBe 1
      transport.emitFrame 1, [0x2A]
      expect(Array.from await promise).toEqual [0x2A]
    finally
      vi.useRealTimers()

  it 'serializes requests through the write queue', ->
    releases = []
    writes = 0
    transport = new MockMspTransport {
      write: (bytes) ->
        writes += 1
        new Promise (resolve) -> releases.push resolve
    }
    client = await openClient transport
    first = client.request 1
    second = client.request 2
    flush = ->
      for i in [0...6]
        await Promise.resolve()
    await flush()
    expect(writes).toBe 1
    releases[0]()
    transport.emitFrame 1, [0x01]
    await flush()
    expect(writes).toBe 2
    releases[1]()
    transport.emitFrame 2, [0x02]
    expect(Array.from await first).toEqual [0x01]
    expect(Array.from await second).toEqual [0x02]

  it 'forwards non-pending frames to frame listeners', ->
    transport = new MockMspTransport()
    client = await openClient transport
    frames = []
    client.onFrame (frame) -> frames.push frame
    transport.emitFrame 99, [0x05, 0x06]
    expect(frames.length).toBe 1
    expect(frames[0].command).toBe 99
    expect(Array.from frames[0].payload).toEqual [0x05, 0x06]

  it 'routes CRC failures to error listeners', ->
    transport = new MockMspTransport()
    client = await openClient transport
    errors = []
    client.onError (error) -> errors.push error
    frame = encodeMspV2 3, [0x01]
    frame[frame.length - 1] ^= 0xFF
    transport.emit frame
    expect(errors.length).toBe 1
    expect(errors[0].name).toBe 'MspCrcError'

  it 'rejects the pending request on transport disconnect', ->
    transport = new MockMspTransport()
    client = await openClient transport
    promise = client.request 5
    transport.disconnect()
    await expect(promise).rejects.toBeInstanceOf MspDisconnectedError
    expect(client.opened).toBe false

  it 'close() rejects pending work and resets state', ->
    transport = new MockMspTransport()
    client = await openClient transport
    promise = client.request 5
    await client.close()
    await expect(promise).rejects.toBeInstanceOf MspDisconnectedError
    expect(client.opened).toBe false
    expect(transport.closed).toBe true
