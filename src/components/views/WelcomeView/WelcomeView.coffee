import './WelcomeView.sass'
import { useNavigate } from 'react-router-dom'
import h from '../../../app/h.coffee'
import useFirmwareConnection from '../../../hooks/useFirmwareConnection.coffee'

WelcomeView = ->
  navigate = useNavigate()
  firmware = useFirmwareConnection()
  busy = firmware.state in ['scanning', 'handshaking']
  primaryLabel = switch firmware.state
    when 'scanning' then 'Choose controller…'
    when 'handshaking' then 'Reading firmware…'
    else 'Connect controller'

  connect = ->
    connected = await firmware.connect()
    navigate '/system/device' if connected

  lastDevice = firmware.identity
  h 'main', { className: 'welcome-view', 'aria-labelledby': 'welcome-title' },
    h 'section', { className: 'welcome-hero' },
      h 'div', { className: 'welcome-orbit', 'aria-hidden': 'true' },
        h('span', { className: 'welcome-orbit-core' }, 'Æ')
      h 'div', { className: 'welcome-copy' },
        h('span', { className: 'welcome-kicker' }, 'ORNIFLIGHT STUDIO'),
        h('h1', { id: 'welcome-title' }, 'Configure the bird. Understand the flight.'),
        h('p', null, 'Open an offline workspace or connect an OrniFlight controller. The 3D flight preview loads only when a workspace needs it.'),
        h 'div', { className: 'welcome-actions' },
          h('button', {
            className: 'welcome-primary'
            type: 'button'
            disabled: busy or not firmware.supported
            onClick: connect
          }, primaryLabel),
          h('button', {
            className: 'welcome-secondary'
            type: 'button'
            onClick: -> navigate '/system/device'
          }, 'Open offline workspace'),
        unless firmware.supported
          h('p', { className: 'welcome-notice' }, 'This browser does not expose WebSerial. Offline profiles remain available.')
        if firmware.lastError
          h('p', { className: 'welcome-error', role: 'alert' }, firmware.lastError)
    h 'aside', { className: 'welcome-session' },
      h('span', { className: 'welcome-session-label' }, if lastDevice then 'LAST CONTROLLER' else 'SESSION'),
      if lastDevice
        h 'div', { className: 'welcome-device' },
          h('strong', null, lastDevice.name or lastDevice.board.targetName or lastDevice.board.identifier),
          h('span', null, "OrniFlight #{lastDevice.firmware.version} · API #{lastDevice.api.version}"),
          h('span', null, lastDevice.board.boardName or lastDevice.board.targetName)
      else
        h 'div', { className: 'welcome-device welcome-device-empty' },
          h('strong', null, 'No controller connected'),
          h('span', null, 'Profiles and log tools work without firmware.'),
      h 'div', { className: 'welcome-steps' },
        h('span', null, '1 · Connect'),
        h('span', null, '2 · Compare'),
        h('span', null, '3 · Apply')

export default WelcomeView
