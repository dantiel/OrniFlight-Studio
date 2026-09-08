###
# ORNIFLIGHT STUDIO — FeatherField (ætheric scroll layer)
#
# The feather pattern breathes beneath every panel: a sticky,
# height-zero anchor keeps a full-viewport layer pinned inside
# the #main-content scroll container, while a rAF loop tracks
# scroll velocity and drives two forces:
#   · parallax — the field drifts slower than the panels above
#   · refraction — an SVG feTurbulence/feDisplacementMap filter
#     bends the pattern like light through a water surface,
#     deepening with scroll speed, calming to a murmur at rest.
#
# Panels ride above as glass; their backdrop-filter samples this
# distorted field, so content visibly refracts the feathers.
###
import './FeatherField.sass'
import h from '../../../app/h.coffee'
import { useEffect, useRef } from 'react'

# Refraction bounds — degrees of distortion at rest / in flight.
REST_SCALE = 3
MAX_SCALE = 16
VELOCITY_GAIN = 1.4

FeatherField = ->
  layerRef = useRef null
  mapRef = useRef null

  useEffect ->
    scrollHost = document.getElementById 'main-content'
    return unless scrollHost and layerRef.current

    lastTop = scrollHost.scrollTop
    scale = REST_SCALE
    ticking = false

    frame = ->
      ticking = false
      top = scrollHost.scrollTop
      delta = top - lastTop
      lastTop = top

      # Velocity-modulated refraction — the water remembers motion.
      next = Math.max REST_SCALE,
        Math.min MAX_SCALE, REST_SCALE + Math.abs(delta) * VELOCITY_GAIN
      if Math.abs(next - scale) > 0.25
        scale = next
        mapRef.current?.setAttribute 'scale', scale.toFixed 2

      # Parallax — the field recedes at one seventh the speed of glass.
      layerRef.current.style.transform =
        "translate3d(0, #{-top * 0.16}px, 0) scale(1.18)"

    onScroll = ->
      unless ticking
        ticking = true
        requestAnimationFrame frame

    onResize = -> onScroll()
    scrollHost.addEventListener 'scroll', onScroll, passive: true
    window.addEventListener 'resize', onResize
    frame()
    ->
      scrollHost.removeEventListener 'scroll', onScroll
      window.removeEventListener 'resize', onResize

  h 'div', { className: 'feather-field-anchor', 'aria-hidden': true },
    h 'svg', { className: 'feather-field-defs', width: 0, height: 0 },
      h 'defs', null,
        h 'filter', { id: 'of-feather-refract', x: '-10%', y: '-10%',
          width: '120%', height: '120%' },
          h 'feTurbulence',
            type: 'fractalNoise'
            baseFrequency: '0.011 0.024'
            numOctaves: 2
            seed: 7
            result: 'warp'
          h 'feDisplacementMap',
            ref: mapRef
            in: 'SourceGraphic'
            in2: 'warp'
            scale: REST_SCALE
            xChannelSelector: 'R'
            yChannelSelector: 'G'
    h 'div', { className: 'feather-field', ref: layerRef }

export default FeatherField
