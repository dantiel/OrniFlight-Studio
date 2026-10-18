import './WelcomeView.sass'
import { useNavigate } from 'react-router-dom'
import h from '../../../app/h.coffee'
import useFirmwareConnection from '../../../hooks/useFirmwareConnection.coffee'
import { useI18n } from '../../../i18n/index.coffee'

WelcomeView = ->
  navigate = useNavigate()
  firmware = useFirmwareConnection()
  { t, md, html } = useI18n()
  busy = firmware.state in ['scanning', 'handshaking']
  primaryLabel = switch firmware.state
    when 'scanning' then t('welcome.choosing')
    when 'handshaking' then t('welcome.reading')
    else t('welcome.connect')

  connect = ->
    connected = await firmware.connect()
    navigate '/system/device' if connected

  lastDevice = firmware.identity
  h 'main', { className: 'welcome-view', 'aria-labelledby': 'welcome-title' },
    h 'section', { className: 'welcome-hero' },
      h 'div', { className: 'welcome-orbit', 'aria-hidden': 'true' },
        h('span', { className: 'welcome-orbit-core' }, 'Æ')
      h 'div', { className: 'welcome-copy' },
        h('span', { className: 'welcome-kicker' }, t('welcome.kicker')),
        h('h1', { id: 'welcome-title' }, t('welcome.title')),
        h('p', null, t('welcome.subtitle')),
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
          }, t('welcome.offline')),
        unless firmware.supported
          h('p', { className: 'welcome-notice' }, t('welcome.webSerialNotice'))
        if firmware.lastError
          h('p', { className: 'welcome-error', role: 'alert' }, firmware.lastError)
    h 'aside', { className: 'welcome-session' },
      h('span', { className: 'welcome-session-label' }, if lastDevice then t('welcome.lastController') else t('welcome.session')),
      if lastDevice
        h 'div', { className: 'welcome-device' },
          h('strong', null, lastDevice.name or lastDevice.board.targetName or lastDevice.board.identifier),
          h('span', null, "OrniFlight #{lastDevice.firmware.version} · API #{lastDevice.api.version}"),
          h('span', null, lastDevice.board.boardName or lastDevice.board.targetName)
      else
        h 'div', { className: 'welcome-device welcome-device-empty' },
          h('strong', null, t('welcome.noController')),
          h('span', null, t('welcome.profilesNote')),
      h 'div', { className: 'welcome-steps' },
        h('span', null, t('welcome.step1')),
        h('span', null, t('welcome.step2')),
        h('span', null, t('welcome.step3'))
    h 'footer', { className: 'welcome-legal' },
      html('welcome.legal_html')

export default WelcomeView
