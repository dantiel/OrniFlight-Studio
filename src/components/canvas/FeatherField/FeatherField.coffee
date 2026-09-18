###
# ORNIFLIGHT STUDIO — FeatherField (ætheric scroll layer)
#
# The feather pattern breathes beneath every panel: a full-viewport
# layer pinned inside the #main-content scroll container, while a
# rAF loop tracks scroll and drives a gentle parallax — the field
# drifts slower than the panels above.
#
# The feathers stay plain and sharp. Glass panels carry their own
# blur (backdrop-filter), so the æther reads crisp and ubiquitous,
# frosting only where a panel sits on top of it.
###
import './FeatherField.sass'
import h from '../../../app/h.coffee'
import { useEffect, useRef } from 'react'

# Parallax — the field recedes at a fraction of the glass' speed.
PARALLAX = 0.16

FeatherField = ->
  layerRef = useRef null

  useEffect ->
    scrollHost = document.getElementById 'main-content'
    return unless scrollHost and layerRef.current

    ticking = false

    frame = ->
      ticking = false
      top = scrollHost.scrollTop

      # Parallax — the æther drifts slower than the panels above.
      layerRef.current.style.transform =
        "translate3d(0, #{-top * PARALLAX}px, 0) scale(1.18)"

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
    h 'div', { className: 'feather-field', ref: layerRef }

export default FeatherField
