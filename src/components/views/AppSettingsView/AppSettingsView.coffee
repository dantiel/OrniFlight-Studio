import './AppSettingsView.sass'
import h from '../../../app/h.coffee'
import { useI18n, LANGUAGES, normalizeLocale } from '../../../i18n/index.coffee'
import useAppStore from '../../../stores/useAppStore.coffee'
import ModuleIcon from '../../primitives/ModuleIcon/ModuleIcon.coffee'
import ThemeToggle from '../../controls/ThemeToggle/ThemeToggle.coffee'
import ViewModeToggle from '../../controls/ViewModeToggle/ViewModeToggle.coffee'

# Studio-side preferences: interface language (all supported locales),
# theme and workspace layout. The language choice is persisted in the
# app store (localStorage) — nothing here touches the controller.
AppSettingsView = ->
  { t } = useI18n()
  locale = useAppStore (s) -> s.locale
  setLocale = useAppStore (s) -> s.setLocale
  viewMode = useAppStore (s) -> s.viewMode
  setViewMode = useAppStore (s) -> s.setViewMode
  current = normalizeLocale locale

  h 'div', { className: 'app-settings-view' },
    h 'header', { className: 'app-settings-head' },
      h 'span', { className: 'app-settings-kicker' }, t('app.kicker')
      h 'h1', { className: 'orgone-display orgone-display-shimmer' },
        h ModuleIcon, { className: 'app-settings-glyph', size: 30 }
        h 'span', null, t('app.title')
      h 'p', { className: 'app-settings-sub' }, t('app.subtitle')

    h 'section', { className: 'app-settings-section' },
      h 'h2', { className: 'app-settings-section-title' }, t('app.interface')
      h 'p', { className: 'app-settings-hint' }, t('app.interfaceSub')

    h 'section', { className: 'app-settings-section' },
      h 'h2', { className: 'app-settings-section-title' }, t('app.language')
      h 'p', { className: 'app-settings-hint' }, t('app.languageSub')
      h 'div', { className: 'language-grid', role: 'listbox', 'aria-label': t('app.language') },
        LANGUAGES.map (lang) ->
          active = lang.id is current
          h 'button',
            key: lang.id
            type: 'button'
            role: 'option'
            'aria-selected': active
            className: "language-option#{if active then ' is-active' else ''}"
            onClick: -> setLocale lang.id
          ,
            h 'span', { className: 'language-flag', 'aria-hidden': 'true' }, lang.flag
            h 'span', { className: 'language-native' }, lang.native
            h 'span', { className: 'language-english' }, lang.english
            if active
              h 'span', { className: 'language-check', 'aria-hidden': 'true' }, '✓'

    h 'section', { className: 'app-settings-section' },
      h 'h2', { className: 'app-settings-section-title' }, t('app.appearance')
      h 'p', { className: 'app-settings-hint' }, t('app.appearanceSub')
      h 'div', { className: 'app-settings-row' },
        h 'span', { className: 'app-settings-label' }, t('app.theme')
        h ThemeToggle, null
      h 'div', { className: 'app-settings-row' },
        h 'span', { className: 'app-settings-label' }, t('app.layout')
        h ViewModeToggle, { mode: viewMode, onModeChange: setViewMode }

export default AppSettingsView
