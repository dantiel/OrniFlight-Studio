import './ConfigurationHub.sass'
import { useEffect, useState } from 'react'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import useFirmwareConnection from '../../../hooks/useFirmwareConnection.coffee'
import useDeviceStore from '../../../stores/useDeviceStore.coffee'
import h from '../../../app/h.coffee'
import { useI18n } from '../../../i18n/index.coffee'

HUBS =
  device:
    titleKey: 'hub.device.title'
    subtitleKey: 'hub.device.subtitle'
    groups: [
      ['boardCraft', 'boardCraftDesc', 'Profile']
      ['portsPeripherals', 'portsPeripheralsDesc', 'Device']
      ['system', 'systemDesc', 'Profile']
      ['calibrationReset', 'calibrationResetDesc', 'Live']
      ['backupRestore', 'backupRestoreDesc', 'File']
      ['advancedCli', 'advancedCliDesc', 'Device']
    ]
  power:
    titleKey: 'hub.power.title'
    subtitleKey: 'hub.power.subtitle'
    groups: [
      ['battery', 'batteryDesc', 'Profile']
      ['voltageMeter', 'voltageMeterDesc', 'Device']
      ['currentMeter', 'currentMeterDesc', 'Device']
      ['warnings', 'warningsDesc', 'Profile']
    ]
  safety:
    titleKey: 'hub.safety.title'
    subtitleKey: 'hub.safety.subtitle'
    groups: [
      ['arming', 'armingDesc', 'Profile']
      ['channelFallback', 'channelFallbackDesc', 'Profile']
      ['linkLoss', 'linkLossDesc', 'Profile']
      ['recovery', 'recoveryDesc', 'Capability']
    ]
  data:
    titleKey: 'hub.data.title'
    subtitleKey: 'hub.data.subtitle'
    groups: [
      ['liveTelemetry', 'liveTelemetryDesc', 'Live']
      ['blackbox', 'blackboxDesc', 'Device']
      ['storage', 'storageDesc', 'Live']
      ['filesDiagnostics', 'filesDiagnosticsDesc', 'File']
    ]

ConfigurationHub = (props) ->
  spec = HUBS[props.kind] || HUBS.device
  tele = useTelemetryStore()
  conn = useFirmwareConnection()
  identity = useDeviceStore (state) -> state.identity
  status = useDeviceStore (state) -> state.status
  { t } = useI18n()
  hardwareConnected = conn.connected and conn.source == 'device'
  [nameDraft, setNameDraft] = useState identity?.name or ''
  [saveState, setSaveState] = useState 'idle'

  useEffect ->
    setNameDraft identity?.name or ''
    setSaveState 'idle'
  , [identity?.name]

  saveName = (event) ->
    event.preventDefault()
    return unless hardwareConnected
    try
      setSaveState 'saving'
      await conn.setCraftName nameDraft
      setSaveState 'saved'
    catch error
      setSaveState error?.message or t('hub.saveFailed')

  deviceSummary = null
  if props.kind == 'device' and identity
    sensorNames = Object.entries(identity.capabilities?.sensors or {})
      .filter((entry) -> entry[1])
      .map((entry) -> entry[0])
    deviceSummary = h 'section', { className: 'hub-device-summary', 'aria-label': t('hub.connectedController') },
      h 'div', { className: 'hub-device-field hub-device-craft' },
        h('span', null, t('hub.craft')),
        h 'form', { onSubmit: saveName },
          h('input', {
            value: nameDraft
            maxLength: 16
            disabled: not hardwareConnected or status?.armed or saveState == 'saving'
            'aria-label': t('hub.craftName')
            onChange: (event) -> setNameDraft event.target.value
          }),
          h('button', {
            type: 'submit'
            disabled: not hardwareConnected or status?.armed or saveState == 'saving' or not nameDraft.trim()
          }, if saveState == 'saving' then t('hub.saving') else t('hub.apply'))
        h('small', { className: if saveState not in ['idle', 'saved'] then 'error' else '' },
          if status?.armed
            t('hub.writesLocked')
          else if saveState == 'saved'
            t('hub.verified')
          else if saveState not in ['idle', 'saving']
            saveState
          else
            t('hub.maxChars'))
      h 'div', { className: 'hub-device-field' },
        h('span', null, t('hub.firmware')),
        h('strong', null, "#{identity.variant} #{identity.firmware.version}"),
        h('small', null, "MSP API #{identity.api.version} · #{identity.build.revision or t('hub.localBuild')}")
      h 'div', { className: 'hub-device-field' },
        h('span', null, t('hub.target')),
        h('strong', null, identity.board.boardName or identity.board.targetName or identity.board.identifier),
        h('small', null, "#{identity.board.identifier} · MCU #{identity.board.mcuTypeId}")
      h 'div', { className: 'hub-device-field' },
        h('span', null, t('hub.liveStatus')),
        h('strong', { className: if status?.armed then 'status-armed' else 'status-safe' }, if status?.armed then t('hub.armed') else t('hub.disarmed')),
        h('small', null, "CPU #{status?.cpuLoad or 0}% · #{if sensorNames.length then sensorNames.join(', ') else t('hub.noSensors')}")

  h 'div', { className: 'configuration-hub' },
    h 'header', { className: 'hub-header' },
      h 'div', null,
        h 'span', { className: 'hub-kicker' }, t('hub.kicker')
        h 'h1', null, t(spec.titleKey)
        h 'p', null, t(spec.subtitleKey)
      h 'div', { className: "hub-source #{if hardwareConnected then 'connected' else ''}" },
        h 'span', { className: 'hub-source-dot' }
        if hardwareConnected then t('hub.deviceConnected') else t('hub.offlineProfile')
    if conn.lastError then h('div', { className: 'hub-connection-error', role: 'alert' }, conn.lastError)
    deviceSummary
    if props.kind == 'power' then h 'div', { className: 'hub-live-strip' },
      h 'span', null, t('hub.liveBattery')
      h 'strong', null, "#{Number(tele.batteryVoltage || 0).toFixed(1)} V"
      h 'span', null, if hardwareConnected then t('hub.fromController') else t('hub.simulationSource')
    h 'div', { className: 'hub-grid' }, spec.groups.map((group) ->
      h 'article', { className: 'hub-card', key: group[0] },
        h 'div', { className: 'hub-card-top' },
          h 'h2', null, t("hub.groups.#{group[0]}")
          h 'span', { className: "availability availability-#{group[2].toLowerCase()}" }, group[2]
        h 'p', null, t("hub.groups.#{group[1]}")
        h 'span', { className: 'hub-card-state' }, if hardwareConnected and group[2] in ['Device', 'Live'] then t('hub.available') else t('hub.offlineSchema')
    )

export default ConfigurationHub
