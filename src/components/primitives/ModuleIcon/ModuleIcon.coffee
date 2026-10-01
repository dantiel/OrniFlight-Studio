import h from '../../../app/h.coffee'
import { activeModuleForPath } from '../../../lib/navigation.coffee'
import Icon from '../Icon/Icon.coffee'

# The active module's dock icon, re-embodied in a page headline —
# one shared vocabulary across the whole surface. Reads the current
# route from window.location so it needs no Router context (views
# render in tests without one, and a route change always re-renders
# the headline).
ModuleIcon = ({ className = 'head-icon', size = 30 }) ->
  mod = activeModuleForPath(window.location.pathname)
  h Icon, { name: mod.icon, className, size }

export default ModuleIcon
