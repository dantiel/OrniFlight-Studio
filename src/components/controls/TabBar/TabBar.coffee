import './TabBar.sass'
import { createElement } from 'react'
import { classNames as cx } from '../../../lib/essential.coffee'

# ═══════════════════════════════════════════════════════════════
# TabBar — Flight dynamics sub-tabs
# Tabs: Tuning, Mixer, Response
# ═══════════════════════════════════════════════════════════════

TABS = [
  { id: 'servos',   label: 'Tuning',   icon: '\u25C7' }  # ◇
  { id: 'pid',      label: 'PID',      icon: '\u25B3' }  # △
  { id: 'ondas',    label: 'Mixer',    icon: '\u223F' }  # ∿
  { id: 'sensors',  label: 'Response', icon: '\u25C9' }  # ◎
]

TabBar = ({ activeTab, onTabChange }) ->
  createElement 'div', { className: 'tab-bar' },
    TABS.map (tab) ->
      createElement 'button',
        key: tab.id
        className: cx 'tab-bar-item', ['active', tab.id is activeTab]
        onClick: -> onTabChange tab.id
        title: tab.label
        createElement('span', { className: 'tab-icon' }, tab.icon),
        createElement('span', { className: 'tab-label' }, tab.label)

export default TabBar
