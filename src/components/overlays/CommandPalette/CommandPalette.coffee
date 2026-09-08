import './CommandPalette.sass'
import { useEffect, useMemo, useRef, useState } from 'react'
import { AnimatePresence, motion } from 'framer-motion'
import { useNavigate } from 'react-router-dom'
import { getActor } from '../../../hooks/useConnection.coffee'
import h from '../../../app/h.coffee'

ROUTES = [
  ['Device', '/device', '◫']
  ['Airframe', '/airframe', '⌁']
  ['Flight Control', '/control', '△']
  ['Receiver', '/receiver', '⇄']
  ['Power', '/power', 'ϟ']
  ['Sensors', '/sensors', '◎']
  ['Safety', '/safety', '◇']
  ['OSD', '/osd', '⌗']
  ['VTX', '/vtx', '≋']
  ['Ports', '/ports', '⇶']
  ['Data', '/data', '▦']
  ['Flash Firmware', '/flash', '↯']
  ['CLI Terminal', '/cli', '❯']
]

CommandPalette = ->
  [open, setOpen] = useState false
  [query, setQuery] = useState ''
  [active, setActive] = useState 0
  inputRef = useRef null
  navigate = useNavigate()
  commands = useMemo ->
    routeItems = ROUTES.map ([label, path, icon]) ->
      { label, icon, hint: path, run: (-> navigate path) }
    routeItems.concat [
      { label: 'Connect device', icon: '◎', hint: 'connection', run: (-> getActor().send { type: 'CONNECT' }) }
      { label: 'Disconnect device', icon: '○', hint: 'connection', run: (-> getActor().send { type: 'DISCONNECT' }) }
      { label: 'Toggle theme', icon: '◐', hint: 'appearance', run: ->
          root = document.documentElement
          root.dataset.theme = if root.dataset.theme == 'light' then 'dark' else 'light'
      }
    ]
  , [navigate]
  filtered = commands.filter (cmd) -> "#{cmd.label} #{cmd.hint}".toLowerCase().includes query.toLowerCase()
  run = (cmd) ->
    cmd?.run?()
    setOpen false
    setQuery ''

  useEffect ->
    handler = (e) ->
      if (e.metaKey || e.ctrlKey) && e.key.toLowerCase() == 'k'
        e.preventDefault()
        setOpen (v) -> !v
      if e.key == 'Escape' then setOpen false
    launcher = -> setOpen true
    window.addEventListener 'keydown', handler
    window.addEventListener 'orniflight:commands', launcher
    ->
      window.removeEventListener 'keydown', handler
      window.removeEventListener 'orniflight:commands', launcher
  , []
  useEffect ->
    if open then requestAnimationFrame -> inputRef.current?.focus()
    setActive 0
  , [open, query]

  h AnimatePresence, null,
    if open then h motion.div,
      className: 'command-backdrop'
      key: 'palette'
      initial: { opacity: 0 }
      animate: { opacity: 1 }
      exit: { opacity: 0 }
      onMouseDown: (e) -> setOpen(false) if e.target == e.currentTarget
    , h motion.div,
        className: 'command-palette'
        role: 'dialog'
        'aria-modal': true
        'aria-label': 'Studio commands'
        initial: { opacity: 0, scale: 0.96, y: -8 }
        animate: { opacity: 1, scale: 1, y: 0 }
        exit: { opacity: 0, scale: 0.97, y: -5 }
      ,
        h 'div', { className: 'command-search' },
          h 'span', null, '⌘'
          h 'input',
            ref: inputRef
            value: query
            placeholder: 'Navigate or run a command…'
            onChange: (e) -> setQuery e.target.value
            onKeyDown: (e) ->
              if e.key == 'ArrowDown'
                e.preventDefault(); setActive (i) -> Math.min(filtered.length - 1, i + 1)
              if e.key == 'ArrowUp'
                e.preventDefault(); setActive (i) -> Math.max(0, i - 1)
              if e.key == 'Enter'
                e.preventDefault(); run filtered[active]
          h 'kbd', null, 'ESC'
        h 'div', { className: 'command-results', role: 'listbox' },
          if filtered.length then filtered.map (cmd, i) ->
            h 'button',
              className: if i == active then 'active' else ''
              key: cmd.label
              type: 'button'
              role: 'option'
              'aria-selected': i == active
              onMouseEnter: (-> setActive i)
              onClick: (-> run cmd)
            , h('span', { className: 'command-icon' }, cmd.icon), h('span', null, cmd.label), h('small', null, cmd.hint)
          else h 'p', { className: 'command-empty' }, 'No matching command'
        h 'footer', null, '↑↓ select · ↵ run · Ctrl/⌘ K toggle'

export default CommandPalette