import h from '../../../app/h.coffee'
import { activeSubtabForPath } from '../../../lib/navigation.coffee'
import Icon from '../Icon/Icon.coffee'

# The active sub-view's own icon, re-embodied in a page headline —
# one shared vocabulary across the whole surface, but each sub-view
# carries a distinct glyph. Reads the current route from
# window.location so it needs no Router context (views render in
# tests without one, and a route change always re-renders the headline).
# The app is a HashRouter: the route lives in location.hash, not pathname.
# (pathname is the dev-server base /OrniFlight-Studio/ — resolving it would
# always fall back to the basic module.) Read the hash first; fall back to
# pathname for test environments where the hash is empty.
routeFromLocation = ->
  hash = window.location.hash
  if hash and hash.length > 1 then hash.slice 1 else window.location.pathname

ModuleIcon = ({ className = 'head-icon', size = 30 }) ->
  sub = activeSubtabForPath(routeFromLocation())
  h Icon, { name: sub.icon, className, size }

export default ModuleIcon