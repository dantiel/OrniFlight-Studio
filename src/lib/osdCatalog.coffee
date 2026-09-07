###
# ORNIFLIGHT STUDIO — OSD Catalog
#
# Pure, zero-class, zero-side-effect module mirroring the OrniFlight
# firmware OSD wire format exactly. Ground truth:
#
#   OrniFlight/src/main/osd/osd.h — enum osd_items_e (52 entries, 0..51),
#     OSD_POS(x,y) = x | (y << 5), OSD_PROFILE_BITS_POS = 11
#   OrniFlight/src/main/osd/osd.c — pgResetFn_osdConfig (defaults),
#     VISIBLE(x) = x & OSD_PROFILE_MASK  (bit SET = element ACTIVE)
#
# item_pos (u16): bits 0..9 hold the cell (x, y in 0..31 on the wire,
# grid UI shows 30×16), bits 11..13 hold per-profile visibility — bit
# SET means VISIBLE in that profile (profile 1 at bit 11), bits 14..15
# are unused. The firmware default leaves every element without profile
# bits, i.e. disabled.
###

GRID_COLS = 30
GRID_ROWS = 16
OSD_ITEM_COUNT = 52
OSD_PROFILE_COUNT = 3

POSITION_BITS = 5
POSITION_XY_MASK = (1 << POSITION_BITS) - 1
PROFILE_BITS_POS = 11
PROFILE_MASK = ((1 << OSD_PROFILE_COUNT) - 1) << PROFILE_BITS_POS
POSITION_MASK = 0x3FF
WIRE_MASK = POSITION_MASK | PROFILE_MASK

itemPos = (x, y) ->
  ((x & POSITION_XY_MASK) |
    ((y & POSITION_XY_MASK) << POSITION_BITS)) & POSITION_MASK

posX = (pos) -> pos & POSITION_XY_MASK
posY = (pos) -> (pos >> POSITION_BITS) & POSITION_XY_MASK
posCell = (pos) -> { x: posX(pos), y: posY(pos) }

clampCell = (x, y) ->
  x = Number x
  y = Number y
  x = 0 unless Number.isFinite x
  y = 0 unless Number.isFinite y
  {
    x: Math.max 0, Math.min GRID_COLS - 1, Math.round x
    y: Math.max 0, Math.min GRID_ROWS - 1, Math.round y
  }

# Cell under a pointer position inside a grid rectangle. Pure — the view
# supplies the bounding rect — and clamped into the visible grid.
cellFromPointer = (clientX, clientY, rect) ->
  return { x: 0, y: 0 } unless rect?.width > 0 and rect?.height > 0
  x = Math.floor (clientX - rect.left) / rect.width * GRID_COLS
  y = Math.floor (clientY - rect.top) / rect.height * GRID_ROWS
  clampCell x, y

# Replace only the low 10 position bits; visibility flags survive.
movePos = (pos, x, y) ->
  (pos & ~POSITION_MASK) | itemPos(x, y)

# Mask everything the wire format does not define (bits 14..15).
sanitizePos = (pos) -> (pos | 0) & WIRE_MASK

profileFlag = (profileIndex) ->
  1 << (PROFILE_BITS_POS + profileIndex - 1)

visibleInProfile = (pos, profileIndex) ->
  (pos & profileFlag(profileIndex)) != 0

visibilityMask = (pos) -> pos & PROFILE_MASK

setVisibleInProfile = (pos, profileIndex, visible) ->
  flag = profileFlag profileIndex
  if visible then pos | flag else pos & ~flag

toggleVisibleInProfile = (pos, profileIndex) ->
  pos ^ profileFlag(profileIndex)

# An element is active when at least one profile bit is set.
isVisible = (pos) -> (pos & PROFILE_MASK) != 0

# First unoccupied cell, row-major; null when the grid is full.
findFreeCell = (items) ->
  occupied = new Set()
  for pos in items
    cell = posCell pos
    occupied.add "#{cell.x}:#{cell.y}"
  for y in [0...GRID_ROWS]
    for x in [0...GRID_COLS]
      return { x, y } unless occupied.has "#{x}:#{y}"
  null

# Enum-exact registry of osd_items_e (0..51). Labels and glyphs are UI
# dressing only — index and key mirror the firmware.
OSD_ITEMS = [
  { index: 0, key: 'RSSI_VALUE', label: 'RSSI', glyph: '📶' }
  { index: 1, key: 'MAIN_BATT_VOLTAGE', label: 'Battery voltage', glyph: '🔋' }
  { index: 2, key: 'CROSSHAIRS', label: 'Crosshairs', glyph: '⊕' }
  { index: 3, key: 'ARTIFICIAL_HORIZON', label: 'Artif. horizon', glyph: '◔' }
  { index: 4, key: 'HORIZON_SIDEBARS', label: 'Horizon sidebars', glyph: '▮' }
  { index: 5, key: 'ITEM_TIMER_1', label: 'Timer 1', glyph: '⏱' }
  { index: 6, key: 'ITEM_TIMER_2', label: 'Timer 2', glyph: '⏲' }
  { index: 7, key: 'FLYMODE', label: 'Fly mode', glyph: '🛩' }
  { index: 8, key: 'CRAFT_NAME', label: 'Craft name', glyph: '⌁' }
  { index: 9, key: 'THROTTLE_POS', label: 'Throttle', glyph: '⚡' }
  { index: 10, key: 'VTX_CHANNEL', label: 'VTX channel', glyph: '📡' }
  { index: 11, key: 'CURRENT_DRAW', label: 'Current draw', glyph: '🔌' }
  { index: 12, key: 'MAH_DRAWN', label: 'mAh drawn', glyph: '🪫' }
  { index: 13, key: 'GPS_SPEED', label: 'GPS speed', glyph: '🛰' }
  { index: 14, key: 'GPS_SATS', label: 'GPS satellites', glyph: '🛰' }
  { index: 15, key: 'ALTITUDE', label: 'Altitude', glyph: '⛰' }
  { index: 16, key: 'ROLL_PIDS', label: 'Roll PIDs', glyph: '📊' }
  { index: 17, key: 'PITCH_PIDS', label: 'Pitch PIDs', glyph: '📊' }
  { index: 18, key: 'YAW_PIDS', label: 'Yaw PIDs', glyph: '📊' }
  { index: 19, key: 'POWER', label: 'Power', glyph: '🔆' }
  { index: 20, key: 'PIDRATE_PROFILE', label: 'PID rate profile', glyph: '▣' }
  { index: 21, key: 'WARNINGS', label: 'Warnings', glyph: '⚠' }
  { index: 22, key: 'AVG_CELL_VOLTAGE', label: 'Avg cell voltage', glyph: '🔋' }
  { index: 23, key: 'GPS_LON', label: 'GPS longitude', glyph: '🧭' }
  { index: 24, key: 'GPS_LAT', label: 'GPS latitude', glyph: '🧭' }
  { index: 25, key: 'DEBUG', label: 'Debug', glyph: '🐞' }
  { index: 26, key: 'PITCH_ANGLE', label: 'Pitch angle', glyph: '∡' }
  { index: 27, key: 'ROLL_ANGLE', label: 'Roll angle', glyph: '∡' }
  { index: 28, key: 'MAIN_BATT_USAGE', label: 'Battery usage', glyph: '🪫' }
  { index: 29, key: 'DISARMED', label: 'Disarmed', glyph: '🛑' }
  { index: 30, key: 'HOME_DIR', label: 'Home direction', glyph: '🏠' }
  { index: 31, key: 'HOME_DIST', label: 'Home distance', glyph: '📏' }
  { index: 32, key: 'NUMERICAL_HEADING', label: 'Heading', glyph: '🧭' }
  { index: 33, key: 'NUMERICAL_VARIO', label: 'Vario', glyph: '↕' }
  { index: 34, key: 'COMPASS_BAR', label: 'Compass bar', glyph: '➤' }
  { index: 35, key: 'ESC_TMP', label: 'ESC temperature', glyph: '🌡' }
  { index: 36, key: 'ESC_RPM', label: 'ESC RPM', glyph: '🌀' }
  { index: 37, key: 'REMAINING_TIME_ESTIMATE', label: 'Time left', glyph: '⏳' }
  { index: 38, key: 'RTC_DATETIME', label: 'Date & time', glyph: '🕐' }
  { index: 39, key: 'ADJUSTMENT_RANGE', label: 'Adjustment range', glyph: '⇔' }
  { index: 40, key: 'CORE_TEMPERATURE', label: 'Core temperature', glyph: '🌡' }
  { index: 41, key: 'ANTI_GRAVITY', label: 'Anti gravity', glyph: '🪂' }
  { index: 42, key: 'G_FORCE', label: 'G-force', glyph: '💫' }
  { index: 43, key: 'MOTOR_DIAG', label: 'Motor diagnostics', glyph: '🛠' }
  { index: 44, key: 'LOG_STATUS', label: 'Log status', glyph: '🗒' }
  { index: 45, key: 'FLIP_ARROW', label: 'Flip arrow', glyph: '⇅' }
  { index: 46, key: 'LINK_QUALITY', label: 'Link quality', glyph: '🔗' }
  { index: 47, key: 'FLIGHT_DIST', label: 'Flight distance', glyph: '🛣' }
  { index: 48, key: 'STICK_OVERLAY_LEFT', label: 'Stick left', glyph: '🕹' }
  { index: 49, key: 'STICK_OVERLAY_RIGHT', label: 'Stick right', glyph: '🕹' }
  { index: 50, key: 'DISPLAY_NAME', label: 'Display name', glyph: '⌨' }
  { index: 51, key: 'ESC_RPM_FREQ', label: 'ESC RPM frequency', glyph: '🌀' }
]

# pgResetFn_osdConfig defaults: every element at OSD_POS(10,7) without
# profile bits (disabled), WARNINGS enabled in all profiles, and the
# three classic elements at their fixed positions.
OSD_DEFAULTS = (itemPos(10, 7) for _ in [0...OSD_ITEM_COUNT])
OSD_DEFAULTS[2] = itemPos 13, 6        # CROSSHAIRS
OSD_DEFAULTS[3] = itemPos 14, 2        # ARTIFICIAL_HORIZON
OSD_DEFAULTS[4] = itemPos 14, 6        # HORIZON_SIDEBARS
OSD_DEFAULTS[21] = itemPos(9, 10) | PROFILE_MASK  # WARNINGS

OSD_DEFAULT_PROFILE_INDEX = 1

export {
  GRID_COLS, GRID_ROWS, OSD_ITEM_COUNT, OSD_PROFILE_COUNT
  POSITION_XY_MASK, PROFILE_BITS_POS, PROFILE_MASK, POSITION_MASK
  itemPos, posX, posY, posCell, clampCell, cellFromPointer, movePos
  sanitizePos, profileFlag, visibleInProfile, visibilityMask
  setVisibleInProfile, toggleVisibleInProfile, isVisible, findFreeCell
  OSD_ITEMS, OSD_DEFAULTS, OSD_DEFAULT_PROFILE_INDEX
}