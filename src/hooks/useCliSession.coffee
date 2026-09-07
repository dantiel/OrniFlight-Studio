import { useCallback, useEffect, useRef } from 'react'
import useCliStore from '../stores/useCliStore.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'
import {
  enterCli, leaveCli, writeCliBytes
} from './useFirmwareConnection.coffee'
import { assembleChunk, emptyState } from './cliAssembler.coffee'

# ═══════════════════════════════════════════════════════════════
# useCliSession — polymorphic CLI session. sim: local echo plus
# canned responses. device: takeover bridge (enterCli) plus the
# pure cliAssembler line discipline (echo, CRLF collapse, ANSI
# clear). Every device echo lands in `pending` until a line ends —
# live echo without local duplication.
# ═══════════════════════════════════════════════════════════════

SIM_COMMAND_NAMES = ['help', 'version', 'status', 'exit', 'clear']

SIM_HELP = [
  'available commands:'
  '  help      show this text'
  '  version   firmware version'
  '  status    system status'
  '  exit      leave CLI'
  '  clear     clear screen'
]

SIM_VERSION = 'OrniFlight 1.0.0 (simulation)'

SIM_STATUS = [
  'System Uptime: 0 s'
  'Voltage: 0 * 0.1V (0S battery - NOT PRESENT)'
  'CPU Clock: 72MHz'
  'I2C Errors: 0'
  'Arming disable flags: 0x0'
]

classifyLine = (text) ->
  if text.startsWith '###' then 'error'
  else if text.startsWith '#' then 'prompt'
  else 'out'

useCliSession = (deps = {}) ->
  enterDevice = deps.enterDevice ? enterCli
  writeDevice = deps.writeDevice ? writeCliBytes
  leaveDevice = deps.leaveDevice ? leaveCli

  lines = useCliStore (s) -> s.lines
  pending = useCliStore (s) -> s.pending
  mode = useCliStore (s) -> s.mode
  rxBytes = useCliStore (s) -> s.rxBytes
  txBytes = useCliStore (s) -> s.txBytes
  source = useDeviceStore (s) -> s.source

  decoderRef = useRef null
  assemblerRef = useRef emptyState()
  historyRef = useRef []
  ownedRef = useRef false

  processBytes = useCallback (bytes) ->
    return unless bytes?.length
    useCliStore.getState().addRx bytes.length
    decoder = decoderRef.current ?= new TextDecoder 'utf-8'
    text = decoder.decode bytes, { stream: true }
    { state, flushes, cleared } = assembleChunk assemblerRef.current, text
    assemblerRef.current = state
    # Wire order: lines finalize before the clear sequence wipes them.
    for line in flushes
      useCliStore.getState().appendLines [
        { text: line, kind: classifyLine line }
      ]
    useCliStore.getState().clearLines() if cleared
    useCliStore.getState().setPending state.line
  , []

  runSimCommand = (command) ->
    cmd = command.trim()
    return unless cmd
    store = useCliStore.getState()
    store.addTx command.length + 1
    store.appendLines [{ text: "# #{cmd}", kind: 'in' }]
    switch cmd
      when 'help'
        store.appendLines SIM_HELP.map (t) -> { text: t, kind: 'out' }
      when 'version'
        store.appendLines [{ text: SIM_VERSION, kind: 'out' }]
      when 'status'
        store.appendLines SIM_STATUS.map (t) -> { text: t, kind: 'out' }
      when 'clear'
        store.clearLines()
      when 'exit'
        store.appendLines [{
          text: 'no device attached — already in simulation'
          kind: 'info'
        }]
      else
        store.appendLines [{
          text: "###ERROR: unknown command: #{cmd}"
          kind: 'error'
        }]

  enter = useCallback ->
    store = useCliStore.getState()
    return false if store.mode == 'device'
    assemblerRef.current = emptyState()
    unless useDeviceStore.getState().source == 'device'
      store.appendLines [{
        text: '###ERROR: no flight controller connected'
        kind: 'error'
      }]
      return false
    try
      await enterDevice (bytes) -> processBytes bytes
      useCliStore.getState().setMode 'device'
      ownedRef.current = true
      true
    catch error
      useCliStore.getState().appendLines [{
        text: "###ERROR: #{error?.message or error}"
        kind: 'error'
      }]
      false
  , [enterDevice, processBytes]

  submit = (command) ->
    store = useCliStore.getState()
    cmd = command.trim()
    return unless cmd
    pushHistory cmd
    if store.mode == 'sim'
      runSimCommand command
      return
    store.addTx command.length + 1
    try
      await writeDevice new TextEncoder().encode "#{cmd}\r"
    catch error
      message = "###ERROR: CLI write failed: #{error?.message or error}"
      foldToSim message, 'error'

  pushHistory = (cmd) ->
    hist = historyRef.current
    hist.push cmd unless hist[hist.length - 1] == cmd

  # Folds a failed device-mode write back into sim, restoring MSP
  # routing. Guards against unhandled rejections when the transport
  # drops mid-command — the session must settle before the await.
  foldToSim = (message = null, kind = 'info') ->
    ownedRef.current = false
    assemblerRef.current = emptyState()
    store = useCliStore.getState()
    store.setMode 'sim'
    store.setPending ''
    store.appendLines [{ text: message, kind }] if message
    try
      await leaveDevice()
    catch error then null

  # Completes the draft: in device mode the firmware completes on
  # '\t'; in sim mode known command names are matched locally.
  complete = (draft) ->
    store = useCliStore.getState()
    if store.mode == 'device'
      store.addTx 1
      try
        await writeDevice new TextEncoder().encode '\t'
      catch error
        message = "###ERROR: CLI write failed: #{error?.message or error}"
        foldToSim message, 'error'
      return null
    trimmed = draft.trim()
    return null unless trimmed
    for name in SIM_COMMAND_NAMES
      if name.startsWith(trimmed) and name != trimmed
        return name
    null

  exit = ->
    store = useCliStore.getState()
    if store.mode == 'sim'
      runSimCommand 'exit'
      return
    store.appendLines [{ text: 'exit', kind: 'in' }]
    store.addTx 5
    try
      await writeDevice new TextEncoder().encode 'exit\r'
    catch error
      message = "###ERROR: CLI write failed: #{error?.message or error}"
      foldToSim message, 'error'
      return
    # Firmware reboots on exit — the disconnect routes through
    # failConnection. The timer is a grace fallback for targets
    # that stay alive (mock transports, lab rigs). The fold-back
    # is synchronous: the store must settle before the await.
    setTimeout ->
      if useCliStore.getState().mode == 'device'
        assemblerRef.current = emptyState()
        store = useCliStore.getState()
        store.setPending ''
        store.setMode 'sim'
        ownedRef.current = false
        try
          await leaveDevice()
        catch error then null
    , 2000

  clear = -> useCliStore.getState().clearLines()

  # The controller rebooting (CLI exit) or failing lifts the
  # device source — fold the session back into sim mode.
  useEffect ->
    if ownedRef.current and source != 'device'
      ownedRef.current = false
      assemblerRef.current = emptyState()
      store = useCliStore.getState()
      store.setMode 'sim'
      store.setPending ''
      store.appendLines [{
        text: '── connection closed by controller ──'
        kind: 'info'
      }]
  , [source]

  # Leaving the view mid-session restores MSP telemetry.
  restoreOnUnmount = ->
    if ownedRef.current
      ownedRef.current = false
      assemblerRef.current = emptyState()
      store = useCliStore.getState()
      store.setMode 'sim'
      store.setPending ''
      try
        await leaveDevice()
      catch error then null

  useEffect ->
    restoreOnUnmount
  , [leaveDevice]

  {
    lines, pending, mode, rxBytes, txBytes
    canEnter: mode == 'sim' and source == 'device'
    enter, exit, submit, complete, clear
    history: -> historyRef.current.slice()
  }

export default useCliSession
export { SIM_COMMAND_NAMES, SIM_HELP, SIM_VERSION, SIM_STATUS, classifyLine }