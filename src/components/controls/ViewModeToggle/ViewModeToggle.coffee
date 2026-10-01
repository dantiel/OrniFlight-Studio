import './ViewModeToggle.sass'
import { createElement } from 'react'
import { classNames as cx } from '../../../lib/essential.coffee'
import Icon from '../../primitives/Icon/Icon.coffee'

# ═══════════════════════════════════════════════════════════════
# ViewModeToggle — layout modes
# Horizon (full 3D) · Nest (split) · Roost (compact)
# ═══════════════════════════════════════════════════════════════

MODES = [
  {
    id: 'full', label: 'Horizon', icon: 'square',
    title: 'Horizon — bird only, full viewport'
  }
  {
    id: 'split', label: 'Nest', icon: 'columns',
    title: 'Nest — bird + inspector side by side'
  }
  {
    id: 'compact', label: 'Roost', icon: 'rows',
    title: 'Roost — compact bird + expanded telemetry'
  }
]

ViewModeToggle = ({ mode, onModeChange }) ->
  createElement 'div', { className: 'viewmode-toggle' },
    MODES.map (m) ->
      createElement 'button',
        key: m.id
        className: cx 'viewmode-btn', ['active', m.id is mode]
        onClick: -> onModeChange m.id
        title: m.title
        createElement(Icon, { name: m.icon, className: 'vm-icon', size: 13 }),
        createElement('span', { className: 'vm-label' }, m.label)

export default ViewModeToggle