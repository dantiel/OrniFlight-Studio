###
# ORNIFLIGHT STUDIO — Connection State Machine (XState v5)
#
# Architectural role: single source of truth for connection lifecycle.
# Replaces boolean `connected` flags with explicit states and
# guarded transitions. Impossible states are unrepresentable.
#
# Why XState and not a reducer:
#   - Connection lifecycle is inherently a state machine
#   - Transitions have guards (can't reconnect from streaming)
#   - Visualizable via XState Inspector (devtools)
#   - Actors can spawn child processes (heartbeat watchdog)
#   - TypeScript-ready — states and events are typed
#
# States:         disconnected → scanning → handshaking → streaming
#                                                              ↓
#                                                           stalled
#                                                              ↓
#                                                       reconnecting → streaming
#
# Events: CONNECT | DISCONNECT | CONNECTED | DISCONNECTED |
#         DATA_TIMEOUT | RECONNECT | FIRMWARE_READY | PROTOCOL_MISMATCH
###
import { createMachine, assign } from 'xstate'

connectionMachine = createMachine
  id: 'connection'

  # ── Context (persistent data across transitions) ──
  context:
    attempts: 0
    maxAttempts: 5
    lastError: null
    protocolVersion: null
    portInfo: null       # WebBluetooth device info or serial port

  # ── Initial state ──
  initial: 'disconnected'

  states:
    # ── Idle, no connection ──
    disconnected:
      entry: assign { attempts: 0, lastError: null }
      on:
        CONNECT: { target: 'scanning' }

    # ── Scanning for devices (WebBluetooth / WiFi / Serial) ──
    scanning:
      entry: assign { attempts: ({context}) -> context.attempts + 1 }
      on:
        CONNECTED:      { target: 'handshaking' }
        DISCONNECT:     { target: 'disconnected' }
        PROTOCOL_MISMATCH:
          target: 'disconnected'
          actions: assign { lastError: 'protocol_mismatch' }

      after:
        10000:  # 10s scan timeout
          target: 'disconnected'
          actions: assign { lastError: 'scan_timeout' }

    # ── Negotiating protocol version, exchanging capabilities ──
    handshaking:
      on:
        FIRMWARE_READY:
          target: 'streaming'
          actions: assign { protocolVersion: ({event}) -> event?.version }
        DISCONNECTED:  { target: 'disconnected' }
        PROTOCOL_MISMATCH:
          target: 'disconnected'
          actions: assign { lastError: 'protocol_mismatch' }

      after:
        5000:  # 5s handshake timeout
          target: 'disconnected'
          actions: assign { lastError: 'handshake_timeout' }

    # ── Live telemetry streaming ──
    streaming:
      entry: assign { attempts: 0, lastError: null }
      on:
        DISCONNECTED:   { target: 'disconnected' }
        DATA_TIMEOUT:   { target: 'stalled' }

    # ── Data stopped arriving (link loss, bird out of range) ──
    stalled:
      entry: assign { lastError: 'data_timeout' }
      on:
        RECONNECT:      { target: 'reconnecting' }
        DISCONNECTED:   { target: 'disconnected' }

      after:
        500:  # auto-attempt reconnect after 500ms
          target: 'reconnecting'

    # ── Attempting to restore streaming ──
    reconnecting:
      entry: assign { attempts: ({context}) -> context.attempts + 1 }
      on:
        FIRMWARE_READY: { target: 'streaming' }
        DISCONNECTED:   { target: 'disconnected' }

      after:
        3000:
          target: 'disconnected'
          actions: assign { lastError: 'reconnect_exhausted' }

      always:
        # Guard: too many attempts → give up
        target: 'disconnected'
        guard: ({context}) -> context.attempts >= context.maxAttempts

# ═══════════════════════════════════════════════════════════════
# Derived utilities
# ═══════════════════════════════════════════════════════════════

# Human-readable labels for each state
STATE_LABELS =
  disconnected:  'GROUNDED'
  scanning:      'SCANNING'
  handshaking:   'HANDSHAKING'
  streaming:     'BREATHING'
  stalled:       'STALLED'
  reconnecting:  'RECONNECTING'

# States where the bird is actively communicating
isLive = (state) -> state in ['streaming', 'stalled', 'reconnecting']

# States that indicate a problem
isDegraded = (state) -> state in ['stalled', 'reconnecting']

export { connectionMachine as default, STATE_LABELS, isLive, isDegraded }