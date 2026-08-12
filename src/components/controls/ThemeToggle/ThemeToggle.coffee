import './ThemeToggle.sass'
import { useState, useEffect, createElement } from 'react'

# ═══════════════════════════════════════════════════════════════
# ThemeToggle — dark/light theme switch via data-theme attribute
# Persists preference in localStorage 'orniflight-theme'
# ═══════════════════════════════════════════════════════════════

ThemeToggle = ->
  [theme, setTheme] = useState 'dark'

  useEffect ->
    stored = localStorage.getItem 'orniflight-theme'
    current = if stored in ['dark', 'light'] then stored else 'dark'
    setTheme current
    document.documentElement.setAttribute 'data-theme', current
    return
  , []

  toggle = ->
    next = if theme is 'dark' then 'light' else 'dark'
    setTheme next
    document.documentElement.setAttribute 'data-theme', next
    localStorage.setItem 'orniflight-theme', next

  createElement 'button',
    className: 'theme-toggle-btn'
    onClick: toggle
    title: "Switch to #{if theme is 'dark' then 'light' else 'dark'} theme"
    if theme is 'dark' then '\u263C' else '\u263E'  # ☼ sun / ☾ moon

export default ThemeToggle