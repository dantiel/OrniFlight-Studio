# The background follows the native scroll timeline where supported.
# Layout observers update its travel distance; scrolling only changes transform.
import './FeatherField.sass'
import h from '../../../app/h.coffee'
import { useEffect, useRef } from 'react'

PARALLAX = 0.16

FeatherField = ->
  layerRef = useRef null

  useEffect ->
    scrollHost = document.getElementById 'main-content'
    layer = layerRef.current
    return unless scrollHost and layer
    nativeScroll = window.CSS?.supports('animation-timeline: scroll()') and
      window.CSS?.supports('timeline-scope: --studio-scroll')
    media = window.matchMedia?('(prefers-reduced-motion: reduce)')

    onScroll = ->
      top = if media?.matches then 0 else scrollHost.scrollTop
      layer.style.transform = "translate3d(0, #{-top * PARALLAX}px, 0) scale(1.18)"

    measure = ->
      travel = Math.max(0, scrollHost.scrollHeight - scrollHost.clientHeight) * PARALLAX
      layer.style.setProperty '--feather-travel', "#{travel}px"
      onScroll() unless nativeScroll

    observer = if typeof ResizeObserver isnt 'undefined' then new ResizeObserver(measure) else null
    observeContent = ->
      observer?.disconnect()
      observer?.observe scrollHost
      observer?.observe child for child in scrollHost.children
      measure()
    mutations = new MutationObserver observeContent
    mutations.observe scrollHost, childList: true
    observeContent()
    unless nativeScroll
      scrollHost.addEventListener 'scroll', onScroll, passive: true
      media?.addEventListener? 'change', onScroll
    window.addEventListener 'resize', measure
    ->
      observer?.disconnect()
      mutations.disconnect()
      scrollHost.removeEventListener 'scroll', onScroll
      media?.removeEventListener? 'change', onScroll
      window.removeEventListener 'resize', measure

  h 'div', { className: 'feather-field-anchor', 'aria-hidden': true },
    h 'div', { className: 'feather-field', ref: layerRef }

export default FeatherField
