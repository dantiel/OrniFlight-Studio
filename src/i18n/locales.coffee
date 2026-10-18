###
# ORNIFLIGHT STUDIO — Locale registry
#
# Every language the studio speaks. `de` is the project's mother tongue
# (the firmware docs and current UI literals are German); `en` is the
# universal fallback when a key is missing from a translation. The
# language menu in System → App renders this registry in full.
###
export LANGUAGES = [
  { id: 'de', native: 'Deutsch', english: 'German', flag: '🇩🇪' }
  { id: 'en', native: 'English', english: 'English', flag: '🇬🇧' }
  { id: 'es', native: 'Español', english: 'Spanish', flag: '🇪🇸' }
  { id: 'fr', native: 'Français', english: 'French', flag: '🇫🇷' }
  { id: 'it', native: 'Italiano', english: 'Italian', flag: '🇮🇹' }
  { id: 'pt', native: 'Português', english: 'Portuguese', flag: '🇵🇹' }
  { id: 'nl', native: 'Nederlands', english: 'Dutch', flag: '🇳🇱' }
  { id: 'pl', native: 'Polski', english: 'Polish', flag: '🇵🇱' }
  { id: 'ru', native: 'Русский', english: 'Russian', flag: '🇷🇺' }
  { id: 'tr', native: 'Türkçe', english: 'Turkish', flag: '🇹🇷' }
  { id: 'uk', native: 'Українська', english: 'Ukrainian', flag: '🇺🇦' }
  { id: 'zh', native: '中文', english: 'Chinese', flag: '🇨🇳' }
  { id: 'ja', native: '日本語', english: 'Japanese', flag: '🇯🇵' }
  { id: 'ko', native: '한국어', english: 'Korean', flag: '🇰🇷' }
]

export DEFAULT_LOCALE = 'de'

export SUPPORTED_LOCALES = (lang.id for lang in LANGUAGES)

export normalizeLocale = (locale) ->
  if locale in SUPPORTED_LOCALES then locale else DEFAULT_LOCALE
