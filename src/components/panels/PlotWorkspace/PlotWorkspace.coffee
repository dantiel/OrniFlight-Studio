import './PlotWorkspace.sass'
import { createElement as h, useMemo } from 'react'
import useAppStore from '../../../stores/useAppStore.coffee'
import PlotCard from '../PlotCard/PlotCard.coffee'
import { curvesForWorkspace } from '../../../telemetry/curveCatalog.coffee'
import {
  profileKey, defaultPlots, clonePlots
} from '../../../telemetry/plotProfiles.coffee'

MODE_LABELS =
  full: 'Horizon'
  split: 'Nest'
  compact: 'Roost'

PlotWorkspace = ({ workspace = 'airframe', history = [], mode }) ->
  storedMode = useAppStore (state) -> state.viewMode
  plotProfiles = useAppStore (state) -> state.plotProfiles or {}
  setPlotProfile = useAppStore (state) -> state.setPlotProfile
  resetPlotProfile = useAppStore (state) -> state.resetPlotProfile
  activeMode = mode or storedMode or 'split'
  key = profileKey workspace, activeMode
  defaults = useMemo (-> defaultPlots workspace, activeMode), [workspace, activeMode]
  customized = Boolean plotProfiles[key]
  plots = plotProfiles[key] or defaults
  curveOptions = curvesForWorkspace workspace, history

  save = (next) -> setPlotProfile key, next
  updateAt = (index, patch) ->
    next = clonePlots plots
    next[index] = { next[index]..., patch... }
    save next
  removeAt = (index) ->
    return unless plots.length > 1
    save plots.filter((plot, i) -> i isnt index)
  duplicateAt = (index) ->
    source = plots[index]
    copy = {
      source...
      id: "#{source.id}-copy-#{Date.now().toString(36)}"
      title: "#{source.title} copy"
      curves: source.curves[...]
    }
    next = plots[...]
    next.splice index + 1, 0, copy
    save next
  addPlot = ->
    firstCurve = curveOptions[0]?.id
    save [
      ...clonePlots(plots)
      {
        id: "custom-#{Date.now().toString(36)}"
        title: 'New plot'
        curves: if firstCurve then [firstCurve] else []
      }
    ]

  cards = plots.map (plot, index) ->
    h PlotCard,
      key: plot.id
      plot: plot
      history: history
      curveOptions: curveOptions
      workspace: workspace
      allowRemove: plots.length > 1
      onChange: (patch) -> updateAt index, patch
      onDuplicate: -> duplicateAt index
      onRemove: -> removeAt index

  h 'section', {
    className: "plot-workspace plot-workspace-#{activeMode}"
    'aria-label': "#{workspace} telemetry plots"
  },
    h 'header', { className: 'plot-workspace-toolbar' },
      h 'div', { className: 'plot-profile-label' },
        h('span', { className: 'plot-profile-kicker' }, 'Plot profile'),
        h('strong', null, "#{workspace} · #{MODE_LABELS[activeMode] or activeMode}"),
        h('span', { className: 'plot-profile-state' }, if customized then 'Customized · saved locally' else 'Default'),
      h 'div', { className: 'plot-workspace-actions' },
        h('button', {
          type: 'button'
          title: 'Restore the default plots for this workspace and layout'
          disabled: not customized
          onClick: -> resetPlotProfile key
        }, 'Reset'),
        h('button', {
          type: 'button'
          className: 'primary'
          title: 'Add another configurable plot'
          onClick: addPlot
        }, '+ Plot'),
    h('div', { className: 'plot-card-strip' }, cards)

export default PlotWorkspace
