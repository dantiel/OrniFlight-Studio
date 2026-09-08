###
# ORNIFLIGHT STUDIO — VTX Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware VTX wire format exactly. Ground truth:
#
#   OrniFlight/src/main/drivers/vtx_common.h — vtxDevType_e,
#     VTXCOMMON_MSP_BANDCHAN_CHKVAL = (7 << 3) + 7 = 63,
#     VTX_SETTINGS_MAX_FREQUENCY_MHZ = 5999
#   OrniFlight/src/main/io/vtx.c — pgResetTemplate(vtxSettingsConfig):
#     band 4, channel 1, freq 5740, power 1, lowPowerDisarm OFF
#   OrniFlight/src/main/io/vtx_string.c — vtx58frequencyTable (5×8)
#   OrniFlight/src/main/drivers/vtx_rtc6705.h — 5 bands, 8 channels,
#     3 power levels, 5600–5950 MHz window
#
# SET_VTX_CONFIG rides a u16 value: ≤ 63 encodes
# (band - 1) × 8 + (channel - 1) with 1-based band/channel, 64..5999
# encodes a custom frequency in MHz (band 0). The table is band-major
# and 1-based — band 0 is the firmware's CUSTOM slot.
###

VTX_BAND_COUNT = 5
VTX_CHANNEL_COUNT = 8
VTX_BANDCHAN_CHKVAL = 63
VTX_MAX_FREQUENCY_MHZ = 5999
VTX_FREQ_MIN = 5600
VTX_FREQ_MAX = 5950
VTX_POWER_COUNT = 3
VTX_DEFAULT_POWER = 1

# vtx58frequencyTable — band-major, index = band - 1.
VTX_BANDS = Object.freeze [
  Object.freeze {
    index: 1
    letter: 'A'
    name: 'BOSCAM A'
    frequencies: Object.freeze [
      5865, 5845, 5825, 5805, 5785, 5765, 5745, 5725
    ]
  }
  Object.freeze {
    index: 2
    letter: 'B'
    name: 'BOSCAM B'
    frequencies: Object.freeze [
      5733, 5752, 5771, 5790, 5809, 5828, 5847, 5866
    ]
  }
  Object.freeze {
    index: 3
    letter: 'E'
    name: 'BOSCAM E'
    frequencies: Object.freeze [
      5705, 5685, 5665, 5645, 5885, 5905, 5925, 5945
    ]
  }
  Object.freeze {
    index: 4
    letter: 'F'
    name: 'FATSHARK'
    frequencies: Object.freeze [
      5740, 5760, 5780, 5800, 5820, 5840, 5860, 5880
    ]
  }
  Object.freeze {
    index: 5
    letter: 'R'
    name: 'RACEBAND'
    frequencies: Object.freeze [
      5658, 5695, 5732, 5769, 5806, 5843, 5880, 5917
    ]
  }
]

# vtx58BandLetter = "-ABEFR" — index = band (0 = custom).
BAND_LETTERS = '-ABEFR'

# vtxDevType_e (drivers/vtx_common.h).
VTX_TYPE_LABELS = Object.freeze
  0: 'MSP'
  1: 'RTC6705'
  3: 'SmartAudio'
  4: 'Tramp'
  255: 'Unknown'

# RTC6705 power index (vtx_common.h): 0 = "---", 1 = 25 mW, 2 = 200 mW.
VTX_POWER_LEVELS = Object.freeze [
  Object.freeze { value: 0, label: 'Off' }
  Object.freeze { value: 1, label: '25 mW' }
  Object.freeze { value: 2, label: '200 mW' }
]

# pgResetTemplate(vtxSettingsConfig) — the firmware defaults.
DEFAULT_VTX_CONFIG = Object.freeze
  vtxType: 255
  band: 4
  channel: 1
  power: 1
  pitmode: 0
  freq: 5740
  deviceIsReady: 0
  lowPowerDisarm: 0

bandLabel = (band) ->
  if band >= 1 and band <= VTX_BAND_COUNT
    VTX_BANDS[band - 1].name
  else
    'CUSTOM'

bandLetter = (band) -> BAND_LETTERS[band] ? '-'

channelLabel = (channel) ->
  if channel >= 1 and channel <= VTX_CHANNEL_COUNT
    String channel
  else
    ''

frequencyFor = (band, channel) ->
  return null unless band >= 1 and band <= VTX_BAND_COUNT
  return null unless channel >= 1 and channel <= VTX_CHANNEL_COUNT
  VTX_BANDS[band - 1].frequencies[channel - 1]

# Wire value packing — the inverse of the firmware's
# newBand = value / 8 + 1, newChannel = value % 8 + 1.
packBandChannel = (band, channel) ->
  return null unless band >= 1 and band <= VTX_BAND_COUNT
  return null unless channel >= 1 and channel <= VTX_CHANNEL_COUNT
  (band - 1) * VTX_CHANNEL_COUNT + (channel - 1)

unpackBandChannel = (value) ->
  value = Math.trunc Number value
  return null unless 0 <= value <= VTX_BANDCHAN_CHKVAL
  band = Math.floor(value / VTX_CHANNEL_COUNT) + 1
  channel = value % VTX_CHANNEL_COUNT + 1
  return null unless band <= VTX_BAND_COUNT
  { band, channel }

# Exact table match for a frequency in MHz; null when custom.
lookupBandChannel = (freq) ->
  freq = Number freq
  return null unless Number.isFinite freq
  for band in VTX_BANDS
    for channel in [1..VTX_CHANNEL_COUNT]
      if band.frequencies[channel - 1] == freq
        return { band: band.index, channel }
  null

clampFrequency = (freq) ->
  freq = Math.round Number freq
  freq = VTX_FREQ_MIN unless Number.isFinite freq
  Math.max VTX_FREQ_MIN, Math.min VTX_FREQ_MAX, freq

# The u16 wire value for a config document: a valid band/channel pair
# packs into ≤ 63; anything else rides the frequency.
vtxValueFor = (config = {}) ->
  band = Math.trunc Number config.band ? 0
  channel = Math.trunc Number config.channel ? 0
  packed = packBandChannel band, channel
  return packed if packed?
  Math.max VTX_FREQ_MIN, Math.min VTX_MAX_FREQUENCY_MHZ,
    clampFrequency config.freq

export {
  VTX_BAND_COUNT, VTX_CHANNEL_COUNT, VTX_BANDCHAN_CHKVAL
  VTX_MAX_FREQUENCY_MHZ, VTX_FREQ_MIN, VTX_FREQ_MAX
  VTX_POWER_COUNT, VTX_DEFAULT_POWER
  VTX_BANDS, BAND_LETTERS, VTX_TYPE_LABELS, VTX_POWER_LEVELS
  DEFAULT_VTX_CONFIG
  bandLabel, bandLetter, channelLabel, frequencyFor
  packBandChannel, unpackBandChannel, lookupBandChannel
  clampFrequency, vtxValueFor
}