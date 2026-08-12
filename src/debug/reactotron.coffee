###
# ORNIFLIGHT STUDIO — Reactotron Debug Bridge
#
# Architectural role: development-time introspection layer.
# Pipes Zustand stores, XState machines, and custom commands
# into the Reactotron desktop client for real-time inspection.
#
# This entire module is tree-shaken in production builds
# via Vite's static replacement of import.meta.env.DEV.
#
# Reactotron desktop app: https://github.com/infinitered/reactotron
#
# Pattern: attach externally — stores and machines stay pure.
#   Reactotron subscribes to Zustand stores and XState actors
#   from the outside. No component or store imports Reactotron.
###
import Reactotron, { trackGlobalErrors } from 'reactotron-react-js'

# ═══════════════════════════════════════════════════════════════
# Singleton — configured once, shared across all bridges
# ═══════════════════════════════════════════════════════════════

isConnected = false

if typeof window != 'undefined'
  Reactotron
    .configure name: 'OrniFlight Studio'
    .use trackGlobalErrors()
    .connect()

  isConnected = true

# ═══════════════════════════════════════════════════════════════
# Store attachment — Zustand → Reactotron display
#
# Usage: attachStore 'AppStore', useAppStore
# Each state change appears as a named display entry in the
# Reactotron timeline. The `preview` gives a one-line summary.
# ═══════════════════════════════════════════════════════════════

attachStore = (name, store) ->
  return unless isConnected

  Reactotron.display
    name: "📦 #{name}"
    value: store.getState()
    preview: "#{name} Initialized"

  store.subscribe (state) ->
    Reactotron.display
      name: "📦 #{name}"
      value: state
      preview: summarizeStore name, state

# ═══════════════════════════════════════════════════════════════
# Machine attachment — XState → Reactotron display
#
# Usage: attachMachine 'Connection', actor
# Every state transition appears as a display entry showing
# the previous state → new state transition with context.
# ═══════════════════════════════════════════════════════════════

attachMachine = (name, actor) ->
  return unless isConnected

  prev = actor.getSnapshot()

  Reactotron.display
    name: "⚙️ #{name}"
    value:
      state:   prev?.value
      context: prev?.context
    preview: "Initial: #{prev?.value || '—'}"

  actor.subscribe (snap) ->
    Reactotron.display
      name: "⚙️ #{name}"
      value:
        from:    prev?.value
        to:      snap.value
        context: snap.context
      preview: "#{prev?.value || '—'} → #{snap.value || '—'}"

    prev = snap

# ═══════════════════════════════════════════════════════════════
# Custom Commands — simulation control from Reactotron
# ═══════════════════════════════════════════════════════════════

_commandHandlers = {}

registerCommand = (command, title, handler) ->
  _commandHandlers[command] = handler
  return unless isConnected

  Reactotron.onCustomCommand { command, title, handler }

export { attachStore, attachMachine, registerCommand }
export default Reactotron

# ═══════════════════════════════════════════════════════════════
# Internal helpers
# ═══════════════════════════════════════════════════════════════

summarizeStore = (name, state) ->
  switch name
    when 'AppStore'
      "#{state.configView || '—'} · #{state.activeTab || '—'} · #{state.connectionState || 'disconnected'}"
    when 'TelemetryStore'
      "t=#{state.t || 0} · roll=#{state.gyro?.roll?.toFixed? 2 || state.gyro?.roll || 0} · ring=#{state.ringIndex || 0}"
    else
      JSON.stringify(state)?.slice 0, 80
