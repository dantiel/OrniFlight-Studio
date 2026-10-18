import './LocaleSwitcher.sass'
import h from '../../../app/h.coffee'
import { LANGUAGES, normalizeLocale } from '../../../i18n/index.coffee'
import useAppStore from '../../../stores/useAppStore.coffee'

# Compact language menu — one segmented flag per supported locale.
# The label is the language's own name (Deutsch / English) so the
# control never needs translating itself.
LocaleSwitcher = ({ className = '' }) ->
  locale = useAppStore (s) -> s.locale
  setLocale = useAppStore (s) -> s.setLocale
  current = normalizeLocale locale

  h 'div',
    className: "locale-switcher #{className}"
    role: 'group'
    'aria-label': 'Language / Sprache'
  , LANGUAGES.map (lang) ->
      active = lang.id is current
      h 'button',
        key: lang.id
        type: 'button'
        className: "locale-option#{if active then ' is-active' else ''}"
        'aria-pressed': active
        title: lang.english
        onClick: -> setLocale lang.id
      ,
        h 'span', { className: 'locale-flag', 'aria-hidden': 'true' }, lang.flag
        h 'span', { className: 'locale-name' }, lang.native

export default LocaleSwitcher
