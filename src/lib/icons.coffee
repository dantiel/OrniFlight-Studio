###
# ORNIFLIGHT STUDIO — Icon registry
#
# Single source of truth for the studio's stroke icons. Every glyph in
# the interface renders from here as inline SVG (stroke = currentColor),
# so dock, sub-menu and headlines share one vocabulary.
###
ICONS =
  wing:
    paths: [
      'M3 12 C5.5 6 12 3.5 21 6.5 L21 17.5 C12 20.5 5.5 18 3 12 Z'
      'M3 12 L21 12'
    ]
  layers:
    paths: [
      'M12 3 L21 8 L12 13 L3 8 Z'
      'M3 12.6 L12 17.6 L21 12.6'
      'M3 17.2 L12 22.2 L21 17.2'
    ]
  gear:
    paths: [
      'M12 8.5 a3.5 3.5 0 1 0 0 7 a3.5 3.5 0 1 0 0 -7'
      'M12 2.5 V5 M12 19 V21.5'
      'M2.5 12 H5 M19 12 H21.5'
      'M5.3 5.3 L7 7 M17 17 L18.7 18.7'
      'M5.3 18.7 L7 17 M17 7 L18.7 5.3'
    ]
  sliders:
    paths: ['M4 7 H20', 'M4 12 H20', 'M4 17 H20']
    circles: [
      { cx: 9, cy: 7, r: 1.8 }
      { cx: 15, cy: 12, r: 1.8 }
      { cx: 7, cy: 17, r: 1.8 }
    ]
  radar:
    paths: [
      'M12 4.5 a7.5 7.5 0 1 0 0.001 0'
      'M12 12 L17.5 7.5'
    ]
    circles: [{ cx: 15.5, cy: 15.5, r: 1 }]
  grid:
    paths: [
      'M4 4 h7 v7 H4 Z'
      'M13 4 h7 v7 h-7 Z'
      'M4 13 h7 v7 H4 Z'
      'M13 13 h7 v7 h-7 Z'
    ]
  shield:
    paths: [
      'M12 3 L20 6 V11.5 C20 16.2 16.9 19.4 12 21 C7.1 19.4 4 16.2 4 11.5 V6 Z'
      'M9 11.5 L11.2 13.7 L15.5 9.2'
    ]
  terminal:
    paths: [
      'M4 5 H20 V19 H4 Z'
      'M8.5 9.5 L11.5 12 L8.5 14.5'
      'M13.5 15.5 H16.5'
    ]
  cmd:
    paths: [
      'M15 6 V18 A3 3 0 1 0 18 15 H6 A3 3 0 1 0 9 18 V6 A3 3 0 1 0 6 9 H18 A3 3 0 1 0 15 6'
    ]
  close:
    paths: ['M6 6 L18 18', 'M18 6 L6 18']
  'arrow-up-right':
    paths: ['M7 17 L17 7', 'M8 7 H17 V16']
  plug:
    paths: [
      'M9 3 V6 M15 3 V6'
      'M6.5 6 H17.5 V11 A5.5 5.5 0 0 1 12 16.5 A5.5 5.5 0 0 1 6.5 11 Z'
      'M12 16.5 V21'
    ]
  'plug-off':
    paths: [
      'M9 3 V6 M15 3 V6'
      'M6.5 6 H17.5 V11 A5.5 5.5 0 0 1 12 16.5'
      'M12 16.5 V21'
      'M3.5 3.5 L20.5 20.5'
    ]
  moon:
    paths: ['M12 3 A6 6 0 0 0 21 12 A9 9 0 1 1 12 3 Z']
  sun:
    paths: [
      'M12 4.5 V2.5 M12 21.5 V19.5'
      'M4.5 12 H2.5 M21.5 12 H19.5'
      'M6.6 6.6 L5.2 5.2 M18.8 18.8 L17.4 17.4'
      'M6.6 17.4 L5.2 18.8 M18.8 5.2 L17.4 6.6'
    ]
    circles: [{ cx: 12, cy: 12, r: 3.6 }]
  bug:
    paths: [
      'M12 8 a3.5 3.5 0 1 0 0 7 a3.5 3.5 0 1 0 0 -7'
      'M8 15 H3.5 L2.5 18 M16 15 H20.5 L21.5 18'
      'M9 5 H6 L6.5 2.5 M15 5 H18 L17.5 2.5'
      'M9 12 H6 M15 12 H18'
    ]
  waves:
    paths: [
      'M3 7 C5.5 4.5 8.5 4.5 11 7 C13.5 9.5 16.5 9.5 19 7'
      'M3 13 C5.5 10.5 8.5 10.5 11 13 C13.5 15.5 16.5 15.5 19 13'
      'M3 19 C5.5 16.5 8.5 16.5 11 19 C13.5 21.5 16.5 21.5 19 19'
    ]
  ruler:
    paths: [
      'M3 21 L10.5 13.5'
      'M17 4 L20 7 L7.5 19.5 L4.5 16.5 Z'
      'M15.5 5.5 L18.5 8.5 M13.5 7.5 L16.5 10.5 M11.5 9.5 L14.5 12.5'
    ]
  square:
    paths: ['M4 4 H20 V20 H4 Z']
  columns:
    paths: ['M4 4 H10 V20 H4 Z', 'M14 4 H20 V20 H14 Z']
  rows:
    paths: ['M4 4 H20 V10 H4 Z', 'M4 14 H20 V20 H4 Z']
  body:
    paths: [
      'M12 3.5 a2.4 2.4 0 1 0 0.001 0'
      'M6.5 21 C6.5 12.5 17.5 12.5 17.5 21'
    ]
  airframe:
    paths: ['M4 20 L12 4 L20 20 Z', 'M12 4 V20']
  gauge:
    paths: ['M4 14 a8 8 0 1 1 16 0', 'M12 14 L12 7']
    circles: [{ cx: 12, cy: 14, r: 1.2 }]
  function:
    paths: ['M3 16 H21', 'M3 16 C8 16 8 5 13 5 C18 5 18 16 21 16']
  toggle:
    paths: ['M6 8 h12 a4 4 0 0 1 0 8 h-12 a4 4 0 0 1 0 -8 Z']
    circles: [{ cx: 17, cy: 12, r: 2.6 }]
  antenna:
    paths: ['M12 21 V12', 'M4 12 a8 8 0 0 1 16 0', 'M7.5 12 a4.5 4.5 0 0 1 9 0']
    circles: [{ cx: 12, cy: 10, r: 1 }]
  wrench:
    paths: [
      'M14.7 6.3 a1 1 0 0 0 0 1.4 l1.6 1.6 a1 1 0 0 0 1.4 0 l3.77 -3.77 a6 6 0 0 1 -7.94 7.94 l-6.91 6.91 a2.12 2.12 0 0 1 -3 -3 l6.91 -6.91 a6 6 0 0 1 7.94 -7.94 l-3.76 3.76 z'
    ]
  chip:
    paths: [
      'M7 7 H17 V17 H7 Z'
      'M10 10 H14 V14 H10 Z'
      'M9 7 V4 M15 7 V4 M9 17 V20 M15 17 V20'
      'M7 9 H4 M7 15 H4 M17 9 H20 M17 15 H20'
    ]
  gyro:
    paths: [
      'M12 3 a9 9 0 1 0 0.001 0'
      'M3 12 a9 4.5 0 0 0 18 0'
      'M12 3 a4.5 9 0 0 0 0 18'
    ]
    circles: [{ cx: 12, cy: 12, r: 1 }]
  device:
    paths: ['M4 4 H20 V20 H4 Z', 'M4 9 H20', 'M4 15 H20']
    circles: [
      { cx: 7.5, cy: 6.5, r: 0.9 }
      { cx: 7.5, cy: 12, r: 0.9 }
      { cx: 7.5, cy: 17.5, r: 0.9 }
    ]
  ports:
    paths: ['M4 7 H20 V17 H4 Z', 'M7 10 H10 V14 H7 Z', 'M14 10 H17 V14 H14 Z']
  battery:
    paths: ['M3 8 H17 V16 H3 Z', 'M20 10 V14', 'M6 10.5 V13.5']
  broadcast:
    paths: ['M12 21 V6', 'M7 6 H17', 'M8 9 H16', 'M9 12 H15', 'M4 21 H20']
  overlay:
    paths: [
      'M2.5 12 C2.5 12 6 5.5 12 5.5 C18 5.5 21.5 12 21.5 12 C21.5 12 18 18.5 12 18.5 C6 18.5 2.5 12 2.5 12 Z'
    ]
    circles: [{ cx: 12, cy: 12, r: 2.6 }]
  voice:
    paths: [
      'M11 5 L6 9 H3 V15 H6 L11 19 Z'
      'M15.5 9 a3.5 3.5 0 0 1 0 6'
      'M18.5 6.5 a7 7 0 0 1 0 11'
    ]
  memory:
    paths: [
      'M12 3.5 C6 3.5 3 5.5 3 8.5 V15.5 C3 18.5 6 20.5 12 20.5 C18 20.5 21 18.5 21 15.5 V8.5 C21 5.5 18 3.5 12 3.5 Z'
      'M3 12 C3 15 6 17 12 17 C18 17 21 15 21 12'
    ]
  bolt:
    paths: ['M13 3 L5 13 H11 L10 21 L19 11 H13 Z']
  data:
    paths: ['M3 20 H21', 'M5 20 V13 M9 20 V7 M13 20 V16 M17 20 V10']

export { ICONS }