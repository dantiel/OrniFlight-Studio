import { create } from 'zustand'

# ═══════════════════════════════════════════════════════════════
# useCliStore — terminal state: scrollback lines, the pending
# (partially echoed) line, mode, and byte counters. The hook owns
# byte assembly; this store is the reactive surface for the view.
# ═══════════════════════════════════════════════════════════════

MAX_LINES = 500
SIM_BANNER = [
  'OrniFlight CLI — simulation mode.'
  'Connect a controller for live access (help, version, status).'
].join ' '

useCliStore = create (set) ->
  lines: [{ text: SIM_BANNER, kind: 'info' }]
  pending: ''
  mode: 'sim'
  rxBytes: 0
  txBytes: 0
  reset: ->
    set {
      lines: [{ text: SIM_BANNER, kind: 'info' }]
      pending: ''
      rxBytes: 0
      txBytes: 0
    }
  setMode: (mode) -> set { mode }
  setPending: (pending) -> set { pending }
  appendLines: (entries) ->
    set (state) ->
      merged = state.lines.concat entries
      cap = if merged.length > MAX_LINES
        merged.slice -MAX_LINES
      else
        merged
      lines: cap
  # One set per device chunk: byte accounting, line appends, the
  # optional clear wipe and the pending tail settle in a single
  # store update — deterministic single re-render per chunk.
  applyChunk: (payload) ->
    set (state) ->
      appended = state.lines.concat payload.entries ? []
      capped = if appended.length > MAX_LINES
        appended.slice -MAX_LINES
      else
        appended
      lines: if payload.cleared then [] else capped
      pending: payload.pending ? ''
      rxBytes: state.rxBytes + (payload.rx ? 0)
  clearLines: -> set { lines: [], pending: '' }
  addRx: (count) -> set (state) -> rxBytes: state.rxBytes + count
  addTx: (count) -> set (state) -> txBytes: state.txBytes + count

export default useCliStore
export { MAX_LINES }