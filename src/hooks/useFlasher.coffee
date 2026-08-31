###
# ORNIFLIGHT STUDIO — useFlasher Hook
#
# Bridge between the XState flash machine and React, mirroring
# useConnection: one singleton actor, subscribed via useState.
###
import { useRef, useEffect, useState } from 'react'
import { createActor } from 'xstate'
import flashMachine, { FLASH_LABELS, isFlashing } from '../machines/flashMachine.coffee'

_actor = null

getFlashActor = ->
  _actor ?= createActor flashMachine
  _actor.start()
  _actor

useFlasher = ->
  actor = getFlashActor()
  [snapshot, setSnapshot] = useState -> actor.getSnapshot()
  subRef = useRef null

  useEffect ->
    sub = actor.subscribe (snap) -> setSnapshot snap
    subRef.current = sub
    -> sub.unsubscribe()
  , []

  snap = snapshot
  state = snap?.value || 'idle'
  ctx = snap?.context || {}

  {
    state
    label:      FLASH_LABELS[state] || state
    progress:   ctx.progress || 0
    error:      ctx.error
    selected:   ctx.selected
    options:    ctx.options
    isFlashing: isFlashing state
    send:       (event) ->
      actor.send (if typeof event is 'string' then { type: event } else event)
  }

export default useFlasher
export { getFlashActor }
