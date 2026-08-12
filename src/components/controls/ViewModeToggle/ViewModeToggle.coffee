import './ViewModeToggle.sass'
import { createElement } from 'react'

# ═══════════════════════════════════════════════════════════════
# ViewModeToggle — layout modes
# Horizon (full 3D) · Nest (split) · Roost (compact)
# ═══════════════════════════════════════════════════════════════

MODES = [
  {
    id: 'full', label: 'Horizon', icon: '\u25A3',
    title: 'Horizon — bird only, full viewport'
  }
  {
    id: 'split', label: 'Nest', icon: '\u25A7',
    title: 'Nest — bird + inspector side by side'
  }
  {
    id: 'compact', label: 'Roost', icon: '\u25B1',
    title: 'Roost — compact bird + expanded telemetry'
  }
]

ViewModeToggle = ({ mode, onModeChange }) ->
  createElement 'div', { className: 'viewmode-toggle' },
    MODES.map (m) ->
      cls = 'viewmode-btn'
      cls += ' active' if m.id is mode
      createElement 'button',
        key: m.id
        className: cls
        onClick: -> onModeChange m.id
        title: m.title
        createElement('span', { className: 'vm-icon' }, m.icon),
        createElement('span', { className: 'vm-label' }, m.label)

export default ViewModeToggle