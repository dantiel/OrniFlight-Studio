import './TabBar.sass'
import { createElement } from 'react'
import { classNames as cx } from '../../../lib/essential.coffee'
import { useI18n } from '../../../i18n/index.coffee'

# ═══════════════════════════════════════════════════════════════
# TabBar — Flight dynamics sub-tabs
# Tabs: Tuning, Mixer, Response
# ═══════════════════════════════════════════════════════════════

TABS = [
  { id: 'servos',   labelKey: 'flight.tuning',    icon: '\u25C7' }  # ◇
  { id: 'pid',      labelKey: 'flight.pid',       icon: '\u25B3' }  # △
  { id: 'ondas',    labelKey: 'flight.mixer',     icon: '\u223F' }  # ∿
  { id: 'sensors',  labelKey: 'flight.response',  icon: '\u25C9' }  # ◎
]

TabBar = ({ activeTab, onTabChange }) ->
  { t } = useI18n()
  createElement 'div', { className: 'tab-bar' },
    TABS.map (tab) ->
      createElement 'button',
        key: tab.id
        className: cx 'tab-bar-item', ['active', tab.id is activeTab]
        onClick: -> onTabChange tab.id
        title: t(tab.labelKey)
        createElement('span', { className: 'tab-icon' }, tab.icon),
        createElement('span', { className: 'tab-label' }, t(tab.labelKey))

export default TabBar
