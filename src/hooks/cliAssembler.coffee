# ═══════════════════════════════════════════════════════════════
# cliAssembler — pure line-discipline state machine for the raw
# CLI byte stream. Mirrors the firmware's cliProcess semantics:
#   \b           → erase one character ("\010 \010" collapses to it)
#   \r / \n      → finalize the line (a CRLF pair finalizes once)
#   ESC[2J / ESC[1;1H → clear screen; every other ANSI strips
# No `this`, no side effects — `state` flows in, `state` flows out.
# ═══════════════════════════════════════════════════════════════

# Hard ceiling for the partially echoed line. A hostile or broken
# device flooding bytes without a line end cannot grow the pending
# buffer past this — the overlong line finalizes as-is and the byte
# starts a fresh one (terminal auto-wrap semantics).
MAX_LINE = 4096

# Discipline state: the partially echoed line, the escape sequence
# being accumulated (ESC, then ESC[ + parameter bytes), and the CR
# flag that suppresses the LF half of a CRLF pair.
emptyState = -> { line: '', esc: null, cr: false }

# One byte through the discipline. Returns the next state plus the
# events it produced: a finalized line (or null) and a clear-screen
# flag. A lone ESC or a malformed sequence is dropped and the byte
# that follows it is reprocessed through the plain path.
assembleByte = (state, ch) ->
  return inEscape state, ch if state.esc?
  switch ch
    when '\u001b'
      nextState: { line: state.line, esc: ch, cr: false }
      flush: null
      cleared: false
    when '\b'
      nextState: { line: state.line.slice 0, -1, esc: null, cr: false }
      flush: null
      cleared: false
    when '\r'
      nextState: { line: '', esc: null, cr: true }
      flush: if state.line then state.line else null
      cleared: false
    when '\n'
      if state.cr and state.line == ''
        nextState: { line: '', esc: null, cr: false }
        flush: null
        cleared: false
      else
        nextState: { line: '', esc: null, cr: false }
        flush: if state.line then state.line else null
        cleared: false
    else
      next = state.line + ch
      if next.length > MAX_LINE
        nextState: { line: ch, esc: null, cr: false }
        flush: state.line
        cleared: false
      else
        nextState: { line: next, esc: null, cr: false }
        flush: null
        cleared: false

inEscape = (state, ch) ->
  esc = state.esc
  if esc == '\u001b'
    if ch == '['
      nextState: { line: state.line, esc: esc + ch, cr: false }
      flush: null
      cleared: false
    else
      assembleByte { line: state.line, esc: null, cr: false }, ch
  else
    code = ch.charCodeAt 0
    if 0x20 <= code <= 0x3f
      nextState: { line: state.line, esc: esc + ch, cr: false }
      flush: null
      cleared: false
    else if 0x40 <= code <= 0x7e
      seq = esc + ch
      isClear = seq.includes('2J') or seq.includes('1;1H')
      nextLine = if isClear then '' else state.line
      nextState: { line: nextLine, esc: null, cr: false }
      flush: null
      cleared: isClear
    else
      assembleByte { line: state.line, esc: null, cr: false }, ch

# Folds a whole decoded chunk through the discipline. Multiple
# lines can finalize within one chunk, so the events are lists:
# flushes in wire order plus one clear flag if any sequence hit.
assembleChunk = (state, chunk) ->
  result = { state: state, flushes: [], cleared: false }
  for ch in chunk
    step = assembleByte result.state, ch
    result.state = step.nextState
    result.flushes.push step.flush if step.flush?
    result.cleared = result.cleared or step.cleared
  result

export { assembleChunk, assembleByte, emptyState, MAX_LINE }