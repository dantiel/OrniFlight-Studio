# Keep the document still: only the title has a bounded parallax offset.
# Docking and the shared blur safe area follow measured layout, including
# wrapped controls and reduced-motion mode.
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
  headSel = opts.headSel ? '.morph-head-title'
  stuckClass = opts.stuckClass ? 'morph-stuck'
  travelledClass = opts.travelledClass ? 'morph-travelled'

  useEffect ->
    host = hostRef.current
    scrollHost = document.getElementById 'main-content'
    return unless host and scrollHost
    media = window.matchMedia?('(prefers-reduced-motion: reduce)')
    headTitle = host.querySelector headSel
    deck = host.querySelector '.morph-deck, .molt-deck'
    shell = host.closest '.studio-shell'
    toolbar = shell?.querySelector '.connection-bar'
    raf = null
    lastSafeArea = null

    frame = ->
      raf = null
      st = scrollHost.scrollTop
      toolbarH = toolbar?.getBoundingClientRect().height or 70
      scrollTop = scrollHost.getBoundingClientRect().top
      if headTitle
        progress = if media?.matches then 0 else clamp01(st / Math.max(1, headTitle.offsetHeight))
      docked = false
      deckH = 0
      if deck
        rect = deck.getBoundingClientRect()
        docked = rect.top <= scrollTop + toolbarH + 1 and rect.bottom > scrollTop + toolbarH
        deckH = rect.height if docked
      host.style.setProperty '--head-morph', progress.toFixed(3) if headTitle
      host.classList.toggle stuckClass, docked
      host.classList.toggle travelledClass, st > 24
      safeArea = toolbarH + deckH
      if safeArea isnt lastSafeArea
        shell?.style.setProperty '--of-safe-area-bar', "#{safeArea}px"
        lastSafeArea = safeArea

    onScroll = ->
      raf = requestAnimationFrame(frame) unless raf?

    observer = if typeof ResizeObserver isnt 'undefined' then new ResizeObserver(onScroll) else null
    observer?.observe el for el in [host, headTitle, deck, toolbar] when el
    scrollHost.addEventListener 'scroll', onScroll, passive: true
    window.addEventListener 'resize', onScroll
    media?.addEventListener? 'change', onScroll
    frame()
    ->
      cancelAnimationFrame raf if raf?
      observer?.disconnect()
      scrollHost.removeEventListener 'scroll', onScroll
      window.removeEventListener 'resize', onScroll
      media?.removeEventListener? 'change', onScroll
      shell?.style.removeProperty '--of-safe-area-bar'

  []

export default useScrollMorph
