###
# ORNIFLIGHT STUDIO — useScrollMorph
#
# Generic scroll choreography for vertical parallax documents (the
# transmorph system). Wires a rAF loop to the #main-content scroll
# host and stamps the page head and every section with custom
# properties consumed by CSS:
#
#   --morph       0→1 entrance progress — curtain rise, settle, glow
#   --exit        0→1 as a section drifts past the upper viewport
#   --depth       px lag offset — deeper sections scroll a touch slower
#   --head-morph  0→1 as the page head dissolves upward
#
# The host gains the travelled class once scrolled and the stuck
# class once the big title has fully dissolved — the pin-point where
# a control deck transmutes into glass. Options select the section/
# head selectors and class names so each view keeps its own
# vocabulary (useMoltMorph delegates here).
#
# scrollMorphTo brings a section into the reading position and
# briefly spotlights it (orgone halo). Honours prefers-reduced-
# motion: the hook does not attach at all and CSS custom-property
# fallbacks rest every effect at its revealed state without JS.
###
import { useEffect } from 'react'

clamp01 = (v) -> Math.max 0, Math.min 1, v

###
# Action-driven scroll: brings a section into the reading position
# and briefly spotlights it. Safe in jsdom (scrollIntoView guarded).
###
export scrollMorphTo = (id, spotlightClass = 'morph-spotlight') ->
  el = document.getElementById id
  return unless el
  reduce = window.matchMedia?('(prefers-reduced-motion: reduce)')?.matches
  try
    el.scrollIntoView?(
      { behavior: (if reduce then 'auto' else 'smooth'), block: 'start' }
    )
  catch err
    undefined
  unless reduce
    el.classList.add spotlightClass
    window.setTimeout (-> el.classList.remove spotlightClass), 1900

useScrollMorph = (hostRef, opts = {}) ->
  sectionSel = opts.sectionSel ? '.morph-section'
  headSel = opts.headSel ? '.morph-head-title'
  stuckClass = opts.stuckClass ? 'morph-stuck'
  travelledClass = opts.travelledClass ? 'morph-travelled'

  useEffect ->
    host = hostRef.current
    scrollHost = document.getElementById 'main-content'
    return unless host and scrollHost
    reduce = window.matchMedia?('(prefers-reduced-motion: reduce)').matches
    return if reduce

    sections = Array.from host.querySelectorAll sectionSel
    headTitle = host.querySelector headSel
    ticking = false

    frame = ->
      ticking = false
      vh = scrollHost.clientHeight or window.innerHeight or 800
      st = scrollHost.scrollTop

      if headTitle
        titleH = headTitle.offsetHeight or 1
        host.style.setProperty '--head-morph',
          clamp01(st / (titleH * 0.9)).toFixed 3
        host.classList.toggle stuckClass, st > titleH * 0.9

      host.classList.toggle travelledClass, st > 24

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

export default useScrollMorph