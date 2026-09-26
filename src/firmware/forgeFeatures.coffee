###
# ORNIFLIGHT STUDIO · The Forge — Build-Flag Catalog
#
# Curated compile-time feature matrix for cloud builds. The firmware
# (OrniFlight fork) gates each feature behind an opt-out define
# (#ifndef WITHOUT_X) in src/main/target/common_pre/post.h; the
# workflow passes `make OPTIONS="..."` whose tokens become -D defines.
#
# A feature left INCLUDED sends no define — the stock build. Unchecking
# strips the subsystem from the image (slimmer flash footprint).
###

FORGE_FEATURES = [
  {
    id: 'osd'
    define: 'WITHOUT_OSD'
    label: 'OSD'
    blurb: 'On-screen display overlay (Max7456 chip or built-in).'
    note: 'Targets without an OSD chip are unaffected.'
  }
  {
    id: 'blackbox'
    define: 'WITHOUT_BLACKBOX'
    label: 'Blackbox'
    blurb: 'Flight-log recording to the onboard flash chip.'
  }
  {
    id: 'telemetry'
    define: 'WITHOUT_TELEMETRY'
    label: 'Telemetry'
    blurb: 'FrSky Hub / SmartPort downlink to the radio.'
  }
  {
    id: 'ledstrip'
    define: 'WITHOUT_LED_STRIP'
    label: 'LED strip'
    blurb: 'WS2812 programmable LED support.'
  }
  {
    id: 'vtx'
    define: 'WITHOUT_VTX'
    label: 'VTX control'
    blurb: 'SmartAudio / Tramp video-transmitter management.'
  }
  {
    id: 'camera'
    define: 'WITHOUT_CAMERA_CONTROL'
    label: 'Camera control'
    blurb: 'FPV camera menu emulation over the OSD joystick.'
  }
  {
    id: 'launch'
    define: 'WITHOUT_LAUNCH_CONTROL'
    label: 'Launch control'
    blurb: 'Assisted takeoff throttle boost.'
  }
  {
    id: 'dashboard'
    define: 'WITHOUT_DASHBOARD'
    label: 'Dashboard'
    blurb: 'MSP dashboard panel for ground stations.'
  }
  {
    id: 'dshot'
    define: 'WITHOUT_DSHOT'
    label: 'DShot'
    blurb: 'Digital ESC protocol — keep for motor-driven airframes.'
  }
]

FORGE_FEATURE_IDS = (f.id for f in FORGE_FEATURES)

# Inclusion check for templates — `in` cannot appear inline inside
# CoffeeHAML attribute expressions or #{} interpolation (it compiles to
# an IIFE with a bare return), so templates call this instead.
hasFeature = (includedIds, id) -> id in includedIds

# Defines to strip: every feature NOT in the included set becomes its
# opt-out define. Empty when everything is included (stock build).
stripDefines = (includedIds = []) ->
  FORGE_FEATURES
    .filter((f) -> f.id not in includedIds)
    .map (f) -> f.define

export { FORGE_FEATURES, FORGE_FEATURE_IDS, stripDefines, hasFeature }