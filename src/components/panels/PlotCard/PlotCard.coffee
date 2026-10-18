import './PlotCard.sass'
import { createElement as h, useEffect, useRef, useState } from 'react'
import WaveformPlot from '../../canvas/WaveformPlot/WaveformPlot.coffee'
import { groupCurves } from '../../../telemetry/curveCatalog.coffee'
import { useI18n } from '../../../i18n/index.coffee'

PlotCard = ({
  plot, history, curveOptions, onChange, onDuplicate, onRemove,
  allowRemove = true, workspace
}) ->
  [menuOpen, setMenuOpen] = useState false
  menuRef = useRef null
  groups = groupCurves curveOptions
  { t } = useI18n()

  useEffect ->
    return unless menuOpen
    close = (event) ->
      setMenuOpen false unless menuRef.current?.contains event.target
    document.addEventListener 'pointerdown', close
    -> document.removeEventListener 'pointerdown', close
  , [menuOpen]

  toggleCurve = (id) ->
    selected = plot.curves or []
    curves =
      if id in selected then selected.filter((curveId) -> curveId isnt id)
      else [...selected, id]
    onChange { curves }

  openContext = (event) ->
    event.preventDefault()
    setMenuOpen true

  menu = null
  if menuOpen
    groupNodes = for own name, curves of groups
      h 'fieldset', { className: 'plot-menu-group', key: name },
        h('legend', null, name),
        curves.map (curve) ->
          active = curve.id in (plot.curves or [])
          h 'label', { className: 'plot-curve-option', key: curve.id },
            h('input', {
              type: 'checkbox'
              checked: active
              onChange: -> toggleCurve curve.id
            }),
            h('span', {
              className: 'curve-swatch'
              style: { backgroundColor: curve.color }
            }),
            h('span', { className: 'curve-option-label' }, curve.label),
            h('span', { className: 'curve-unit' }, curve.unit)

    capabilityNote = null
    if workspace is 'sensors' and not curveOptions.some((curve) -> curve.group is 'Accelerometer')
      capabilityNote = h 'p', { className: 'plot-capability-note' },
        t('plots.accelerometerNote')

    menu = h 'div', {
      className: 'plot-context-menu'
      ref: menuRef
      role: 'dialog'
      'aria-label': t('plots.configure', { title: plot.title })
    },
      h 'label', { className: 'plot-title-editor' },
        h('span', null, t('plots.plotTitle')),
        h('input', {
          value: plot.title
          onChange: (event) -> onChange { title: event.target.value }
        }),
      groupNodes,
      capabilityNote,
      h 'div', { className: 'plot-menu-actions' },
        h('button', { type: 'button', onClick: onDuplicate }, t('plots.duplicate')),
        h('button', {
          type: 'button'
          className: 'danger'
          disabled: not allowRemove
          onClick: onRemove
        }, t('plots.removePlot'))

  h 'article', {
    className: 'telemetry-plot-card'
    onContextMenu: openContext
  },
    h 'header', { className: 'plot-card-header' },
      h('h3', null, plot.title),
      h 'button', {
        type: 'button'
        className: 'plot-menu-trigger'
        title: t('plots.menuTitle')
        'aria-label': t('plots.configure', { title: plot.title })
        'aria-expanded': menuOpen
        onClick: -> setMenuOpen not menuOpen
      }, '•••',
    h(WaveformPlot, { history, curves: plot.curves }),
    menu

export default PlotCard
