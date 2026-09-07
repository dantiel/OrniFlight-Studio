import './ConfigurationHub.sass'
import { useEffect, useState } from 'react'
import useTelemetryStore from '../../../stores/useTelemetryStore.coffee'
import useFirmwareConnection from '../../../hooks/useFirmwareConnection.coffee'
import useDeviceStore from '../../../stores/useDeviceStore.coffee'
import h from '../../../app/h.coffee'

HUBS =
  device:
    title: 'Device'
    subtitle: 'Controller identity, hardware and system-wide configuration.'
    groups: [
      ['Board & Craft', 'Target, craft name, firmware identity and capabilities.', 'Profile']
      ['Ports & Peripherals', 'Serial functions, receiver input and telemetry output.', 'Device']
      ['System', 'Loop timing, features, arming, beeper and alignment.', 'Profile']
      ['Calibration & Reset', 'Sensor calibration, defaults and bootloader actions.', 'Live']
      ['Backup & Restore', 'Portable configuration snapshots and device diffs.', 'File']
      ['Advanced / CLI', 'Raw firmware settings and diagnostic commands.', 'Device']
    ]
  power:
    title: 'Power'
    subtitle: 'Battery state, metering, calibration and protection thresholds.'
    groups: [
      ['Battery', 'Capacity, cell detection, minimum, warning and maximum voltage.', 'Profile']
      ['Voltage Meter', 'Source, scale, divider and multiplier calibration.', 'Device']
      ['Current Meter', 'Source, scale, offset and consumption calibration.', 'Device']
      ['Warnings', 'Low-voltage and consumed-capacity thresholds.', 'Profile']
    ]
  safety:
    title: 'Safety'
    subtitle: 'Arming constraints and deterministic behavior after link loss.'
    groups: [
      ['Arming', 'Arming angle, checks, auto-disarm and kill-switch behavior.', 'Profile']
      ['Channel Fallback', 'Hold or configured fallback value for each receiver channel.', 'Profile']
      ['Link Loss', 'Detection delay, stage timing and throttle behavior.', 'Profile']
      ['Recovery', 'Drop, land, recovery mode and capability-gated rescue.', 'Capability']
    ]
  data:
    title: 'Data'
    subtitle: 'Telemetry, flight recording, storage and diagnostics.'
    groups: [
      ['Live Telemetry', 'Inspect and record active sensor, receiver and output streams.', 'Live']
      ['Blackbox', 'Logging device, rate, debug mode and field selection.', 'Device']
      ['Storage', 'Onboard flash or SD status, erase and download.', 'Live']
      ['Files & Diagnostics', 'Open logs offline, export data and compare sessions.', 'File']
    ]

ConfigurationHub = (props) ->
  spec = HUBS[props.kind] || HUBS.device
  tele = useTelemetryStore()
  conn = useFirmwareConnection()
  identity = useDeviceStore (state) -> state.identity
  status = useDeviceStore (state) -> state.status
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
      setSaveState error?.message or 'Save failed'

  deviceSummary = null
  if props.kind == 'device' and identity
    sensorNames = Object.entries(identity.capabilities?.sensors or {})
      .filter((entry) -> entry[1])
      .map((entry) -> entry[0])
    deviceSummary = h 'section', { className: 'hub-device-summary', 'aria-label': 'Connected controller' },
      h 'div', { className: 'hub-device-field hub-device-craft' },
        h('span', null, 'CRAFT'),
        h 'form', { onSubmit: saveName },
          h('input', {
            value: nameDraft
            maxLength: 24
            disabled: not hardwareConnected or status?.armed or saveState == 'saving'
            'aria-label': 'Craft name'
            onChange: (event) -> setNameDraft event.target.value
          }),
          h('button', {
            type: 'submit'
            disabled: not hardwareConnected or status?.armed or saveState == 'saving' or not nameDraft.trim()
          }, if saveState == 'saving' then 'Saving…' else 'Apply')
        h('small', { className: if saveState not in ['idle', 'saved'] then 'error' else '' },
          if status?.armed then 'Writes locked while armed' else if saveState == 'saved' then 'Verified on device' else if saveState not in ['idle', 'saving'] then saveState else 'EEPROM write + read-back verification')
      h 'div', { className: 'hub-device-field' },
        h('span', null, 'FIRMWARE'),
        h('strong', null, "#{identity.variant} #{identity.firmware.version}"),
        h('small', null, "MSP API #{identity.api.version} · #{identity.build.revision or 'local build'}")
      h 'div', { className: 'hub-device-field' },
        h('span', null, 'TARGET'),
        h('strong', null, identity.board.boardName or identity.board.targetName or identity.board.identifier),
        h('small', null, "#{identity.board.identifier} · MCU #{identity.board.mcuTypeId}")
      h 'div', { className: 'hub-device-field' },
        h('span', null, 'LIVE STATUS'),
        h('strong', { className: if status?.armed then 'status-armed' else 'status-safe' }, if status?.armed then 'ARMED' else 'DISARMED'),
        h('small', null, "CPU #{status?.cpuLoad or 0}% · #{if sensorNames.length then sensorNames.join(', ') else 'no sensors reported'}")

  h 'div', { className: 'configuration-hub' },
    h 'header', { className: 'hub-header' },
      h 'div', null,
        h 'span', { className: 'hub-kicker' }, 'CONFIGURATION WORKSPACE'
        h 'h1', null, spec.title
        h 'p', null, spec.subtitle
      h 'div', { className: "hub-source #{if hardwareConnected then 'connected' else ''}" },
        h 'span', { className: 'hub-source-dot' }
        if hardwareConnected then 'DEVICE CONNECTED' else 'OFFLINE PROFILE'
    if conn.lastError then h('div', { className: 'hub-connection-error', role: 'alert' }, conn.lastError)
    deviceSummary
    if props.kind == 'power' then h 'div', { className: 'hub-live-strip' },
      h 'span', null, 'LIVE BATTERY'
      h 'strong', null, "#{Number(tele.batteryVoltage || 0).toFixed(1)} V"
      h 'span', null, if hardwareConnected then 'from controller' else 'simulation source'
    h 'div', { className: 'hub-grid' }, spec.groups.map((group) ->
      h 'article', { className: 'hub-card', key: group[0] },
        h 'div', { className: 'hub-card-top' },
          h 'h2', null, group[0]
          h 'span', { className: "availability availability-#{group[2].toLowerCase()}" }, group[2]
        h 'p', null, group[1]
        h 'span', { className: 'hub-card-state' }, if hardwareConnected and group[2] in ['Device', 'Live'] then 'Available from controller' else 'Offline schema'
    )

export default ConfigurationHub