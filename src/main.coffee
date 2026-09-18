import { createRoot } from 'react-dom/client'
import { HashRouter } from 'react-router-dom'
import h from './app/h.coffee'
import App from './app/App.chaml'
import ErrorBoundary from './components/ErrorBoundary/ErrorBoundary.coffee'
import './styles/main.sass'

# ═══════════════════════════════════════════════════════
# Reactotron — dev-only introspection layer
# Tree-shaken in production via import.meta.env.DEV
# ═══════════════════════════════════════════════════════
if import.meta.env.DEV
  import('./debug/bridge.coffee').catch -> null

rootEl = document.getElementById 'root'
root = createRoot rootEl
root.render h HashRouter, null,
  h ErrorBoundary, null,
    h App, null