import './SystemShell.sass'
import h from '../../../app/h.coffee'
import { Outlet, NavLink, useLocation } from 'react-router-dom'
import Icon from '../../primitives/Icon/Icon.coffee'
import Section from '../../layout/Section/Section.coffee'
import { SUBTABS, activeSubtabForPath } from '../../../lib/navigation.coffee'
import { useI18n } from '../../../i18n/index.coffee'
import useFirmwareConnection from '../../../hooks/useFirmwareConnection.coffee'
import useDeviceStore from '../../../stores/useDeviceStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'

# macOS-style three-pane shell for the System module:
#   left  = navigation source list (the module's sub-views)
#   center= the active sub-view (rendered through <Outlet/>)
#   right = contextual inspector (a different, minor section)
SystemShell = ->
  location = useLocation()
  { t } = useI18n()
  conn = useFirmwareConnection()
  identity = useDeviceStore (state) -> state.identity
  status = useDeviceStore (state) -> state.status
  tele = useTelemetryStore()
  active = activeSubtabForPath location.pathname
  hardware = conn.connected and conn.source == 'device'

  navItems = (SUBTABS.system ? []).map ([path, label, icon]) ->
    navClass = ({ isActive }) ->
      "system-nav-item#{if isActive then ' is-active' else ''}"
    h NavLink,
      key: path
      to: path
      className: navClass
    ,
      h Icon, { name: icon, size: 15, strokeWidth: 1.6 }
      h 'span', { className: 'system-nav-label' }, t(label)

  connLabel = if hardware then t('conn.deviceConnected') else t('conn.offlineProfile')
  connClass = "system-conn#{if hardware then ' is-online' else ''}"
  sourceLabel = if hardware then t('conn.controller') else t('conn.simulation')
  firmwareLabel =
    if identity then "#{identity.variant} #{identity.firmware?.version or ''}" else ''
  targetLabel =
    if identity
      identity.board?.boardName or identity.board?.targetName or '—'
    else
      '—'
  armClass = if status?.armed then 'system-armed' else 'system-safe'
  armLabel = if status?.armed then t('conn.armed') else t('conn.disarmed')

  h 'div', { className: 'system-shell' },
    h 'aside', { className: 'system-sidebar', 'aria-label': t('shell.system') },
      h 'div', { className: 'system-sidebar-head' },
        h Icon, { name: 'grid', size: 15, strokeWidth: 1.7 }
        h 'span', null, t('shell.system')
      h 'nav', { className: 'system-nav' }, navItems
    h 'main', { className: 'system-content' },
      h Outlet, null
    h 'aside', { className: 'system-inspector', 'aria-label': t('shell.inspector') },
      h Section, { heading: t('shell.module') },
        h 'div', { className: 'system-inspector-row' },
          h Icon, { name: active.icon, size: 14, strokeWidth: 1.6 }
          h 'span', null, t(active.label)
      h Section, { heading: t('shell.connection') },
        h 'div', { className: connClass },
          h 'span', { className: 'system-conn-dot' }
          h 'span', null, connLabel
        h 'div', { className: 'system-inspector-row' },
          h 'span', { className: 'system-inspector-key' }, t('shell.source')
          h 'span', null, sourceLabel
      if identity
        h Section, { heading: t('shell.device') },
          h 'div', { className: 'system-inspector-row' },
            h 'span', { className: 'system-inspector-key' }, t('shell.firmware')
            h 'span', null, firmwareLabel
          h 'div', { className: 'system-inspector-row' },
            h 'span', { className: 'system-inspector-key' }, t('shell.target')
            h 'span', null, targetLabel
          h 'div', { className: 'system-inspector-row' },
            h 'span', { className: 'system-inspector-key' }, t('shell.status')
            h 'span', { className: armClass }, armLabel
      h Section, { heading: t('shell.live') },
        h 'div', { className: 'system-inspector-row' },
          h 'span', { className: 'system-inspector-key' }, t('shell.voltage')
          h 'span', null, "#{Number(tele.batteryVoltage or 0).toFixed(1)} V"
        h 'div', { className: 'system-inspector-row' },
          h 'span', { className: 'system-inspector-key' }, t('shell.cpu')
          h 'span', null, "#{status?.cpuLoad or 0}%"

export default SystemShell
