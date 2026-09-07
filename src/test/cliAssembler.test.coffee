import { describe, it, expect } from 'vitest'
import {
  assembleChunk, emptyState, MAX_LINE
} from '../hooks/cliAssembler.coffee'

describe 'cliAssembler', ->
  it 'accumulates partial chunks into the pending line', ->
    { state, flushes, cleared } = assembleChunk emptyState(), '# h'
    expect(state.line).toBe '# h'
    expect(flushes).toEqual []
    expect(cleared).toBe false

  it 'finalizes on CR and collapses the CRLF pair', ->
    { state, flushes } = assembleChunk emptyState(), 'abc\r\n# '
    expect(flushes).toEqual ['abc']
    expect(state.line).toBe '# '

  it 'collects multiple flushes from a single chunk', ->
    { flushes } = assembleChunk emptyState(), 'one\r\ntwo\r\n'
    expect(flushes).toEqual ['one', 'two']

  it 'suppresses empty lines', ->
    { flushes } = assembleChunk emptyState(), '\r\n\r\n'
    expect(flushes).toEqual []

  it 'collapses the firmware backspace sequence to one erase', ->
    { state, flushes } = assembleChunk emptyState(), 'abc\b \bd\r\n'
    expect(flushes).toEqual ['abd']
    expect(state.line).toBe ''

  it 'flags clear-screen sequences and strips all other ANSI', ->
    { state, flushes, cleared } =
      assembleChunk emptyState(), '\u001b[31mred\u001b[0m\r\n'
    expect(flushes).toEqual ['red']
    expect(cleared).toBe false
    result = assembleChunk state, '\u001b[2J\u001b[1;1H'
    expect(result.cleared).toBe true

  it 'carries escape state across chunk boundaries', ->
    first = assembleChunk emptyState(), '\u001b[3'
    expect(first.state.esc).toBe '\u001b[3'
    second = assembleChunk first.state, '1mred\r\n'
    expect(second.flushes).toEqual ['red']
    expect(second.cleared).toBe false

  it 'drops a lone ESC and reprocesses the following byte', ->
    { state, flushes } = assembleChunk emptyState(), '\u001bx\r\n'
    expect(flushes).toEqual ['x']
    expect(state.line).toBe ''

  it 'treats a bare LF as a line end when no CR precedes it', ->
    { flushes } = assembleChunk emptyState(), 'abc\ndef\n'
    expect(flushes).toEqual ['abc', 'def']

  it 'no-ops backspace on an empty line', ->
    { state, flushes } = assembleChunk emptyState(), '\b\b'
    expect(state.line).toBe ''
    expect(flushes).toEqual []

  it 'ignores a bare CR on an empty line and keeps assembling', ->
    { flushes } = assembleChunk emptyState(), '\rabc\r\n'
    expect(flushes).toEqual ['abc']

  it 'resets the pending line when a clear sequence interrupts it', ->
    { state, flushes, cleared } =
      assembleChunk emptyState(), 'foo\u001b[2Jbar\r\n'
    expect(cleared).toBe true
    expect(flushes).toEqual ['bar']
    expect(state.line).toBe ''

  it 'auto-flushes an overlong line at MAX_LINE instead of growing', ->
    { flushes, state } = assembleChunk emptyState(),
      ('x'.repeat MAX_LINE) + ('y'.repeat 10) + '\r\n'
    expect(flushes).toEqual ['x'.repeat(MAX_LINE), 'y'.repeat 10]
    expect(state.line).toBe ''

  it 'bounds a newline-free flood via MAX_LINE auto-wrap', ->
    flood = 'z'.repeat MAX_LINE * 2 + 7
    { flushes, state } = assembleChunk emptyState(), flood
    expect(flushes.length).toBe 2
    expect(flushes[0].length).toBe MAX_LINE
    expect(flushes[1].length).toBe MAX_LINE
    expect(state.line.length).toBe 7

  it 'renders OSC and BEL bytes as inert text, never as control', ->
    { flushes, state } = assembleChunk emptyState(),
      'a\u001b]0;evil\u0007b\r\n'
    expect(flushes).toEqual ['a]0;evil\u0007b']
    expect(state.line).toBe ''