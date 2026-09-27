###
# ORNIFLIGHT STUDIO — useMoltMorph
#
# Scroll choreography for vertical parallax documents. Wires a rAF
# loop to the #main-content scroll host and stamps the page head and
# every .molt-section with custom properties consumed by CSS:
#
#   --morph       0→1 entrance progress — curtain rise, settle, glow
#   --exit        0→1 as a section drifts past the upper viewport
#   --depth       px lag offset — deeper sections scroll a touch slower
#   --head-morph  0→1 as the page head condenses into the masthead
#
# The host gains .molt-travelled once the page has scrolled. Honours
# prefers-reduced-motion by not attaching at all; CSS custom-property
# fallbacks keep every effect at rest (fully revealed) without JS.
###
import { useEffect } from 'react'

clamp01 = (v) -> Math.max 0, Math.min 1, v

useMoltMorph = (hostRef) ->
  useEffect ->
    host = hostRef.current
    scrollHost = document.getElementById 'main-content'
    return unless host and scrollHost
    reduce = window.matchMedia?('(prefers-reduced-motion: reduce)').matches
    return if reduce

    sections = Array.from host.querySelectorAll '.molt-section'
    head = host.querySelector '.molt-head'
    ticking = false

    frame = ->
      ticking = false
      vh = scrollHost.clientHeight or window.innerHeight or 800
      st = scrollHost.scrollTop

      if head
        headH = head.offsetHeight or 1
        host.style.setProperty '--head-morph',
          clamp01(st / (headH * 0.45)).toFixed 3

      host.classList.toggle 'molt-travelled', st > 24

      sections.forEach (el, i) ->
        rect = el.getBoundingClientRect()
        morph = clamp01 (vh - rect.top) / (vh * 0.3)
        exit = clamp01 ((vh * 0.22) - rect.top) / (vh * 0.22)
        depth = st * (0.02 + i * 0.012)
        el.style.setProperty '--morph', morph.toFixed 3
        el.style.setProperty '--exit', exit.toFixed 3
        el.style.setProperty '--depth', "#{Math.round depth}px"

    onScroll = ->
      unless ticking
        ticking = true
        requestAnimationFrame frame

    scrollHost.addEventListener 'scroll', onScroll, passive: true
    window.addEventListener 'resize', onScroll
    frame()
    ->
      scrollHost.removeEventListener 'scroll', onScroll
      window.removeEventListener 'resize', onScroll

  []

export default useMoltMorph
