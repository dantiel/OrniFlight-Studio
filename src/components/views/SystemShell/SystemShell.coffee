import './SystemShell.sass'
import h from '../../../app/h.coffee'
import { Outlet, NavLink, useLocation } from 'react-router-dom'
import Icon from '../../primitives/Icon/Icon.coffee'
import Section from '../../layout/Section/Section.coffee'
import { SUBTABS, activeSubtabForPath } from '../../../lib/navigation.coffee'
import useFirmwareConnection from '../../../hooks/useFirmwareConnection.coffee'
import useDeviceStore from '../../../stores/useDeviceStore.coffee'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'

# macOS-style three-pane shell for the System module:
#   left  = navigation source list (the module's sub-views)
#   center= the active sub-view (rendered through <Outlet/>)
#   right = contextual inspector (a different, minor section)
SystemShell = ->
  location = useLocation()
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
      h 'span', { className: 'system-nav-label' }, label

  connLabel = if hardware then 'DEVICE CONNECTED' else 'OFFLINE PROFILE'
  connClass = "system-conn#{if hardware then ' is-online' else ''}"
  sourceLabel = if hardware then 'Controller' else 'Simulation'
  firmwareLabel =
    if identity then "#{identity.variant} #{identity.firmware?.version or ''}" else ''
  targetLabel =
    if identity
      identity.board?.boardName or identity.board?.targetName or '—'
    else
      '—'
  armClass = if status?.armed then 'system-armed' else 'system-safe'
  armLabel = if status?.armed then 'ARMED' else 'DISARMED'

  h 'div', { className: 'system-shell' },
    h 'aside', { className: 'system-sidebar', 'aria-label': 'System' },
      h 'div', { className: 'system-sidebar-head' },
        h Icon, { name: 'grid', size: 15, strokeWidth: 1.7 }
        h 'span', null, 'System'
      h 'nav', { className: 'system-nav' }, navItems
    h 'main', { className: 'system-content' },
      h Outlet, null
    h 'aside', { className: 'system-inspector', 'aria-label': 'Inspector' },
      h Section, { heading: 'Modul' },
        h 'div', { className: 'system-inspector-row' },
          h Icon, { name: active.icon, size: 14, strokeWidth: 1.6 }
          h 'span', null, active.label
      h Section, { heading: 'Verbindung' },
        h 'div', { className: connClass },
          h 'span', { className: 'system-conn-dot' }
          h 'span', null, connLabel
        h 'div', { className: 'system-inspector-row' },
          h 'span', { className: 'system-inspector-key' }, 'Source'
          h 'span', null, sourceLabel
      if identity
        h Section, { heading: 'Gerät' },
          h 'div', { className: 'system-inspector-row' },
            h 'span', { className: 'system-inspector-key' }, 'Firmware'
            h 'span', null, firmwareLabel
          h 'div', { className: 'system-inspector-row' },
            h 'span', { className: 'system-inspector-key' }, 'Target'
            h 'span', null, targetLabel
          h 'div', { className: 'system-inspector-row' },
            h 'span', { className: 'system-inspector-key' }, 'Status'
            h 'span', { className: armClass }, armLabel
      h Section, { heading: 'Live' },
        h 'div', { className: 'system-inspector-row' },
          h 'span', { className: 'system-inspector-key' }, 'Voltage'
          h 'span', null, "#{Number(tele.batteryVoltage or 0).toFixed(1)} V"
        h 'div', { className: 'system-inspector-row' },
          h 'span', { className: 'system-inspector-key' }, 'CPU'
          h 'span', null, "#{status?.cpuLoad or 0}%"

export default SystemShell