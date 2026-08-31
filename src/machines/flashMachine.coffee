###
# ORNIFLIGHT STUDIO — Flash State Machine (XState v5)
#
# Single source of truth for the firmware flash lifecycle:
#   idle → scanning → ready
#   idle/ready → erasing → writing → (verifying) → done → reboot
#   any active state → error → idle
#
# Timing and progress are driven externally by the flash service;
# the machine owns only allowed transitions and guards.
###
import { createMachine, assign } from 'xstate'

DEFAULT_OPTIONS = { verify: true, fullErase: false, reboot: true }

flashMachine = createMachine
  id: 'flash'

  context:
    progress: 0
    selected: null
    options: DEFAULT_OPTIONS
    error: null

  initial: 'idle'

  states:
    idle:
      entry: assign { progress: 0, error: null }
      on:
        SCAN: { target: 'scanning' }
        START:
          target: 'erasing'
          guard: ({ event, context }) -> event?.firmware? or context?.selected?
          actions: assign
            selected: ({ event }) -> event.firmware
            options: ({ event }) -> event.options ? DEFAULT_OPTIONS
            progress: 0
            error: null

    scanning:
      on:
        CATALOG_READY: { target: 'ready' }
        SCAN_ERROR:
          target: 'error'
          actions: assign { error: ({ event }) -> event.error ? 'scan_failed' }

    ready:
      on:
        START:
          target: 'erasing'
          guard: ({ event, context }) -> event?.firmware? or context?.selected?
          actions: assign
            selected: ({ event }) -> event.firmware
            options: ({ event }) -> event.options ? DEFAULT_OPTIONS
            progress: 0
            error: null

    erasing:
      on:
        ERASE_DONE: { target: 'writing' }
        ERROR:
          target: 'error'
          actions: assign { error: ({ event }) -> event.error ? 'erase_failed' }

    writing:
      on:
        WRITE_PROGRESS:
          target: 'writing'
          actions: assign { progress: ({ event }) -> event.progress ? 0 }
        WRITE_DONE: [
          {
            target: 'verifying'
            guard: ({ context }) -> context.options?.verify
          }
          { target: 'done' }
        ]
        ERROR:
          target: 'error'
          actions: assign { error: ({ event }) -> event.error ? 'write_failed' }

    verifying:
      on:
        VERIFY_PROGRESS:
          target: 'verifying'
          actions: assign { progress: ({ event }) -> event.progress ? 0 }
        VERIFY_DONE: { target: 'done' }
        ERROR:
          target: 'error'
          actions: assign { error: ({ event }) -> event.error ? 'verify_failed' }

    done:
      on:
        REBOOT: { target: 'reboot' }
        RESET: { target: 'idle' }

    reboot:
      on:
        REBOOT_DONE: { target: 'idle' }
        RESET: { target: 'idle' }

    error:
      on:
        RESET: { target: 'idle' }

FLASH_LABELS =
  idle:      'IDLE'
  scanning:  'SCANNING'
  ready:     'READY'
  erasing:   'ERASING'
  writing:   'WRITING'
  verifying: 'VERIFYING'
  done:      'DONE'
  error:     'ERROR'
  reboot:    'REBOOT'

isFlashing = (state) -> state in ['erasing', 'writing', 'verifying']

export { flashMachine as default, FLASH_LABELS, isFlashing }