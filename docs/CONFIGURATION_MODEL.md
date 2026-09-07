# OrniFlight Studio — Configuration Model

This model replaces the old configurator's flat tab list with durable domain
workspaces. A workspace is not tied to a connection: configuration may come
from an offline profile, a connected controller, a backup, or firmware defaults.

## Workspaces

| Workspace | Configuration owned by the workspace |
|---|---|
| Device | Board target, craft identity, feature flags, loop timing, arming, beeper, calibration, reset, backup/restore, ports and peripherals, advanced CLI |
| Airframe | Servo endpoints/direction/rate, wing geometry, mount position, channel/output assignment, ONDAS wing mixer, actuator test |
| Flight Control | PID axes, rates/expo, feedforward, gyro and D-term filters, anti-gravity, I-term behavior, dynamic notch, control profiles and in-flight adjustments |
| Receiver | Receiver protocol, serial/SPI setup, channel map, endpoints/deadband, input interpolation/smoothing, RSSI/LQ, modes/AUX ranges |
| Power | Battery capacity and cell thresholds, voltage/current meter source, scale/offset/divider calibration, current consumption and warnings |
| Sensors | Gyro selection/alignment/range/rate/filtering and live traces; capability-gated accelerometer, magnetometer, barometer, sonar and GPS |
| Safety | Arming constraints, receiver fallback per channel, link-loss stages, failsafe procedure, recovery and future GPS rescue |
| Data | Live telemetry logging, blackbox device/rate/debug mode, flash/SD management, log import/export and diagnostics |
| Flash Firmware | Target and release selection, local images, full erase, flash-on-connect, bootloader recovery, verification and console |

## Availability model

Every field should expose a source and an availability state instead of hiding
the entire workspace when no controller is connected.

- **Profile** — editable offline and queued for a later sync.
- **Device** — read from or written to a connected controller.
- **Capability** — shown only when the selected target or connected firmware
  reports support.
- **Live** — requires an active stream, calibration operation, test mode, or
  storage device.
- **File** — usable offline from backups, firmware images, or log files.

Edits belong to a draft configuration document. Connecting a controller should
produce a diff (`draft ↔ device`) and an explicit apply/revert workflow rather
than replacing the draft silently.

## Legacy configurator coverage

| Legacy tab | New home |
|---|---|
| Setup, Configuration, Ports, CLI | Device |
| Servos, Motors/servo test, ornithopter geometry | Airframe |
| PID Tuning, Rates, Filters, Adjustments, Profiles | Flight Control |
| Receiver, Modes/Auxiliary | Receiver |
| Power | Power |
| Sensors, GPS capability | Sensors |
| Failsafe, receiver channel fallback | Safety |
| Logging, Onboard Logging/Blackbox | Data |
| Firmware Flasher | Flash Firmware |
| Simulator | Embedded preview in Airframe, Flight Control, and Sensors |

OSD, VTX, LED strip, transponder, GPS, and other optional modules should be
capability-driven extensions, not permanent top-level navigation items.
