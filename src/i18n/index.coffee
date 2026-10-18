###
# ORNIFLIGHT STUDIO — I18n core
#
# Key-based translation with Markdown / HTML support.
#
#   t(key, params)   → plain string (attributes, text nodes)
#   md(key, params)  → React element, Markdown → HTML
#   html(key, params)→ React element, raw developer-authored HTML
#   <T k="..." />    → auto-detects the `_markdown` / `_html` suffix
#
# Key convention: a key ending in `_markdown` carries Markdown, one ending
# in `_html` carries raw HTML. Both are developer-authored catalog content
# (never firmware/user input), so rendering through dangerouslySetInnerHTML
# is safe by construction.
#
# Locale lives in useAppStore (persisted to localStorage). `useI18n()`
# re-binds on change; non-React code can read `getT()` / `getLocale()`.
# Fallback chain: requested locale → English → German → the key itself.
###
import { useMemo, createElement as h } from 'react'
import { marked } from 'marked'
import useAppStore from '../stores/useAppStore.coffee'
import { LANGUAGES, DEFAULT_LOCALE, normalizeLocale } from './locales.coffee'
import de from './de.coffee'
import en from './en.coffee'
import es from './es.coffee'
import fr from './fr.coffee'
import it from './it.coffee'
import pt from './pt.coffee'
import nl from './nl.coffee'
import pl from './pl.coffee'
import ru from './ru.coffee'
import tr from './tr.coffee'
import uk from './uk.coffee'
import zh from './zh.coffee'
import ja from './ja.coffee'
import ko from './ko.coffee'

CATALOGS = { de, en, es, fr, it, pt, nl, pl, ru, tr, uk, zh, ja, ko }

# ── Lookup ────────────────────────────────────────────────
resolve = (catalog, key) ->
  node = catalog
  for part in key.split '.'
    return undefined unless node? and typeof node is 'object'
    node = node[part]
  node

lookup = (locale, key) ->
  resolve(CATALOGS[locale], key) ? \
    resolve(CATALOGS.en, key) ? \
    resolve(CATALOGS[DEFAULT_LOCALE], key)

# ── Interpolation: {name} placeholders ────────────────────
interpolate = (str, params = {}) ->
  return str unless typeof str is 'string'
  str.replace /\{(\w+)\}/g, (m, name) ->
    if Object::hasOwnProperty.call(params, name) then String(params[name]) else m

# ── Suffix kind detection ─────────────────────────────────
kindOf = (key) ->
  return 'html' if key.endsWith '_html'
  return 'markdown' if key.endsWith '_markdown'
  'text'

renderMarkdown = (src) ->
  marked.parse(src ? '', { async: false })

# ── Bound translators ─────────────────────────────────────
makeT = (locale) -> (key, params = {}) ->
  msg = lookup(locale, key)
  if typeof msg is 'string' then interpolate(msg, params) else key

makeRich = (locale, kind) -> (key, params = {}, opts = {}) ->
  text = makeT(locale) key, params
  html = if kind is 'html' then text else renderMarkdown text
  attrs = { dangerouslySetInnerHTML: { __html: html } }
  attrs.className = opts.className if opts.className?
  h (opts.as ? 'span'), attrs

# ── React hook ────────────────────────────────────────────
useI18n = ->
  locale = useAppStore (s) -> s.locale
  setLocale = useAppStore (s) -> s.setLocale
  normalized = normalizeLocale locale
  useMemo (-> {
    locale: normalized
    lang: normalized
    setLocale
    t: makeT normalized
    md: makeRich normalized, 'markdown'
    html: makeRich normalized, 'html'
  }), [locale]

# ── Non-React access ──────────────────────────────────────
getLocale = -> normalizeLocale useAppStore.getState().locale
getT = -> makeT getLocale()

# ── <T> component — suffix-aware renderer ─────────────────
T = ({ k, params, as = 'span', className }) ->
  { locale } = useI18n()
  text = makeT(locale) k, params
  kind = kindOf k
  return text if kind is 'text'
  html = if kind is 'html' then text else renderMarkdown text
  props = { dangerouslySetInnerHTML: { __html: html } }
  props.className = className if className?
  h as, props

export {
  LANGUAGES, DEFAULT_LOCALE, normalizeLocale
  resolve, interpolate, kindOf, renderMarkdown
  makeT, useI18n, T, getLocale, getT
}
export default useI18n
