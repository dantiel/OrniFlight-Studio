import './PlotWorkspace.sass'
import { createElement as h, useMemo } from 'react'
import useAppStore from '../../../stores/useAppStore.coffee'
import PlotCard from '../PlotCard/PlotCard.coffee'
import { curvesForWorkspace } from '../../../telemetry/curveCatalog.coffee'
import {
  profileKey, defaultPlots, clonePlots
} from '../../../telemetry/plotProfiles.coffee'
import { useI18n } from '../../../i18n/index.coffee'

MODE_KEYS =
  full: 'plots.horizon'
  split: 'plots.nest'
  compact: 'plots.roost'

PlotWorkspace = ({ workspace = 'airframe', history = [], mode }) ->
  storedMode = useAppStore (state) -> state.viewMode
  plotProfiles = useAppStore (state) -> state.plotProfiles or {}
  setPlotProfile = useAppStore (state) -> state.setPlotProfile
  resetPlotProfile = useAppStore (state) -> state.resetPlotProfile
  { t } = useI18n()
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
      title: t('plots.copy', { title: source.title })
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
        title: t('plots.newPlot')
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
        h('span', { className: 'plot-profile-kicker' }, t('plots.profile')),
        h('strong', null, t('plots.profileLabel', { workspace: workspace, mode: t(MODE_KEYS[activeMode] or 'plots.nest') })),
        h('span', { className: 'plot-profile-state' }, if customized then t('plots.customized') else t('plots.default')),
      h 'div', { className: 'plot-workspace-actions' },
        h('button', {
          type: 'button'
          title: t('plots.resetTitle')
          disabled: not customized
          onClick: -> resetPlotProfile key
        }, t('plots.reset')),
        h('button', {
          type: 'button'
          className: 'primary'
          title: t('plots.addTitle')
          onClick: addPlot
        }, t('plots.addPlot')),
    h('div', { className: 'plot-card-strip' }, cards)

export default PlotWorkspace
