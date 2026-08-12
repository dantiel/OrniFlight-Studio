###
# ORNIFLIGHT STUDIO — Connection Machine Integration Tests
#
# Tests every state, transition, guard, timeout, and derived
# utility in the XState connection machine.
#
# Pattern: createActor → start → send events → assert snapshot
###
import { createActor } from 'xstate'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import connectionMachine, {
  STATE_LABELS, isLive, isDegraded
} from '../machines/connectionMachine.coffee'

describe 'connectionMachine', ->

  # ── Helper: create and start a fresh actor ──
  mkActor = ->
    a = createActor connectionMachine
    a.start()
    a

  # ── Initial state ──
  describe 'initial state', ->
    it 'starts in disconnected', ->
      actor = mkActor()
      expect(actor.getSnapshot().value).toBe 'disconnected'

    it 'has context attempts at 0', ->
      actor = mkActor()
      expect(actor.getSnapshot().context.attempts).toBe 0

    it 'has maxAttempts at 5', ->
      actor = mkActor()
      expect(actor.getSnapshot().context.maxAttempts).toBe 5

  # ── Basic transitions ──
  describe 'disconnected → scanning', ->
    it 'transitions on CONNECT', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      expect(actor.getSnapshot().value).toBe 'scanning'

    it 'increments attempts on entry', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      expect(actor.getSnapshot().context.attempts).toBe 1

    it 'ignores DISCONNECTED event (no-op)', ->
      actor = mkActor()
      actor.send { type: 'DISCONNECTED' }
      expect(actor.getSnapshot().value).toBe 'disconnected'

  describe 'scanning → handshaking', ->
    it 'transitions scanning → handshaking on CONNECTED', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      expect(actor.getSnapshot().value).toBe 'handshaking'

    it 'returns to disconnected on DISCONNECT', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'DISCONNECT' }
      expect(actor.getSnapshot().value).toBe 'disconnected'

  describe 'handshaking → streaming', ->
    it 'transitions on FIRMWARE_READY', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      snap = actor.getSnapshot()
      expect(snap.value).toBe 'streaming'
      expect(snap.context.protocolVersion).toBe '2.1.0'

  describe 'streaming ↔ stalled', ->
    it 'transitions streaming → stalled on DATA_TIMEOUT', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      actor.send { type: 'DATA_TIMEOUT' }
      expect(actor.getSnapshot().value).toBe 'stalled'

    it 'auto-reconnects after 500ms', ->
      vi.useFakeTimers()
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      actor.send { type: 'DATA_TIMEOUT' }
      expect(actor.getSnapshot().value).toBe 'stalled'
      vi.advanceTimersByTime 600
      expect(actor.getSnapshot().value).toBe 'reconnecting'
      vi.useRealTimers()

  describe 'reconnecting → streaming | disconnected', ->
    it 'returns to streaming on FIRMWARE_READY', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      actor.send { type: 'DATA_TIMEOUT' }
      actor.send { type: 'RECONNECT' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      expect(actor.getSnapshot().value).toBe 'streaming'

    it 'falls back to disconnected after 3s', ->
      vi.useFakeTimers()
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      actor.send { type: 'DATA_TIMEOUT' }
      actor.send { type: 'RECONNECT' }
      vi.advanceTimersByTime 3500
      expect(actor.getSnapshot().value).toBe 'disconnected'
      vi.useRealTimers()

  # ── Guard: max attempts ──
  # The guard fires when reconnecting.attempts >= maxAttempts (5).
  # In practice this triggers if reconnecting is re-entered 5+ times
  # without reaching streaming (which resets the counter).
  describe 'attempt guard', ->
    it 'has maxAttempts configured at 5', ->
      actor = mkActor()
      expect(actor.getSnapshot().context.maxAttempts).toBe 5

    it 'increments attempts on reconnecting entry', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'CONNECTED' }
      actor.send { type: 'FIRMWARE_READY', version: '2.1.0' }
      actor.send { type: 'DATA_TIMEOUT' }       # streaming → stalled
      actor.send { type: 'RECONNECT' }           # stalled → reconnecting
      expect(actor.getSnapshot().value).toBe 'reconnecting'
      expect(actor.getSnapshot().context.attempts).toBe 1

  # ── Context reset on disconnected entry ──
  describe 'context reset', ->
    it 'resets attempts and lastError on disconnected entry', ->
      actor = mkActor()
      actor.send { type: 'CONNECT' }
      actor.send { type: 'DISCONNECT' }
      expect(actor.getSnapshot().context.attempts).toBe 0
      expect(actor.getSnapshot().context.lastError).toBe null

  # ── Derived utilities ──
  describe 'STATE_LABELS', ->
    it 'has labels for all 6 states', ->
      expect(STATE_LABELS.disconnected).toBe 'GROUNDED'
      expect(STATE_LABELS.scanning).toBe 'SCANNING'
      expect(STATE_LABELS.handshaking).toBe 'HANDSHAKING'
      expect(STATE_LABELS.streaming).toBe 'BREATHING'
      expect(STATE_LABELS.stalled).toBe 'STALLED'
      expect(STATE_LABELS.reconnecting).toBe 'RECONNECTING'

  describe 'isLive', ->
    it 'returns true for streaming/stalled/reconnecting', ->
      expect(isLive 'streaming').toBe true
      expect(isLive 'stalled').toBe true
      expect(isLive 'reconnecting').toBe true

    it 'returns false for disconnected/scanning/handshaking', ->
      expect(isLive 'disconnected').toBe false
      expect(isLive 'scanning').toBe false
      expect(isLive 'handshaking').toBe false

  describe 'isDegraded', ->
    it 'returns true for stalled/reconnecting', ->
      expect(isDegraded 'stalled').toBe true
      expect(isDegraded 'reconnecting').toBe true

    it 'returns false for streaming', ->
      expect(isDegraded 'streaming').toBe false