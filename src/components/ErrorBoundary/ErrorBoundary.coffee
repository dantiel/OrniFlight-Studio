###
# ORNIFLIGHT STUDIO — Error Boundary
#
# Architectural role: crash containment.
# Catches render errors from child components, prevents
# one servo glitch from taking down the entire dashboard.
#
# Pattern: React Class Component (error boundaries require
# componentDidCatch — no hook equivalent in React 18).
#
# Usage (in main.coffee):
#   root.render h ErrorBoundary, null, h App, null
###
import { Component } from 'react'
import h from '../../app/h.coffee'

class ErrorBoundary extends Component
  constructor: (props) ->
    super props
    @state = hasError: false, error: null, errorInfo: null

  componentDidCatch: (error, errorInfo) ->
    @setState { hasError: true, error, errorInfo }
    console.error '[OrniFlight] Boundary caught:', error, errorInfo

  reset: =>
    @setState { hasError: false, error: null, errorInfo: null }

  render: ->
    if @state.hasError
      h 'div',
        style:
          display: 'flex'
          flexDirection: 'column'
          alignItems: 'center'
          justifyContent: 'center'
          height: '100vh'
          padding: '2rem'
          fontFamily: 'Orbitron, monospace'
          color: 'var(--of-text)'
          background: 'var(--of-bg)'
          textAlign: 'center'
        h 'h1',
          style:
            fontSize: '2rem'
            marginBottom: '1rem'
            color: 'var(--of-accent)'
          'Æther Fracture'
        h 'p',
          style: marginBottom: '0.5rem', color: 'var(--of-text-muted)'
          @state.error?.message || 'Unknown error'
        h 'pre',
          style:
            maxWidth: '600px'
            overflow: 'auto'
            fontSize: '0.75rem'
            padding: '1rem'
            background: 'var(--of-surface)'
            borderRadius: '8px'
            color: 'var(--of-text-muted)'
            marginBottom: '2rem'
            whiteSpace: 'pre-wrap'
          @state.error?.stack?.split('\n').slice(0, 8).join('\n') || ''
        h 'button',
          onClick: @reset
          style:
            padding: '0.75rem 2rem'
            fontSize: '1rem'
            fontFamily: 'Orbitron, monospace'
            background: 'var(--of-accent)'
            color: '#000'
            border: 'none'
            borderRadius: '6px'
            cursor: 'pointer'
          'Reconstitute'
    else
      @props.children

export default ErrorBoundary