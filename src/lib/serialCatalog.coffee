###
# ORNIFLIGHT STUDIO — Serial Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware serial port wire format exactly. Ground truth:
#
#   OrniFlight/src/main/io/serial.h — serialPortFunction_e masks,
#     serialPortIdentifier_e (USART1..8 = 0..7, USB VCP = 20,
#     SOFTSERIAL1/2 = 30/31), baudRate_e (16 entries)
#   OrniFlight/src/main/io/serial.c — baudRates[] and the
#     pgResetFn_serialConfig defaults (msp 115200, gps 57600,
#     telemetry AUTO, blackbox 115200; UART1 = FUNCTION_MSP)
#   OrniFlight/src/main/msp/msp.c — MSP 54 streams one 7-byte record
#     per available port: identifier u8, functionMask u16 LE,
#     msp/gps/telemetry/blackbox baudrate indices u8
#
# The conflict matrix mirrors the firmware's serialPinFunction
# arbitration — a port can never carry a conflicting pair.
###

SERIAL_CONFIG_BYTES = 7

FUNCTION_MSP = 1
FUNCTION_GPS = 2
FUNCTION_TELEMETRY_FRSKY_HUB = 4
FUNCTION_TELEMETRY_HOTT = 8
FUNCTION_TELEMETRY_LTM = 16
FUNCTION_TELEMETRY_SMARTPORT = 32
FUNCTION_RX_SERIAL = 64
FUNCTION_BLACKBOX = 128
FUNCTION_TELEMETRY_MAVLINK = 512
FUNCTION_ESC_SENSOR = 1024
FUNCTION_VTX_SMARTAUDIO = 2048
FUNCTION_TELEMETRY_IBUS = 4096
FUNCTION_VTX_TRAMP = 8192
FUNCTION_RCDEVICE = 16384
FUNCTION_LIDAR_TF = 32768

# The curated set the PortsView offers — the full mask space remains
# readable/writable on the wire, unknown bits are preserved.
SERIAL_FUNCTIONS = Object.freeze [
  Object.freeze { id: FUNCTION_MSP, key: 'MSP', label: 'MSP' }
  Object.freeze
    id: FUNCTION_RX_SERIAL, key: 'RX', label: 'Serial RX'
  Object.freeze
    id: FUNCTION_VTX_SMARTAUDIO, key: 'VTX_SA', label: 'VTX SmartAudio'
  Object.freeze
    id: FUNCTION_VTX_TRAMP, key: 'VTX_TRAMP', label: 'VTX Tramp'
  Object.freeze { id: FUNCTION_GPS, key: 'GPS', label: 'GPS' }
  Object.freeze
    id: FUNCTION_BLACKBOX, key: 'BLACKBOX', label: 'Blackbox'
]

FUNCTION_CONFLICTS = {}
FUNCTION_CONFLICTS[FUNCTION_MSP] =
  FUNCTION_GPS | FUNCTION_VTX_SMARTAUDIO | FUNCTION_VTX_TRAMP
FUNCTION_CONFLICTS[FUNCTION_GPS] =
  FUNCTION_MSP | FUNCTION_RX_SERIAL |
  FUNCTION_VTX_SMARTAUDIO | FUNCTION_VTX_TRAMP
FUNCTION_CONFLICTS[FUNCTION_RX_SERIAL] =
  FUNCTION_GPS | FUNCTION_VTX_SMARTAUDIO | FUNCTION_VTX_TRAMP
FUNCTION_CONFLICTS[FUNCTION_BLACKBOX] =
  FUNCTION_VTX_SMARTAUDIO | FUNCTION_VTX_TRAMP
FUNCTION_CONFLICTS[FUNCTION_VTX_SMARTAUDIO] =
  FUNCTION_MSP | FUNCTION_GPS | FUNCTION_RX_SERIAL |
  FUNCTION_BLACKBOX | FUNCTION_VTX_TRAMP
FUNCTION_CONFLICTS[FUNCTION_VTX_TRAMP] =
  FUNCTION_MSP | FUNCTION_GPS | FUNCTION_RX_SERIAL |
  FUNCTION_BLACKBOX | FUNCTION_VTX_SMARTAUDIO
Object.freeze FUNCTION_CONFLICTS

# baudRates[] / baudRate_e — index IS the wire value.
BAUD_RATES = Object.freeze [
  'AUTO', '9600', '19200', '38400', '57600', '115200', '230400'
  '250000', '400000', '460800', '500000', '921600', '1000000'
  '1500000', '2000000', '2470000'
]

# The four per-port baud fields in wire order, with UI labels.
BAUD_FIELDS = Object.freeze [
  Object.freeze ['mspBaud', 'MSP']
  Object.freeze ['gpsBaud', 'GPS']
  Object.freeze ['telemetryBaud', 'Telemetry']
  Object.freeze ['blackboxBaud', 'Blackbox']
]

# serialPortIdentifier_e — fixed identifiers used by MSP.
PORT_LABELS = Object.freeze
  0: 'UART1'
  1: 'UART2'
  2: 'UART3'
  3: 'UART4'
  4: 'UART5'
  5: 'UART6'
  6: 'UART7'
  7: 'UART8'
  20: 'USB VCP'
  30: 'SOFTSERIAL1'
  31: 'SOFTSERIAL2'

portLabel = (identifier) -> PORT_LABELS[identifier] ? "PORT #{identifier}"

baudLabel = (index) -> BAUD_RATES[index] ? BAUD_RATES[0]

clampBaud = (value) ->
  value = Math.trunc Number value ? 0
  value = 0 unless Number.isFinite value
  Math.max 0, Math.min BAUD_RATES.length - 1, value

knownFunction = (id) -> SERIAL_FUNCTIONS.some (fn) -> fn.id == id

functionLabels = (mask) ->
  labels = []
  for fn in SERIAL_FUNCTIONS
    labels.push fn.label if mask & fn.id
  labels

maskConflicts = (mask) ->
  conflicts = 0
  for fn in SERIAL_FUNCTIONS
    conflicts |= FUNCTION_CONFLICTS[fn.id] if mask & fn.id
  conflicts

# Turning a function on clears every conflicting function on the same
# port (firmware arbitration); turning it off just clears the bit.
toggleFunction = (mask, functionId, enabled) ->
  return mask unless knownFunction functionId
  if enabled
    (mask & ~FUNCTION_CONFLICTS[functionId]) | functionId
  else
    mask & ~functionId

# Firmware reset defaults (pgResetFn_serialConfig) plus the USB VCP
# link typical boards expose — the sim document mirrors reality so
# dry-runs show a meaningful port table.
SIM_PORT_DEFAULTS = Object.freeze [
  Object.freeze
    identifier: 0
    functionMask: FUNCTION_MSP
    mspBaud: 5
    gpsBaud: 4
    telemetryBaud: 0
    blackboxBaud: 5
  Object.freeze
    identifier: 20
    functionMask: FUNCTION_MSP
    mspBaud: 5
    gpsBaud: 4
    telemetryBaud: 0
    blackboxBaud: 5
]

export {
  SERIAL_CONFIG_BYTES
  FUNCTION_MSP, FUNCTION_GPS, FUNCTION_TELEMETRY_FRSKY_HUB
  FUNCTION_TELEMETRY_HOTT, FUNCTION_TELEMETRY_LTM
  FUNCTION_TELEMETRY_SMARTPORT, FUNCTION_RX_SERIAL, FUNCTION_BLACKBOX
  FUNCTION_TELEMETRY_MAVLINK, FUNCTION_ESC_SENSOR
  FUNCTION_VTX_SMARTAUDIO, FUNCTION_TELEMETRY_IBUS, FUNCTION_VTX_TRAMP
  FUNCTION_RCDEVICE, FUNCTION_LIDAR_TF
  SERIAL_FUNCTIONS, FUNCTION_CONFLICTS, BAUD_RATES, BAUD_FIELDS
  PORT_LABELS, SIM_PORT_DEFAULTS
  portLabel, baudLabel, clampBaud, knownFunction
  functionLabels, maskConflicts, toggleFunction
}