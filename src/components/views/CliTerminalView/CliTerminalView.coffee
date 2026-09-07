import './CliTerminalView.sass'
import { useEffect, useRef, useState } from 'react'
import h from '../../../app/h.coffee'
import useCliSession from '../../../hooks/useCliSession.coffee'

# ═══════════════════════════════════════════════════════════════
# CliTerminalView — split-UI terminal. h() component (not CHAML):
# refs for autoscroll/focus and per-keystroke key handling need
# real lifecycle hooks. The input line echoes the draft locally;
# the device echoes into the scrollback — the proven legacy model.
# ═══════════════════════════════════════════════════════════════

CliTerminalView = ->
  cli = useCliSession()
  [command, setCommand] = useState ''
  [histIdx, setHistIdx] = useState -1
  draftRef = useRef ''
  scrollRef = useRef null
  inputRef = useRef null
  live = cli.mode == 'device'

  autoscroll = ->
    el = scrollRef.current
    el?.scrollTo? { top: el.scrollHeight }

  useEffect autoscroll, [cli.lines.length, cli.pending]
  useEffect ->
    inputRef.current?.focus()
    return
  , []

  recall = (delta) ->
    hist = cli.history()
    return unless hist.length
    if histIdx == -1
      draftRef.current = command
      next = if delta < 0 then hist.length - 1 else -1
      return if next == -1
      setHistIdx next
      setCommand hist[next]
    else
      next = histIdx + delta
      if next >= hist.length or next < 0
        setHistIdx -1
        setCommand draftRef.current
      else
        setHistIdx next
        setCommand hist[next]

  submit = ->
    cmd = command
    return unless cmd.trim()
    cli.submit cmd
    setCommand ''
    setHistIdx -1
    draftRef.current = ''
    inputRef.current?.focus()

  onKeyDown = (e) ->
    if e.key == 'l' and (e.ctrlKey or e.metaKey)
      e.preventDefault()
      cli.clear()
      return
    switch e.key
      when 'Enter'
        e.preventDefault()
        submit()
      when 'ArrowUp', 'ArrowDown'
        e.preventDefault()
        recall (if e.key == 'ArrowUp' then -1 else 1)
      when 'Tab'
        e.preventDefault()
        completion = await cli.complete command
        setCommand completion if completion

  h 'main', { className: 'cli-view', 'aria-labelledby': 'cli-title' },
    h 'header', { className: 'cli-head' },
      h 'div', { className: 'cli-title-block' },
        h 'h1', { id: 'cli-title', className: 'cli-title' }, 'CLI Terminal'
        h 'p', { className: 'cli-subtitle' },
          'Text console of the flight controller'
      h 'div', { className: 'cli-actions' },
        h 'span', {
          className: "cli-badge #{if live then 'cli-badge-live' else ''}"
          role: 'status'
        }, if live then '● LIVE' else '◌ SIMULATION'
        h 'button', {
          className: 'cli-btn'
          type: 'button'
          hidden: live
          disabled: not cli.canEnter
          onClick: -> cli.enter()
        }, 'Open device CLI'
        h 'button', {
          className: 'cli-btn cli-btn-exit'
          type: 'button'
          hidden: not live
          onClick: -> cli.exit()
        }, 'Exit CLI'
        h 'button', {
          className: 'cli-btn'
          type: 'button'
          onClick: -> cli.clear()
        }, 'Clear'
    h 'div', {
      className: 'cli-screen'
      ref: scrollRef
      role: 'log'
      'aria-live': 'polite'
      'aria-label': 'CLI output'
      onMouseDown: -> inputRef.current?.focus()
    },
      cli.lines.map (line, i) ->
        h 'div', { className: "cli-line cli-#{line.kind}", key: i }, line.text
      if cli.pending
        h 'div', { className: 'cli-line cli-pending' }, cli.pending
      else if not cli.lines.length
        h 'div', { className: 'cli-line cli-muted' }, '─ idle ─'
    h 'form', {
      className: 'cli-input-row'
      onSubmit: (e) ->
        e.preventDefault()
        submit()
    },
      h 'span', { className: 'cli-prompt', 'aria-hidden': 'true' },
        if live then '#' else '❯'
      h 'input', {
        className: 'cli-input'
        ref: inputRef
        value: command
        placeholder: if live
          'type a command — tab completes'
        else
          'simulation — try help, version, status'
        autoComplete: 'off'
        spellCheck: 'false'
        'aria-label': 'CLI command input'
        onChange: (e) -> setCommand e.target.value
        onKeyDown: onKeyDown
      }
      h 'span', { className: 'cli-counters' },
        "RX #{cli.rxBytes} · TX #{cli.txBytes}"

export default CliTerminalView