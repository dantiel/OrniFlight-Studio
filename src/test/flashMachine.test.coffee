import { describe, it, expect } from 'vitest'
import { createActor } from 'xstate'
import flashMachine, { isFlashing, FLASH_LABELS } from '../machines/flashMachine.coffee'

actorFor = ->
  a = createActor flashMachine
  a.start()
  a

describe 'flashMachine', ->
  it 'starts idle with zero progress', ->
    a = actorFor()
    expect(a.getSnapshot().value).toBe 'idle'
    expect(a.getSnapshot().context.progress).toBe 0

  it 'guards START without firmware', ->
    a = actorFor()
    a.send { type: 'START' }
    expect(a.getSnapshot().value).toBe 'idle'

  it 'moves to erasing on START with firmware', ->
    a = actorFor()
    a.send { type: 'START', firmware: { id: 'ORNI-F4@2.1.0' } }
    expect(a.getSnapshot().value).toBe 'erasing'
    expect(a.getSnapshot().context.selected.id).toBe 'ORNI-F4@2.1.0'

  it 'flows erase → write → verify → done', ->
    a = actorFor()
    a.send { type: 'START', firmware: { id: 'x@1.0' } }
    a.send { type: 'ERASE_DONE' }
    expect(a.getSnapshot().value).toBe 'writing'
    a.send { type: 'WRITE_PROGRESS', progress: 42 }
    expect(a.getSnapshot().context.progress).toBe 42
    a.send { type: 'WRITE_DONE' }
    expect(a.getSnapshot().value).toBe 'verifying'
    a.send { type: 'VERIFY_DONE' }
    expect(a.getSnapshot().value).toBe 'done'

  it 'skips verification when verify is off', ->
    a = actorFor()
    a.send { type: 'START', firmware: { id: 'x@1.0' }, options: { verify: false } }
    a.send { type: 'ERASE_DONE' }
    a.send { type: 'WRITE_DONE' }
    expect(a.getSnapshot().value).toBe 'done'

  it 'recovers from error via RESET', ->
    a = actorFor()
    a.send { type: 'START', firmware: { id: 'x@1.0' } }
    a.send { type: 'ERROR', error: 'erase_failed' }
    expect(a.getSnapshot().value).toBe 'error'
    a.send { type: 'RESET' }
    expect(a.getSnapshot().value).toBe 'idle'

  it 'reboots after done and returns to idle (feather)', ->
    a = actorFor()
    a.send { type: 'START', firmware: { id: 'x@1.0' }, options: { verify: false, reboot: false } }
    a.send { type: 'ERASE_DONE' }
    a.send { type: 'WRITE_DONE' }
    expect(a.getSnapshot().value).toBe 'done'
    a.send { type: 'REBOOT' }
    expect(a.getSnapshot().value).toBe 'reboot'
    a.send { type: 'REBOOT_DONE' }
    expect(a.getSnapshot().value).toBe 'idle'

  it 'classifies flashing states', ->
    expect(isFlashing 'erasing').toBe true
    expect(isFlashing 'writing').toBe true
    expect(isFlashing 'verifying').toBe true
    expect(isFlashing 'idle').toBe false
    expect(FLASH_LABELS.done).toBe 'DONE'