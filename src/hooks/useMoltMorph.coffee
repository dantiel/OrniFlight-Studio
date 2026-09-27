###
# ORNIFLIGHT STUDIO — useMoltMorph
#
# The Molt's scroll choreography, now a thin delegate over the
# shared useScrollMorph system with the Molt's own vocabulary:
# .molt-section / .molt-head-title sections and molt-stuck /
# molt-travelled host classes. moltScrollTo spotlights with the
# molt halo. All behaviour lives in useScrollMorph.
###
import useScrollMorph from './useScrollMorph.coffee'
import { scrollMorphTo } from './useScrollMorph.coffee'

export moltScrollTo = (id) -> scrollMorphTo(id, 'molt-spotlight')

useMoltMorph = (hostRef) ->
  useScrollMorph hostRef,
    sectionSel: '.molt-section'
    headSel: '.molt-head-title'
    stuckClass: 'molt-stuck'
    travelledClass: 'molt-travelled'

export default useMoltMorph
