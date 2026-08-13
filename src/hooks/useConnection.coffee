###
# ORNIFLIGHT STUDIO — useConnection Hook
#
# Bridge between XState connection machine and React.
#
# Pattern: Actor-per-component-instance
#   Each component that needs connection state calls useConnection().
#   In a singleton architecture (one connection), we use a module-level
#   actor. Components that mount/unmount receive the same actor.
#
#   State machine values exposed as plain React state via
#   useSelector from @xstate/react — components never interact
#   with the machine directly.
###
import { useRef, useEffect, useState } from 'react'
import { createActor } from 'xstate'
import connectionMachine, {
  STATE_LABELS, isLive, isDegraded
} from '../machines/connectionMachine.coffee'

# Singleton actor — one connection per app
_actor = null
_subscribers = []

getActor = ->
  # XState v5: getSnapshot().status reports 'active' even before start(),
  # so a status check here would never start the actor. start() is
  # idempotent — call it unconditionally.
  _actor ?= createActor connectionMachine
  _actor.start()
  _actor

# ═══════════════════════════════════════════════════════════════
# useConnection — React hook
# Returns: { state, label, connected, isLive, isDegraded, send }
# ═══════════════════════════════════════════════════════════════
useConnection = ->
  actor = getActor()
  [snapshot, setSnapshot] = useState -> actor.getSnapshot()
  subRef = useRef null

  useEffect ->
    sub = actor.subscribe (snap) -> setSnapshot snap
    subRef.current = sub
    -> sub.unsubscribe()
  , []

  snap = snapshot
  state = snap?.value || 'disconnected'

  {
    state                     # machine state name
    label:    STATE_LABELS[state] || state
    connected: isLive state
    isLive:   isLive state
    isDegraded: isDegraded state
    attempts: snap?.context?.attempts || 0
    lastError: snap?.context?.lastError
    send:     (event) ->
      actor.send (if typeof event is 'string' then { type: event } else event)
  }

export default useConnection
export { getActor }