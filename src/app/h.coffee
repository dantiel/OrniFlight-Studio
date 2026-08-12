import { createElement, Fragment } from 'react'

# ═══════════════════════════════════════════════════════════════
# Hyperscript helper — concise React element creation in CoffeeScript.
# Usage:
#   h 'div', { className: 'box' },
#     h 'span', null, 'Hello'
#     h OtherComponent, { prop: value }
# ═══════════════════════════════════════════════════════════════

h = (tag, attrs, children...) ->
  # Flatten nested arrays into a single-level array
  flat = []
  walk = (c) ->
    if Array.isArray c
      walk(x) for x in c
    else if c? and c != false
      flat.push c
    return
  walk children
  createElement tag, attrs, flat...

export default h
export { h, Fragment }