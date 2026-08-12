###
# ORNIFLIGHT STUDIO — Application Store (Zustand)
#
# Architectural role: single source of truth for UI state.
#
# Middleware stack (composed functionally):
#   persist(name)  → localStorage survival across refresh
#   devtools(name) → Redux DevTools timeline + jump-to-state
#
# Selector pattern:
#   activeTab = useAppStore((s) -> s.activeTab)
#   Components import only their slice — no re-renders on
#   unrelated state changes.
###
import { create } from 'zustand'
import { persist, devtools } from 'zustand/middleware'

useAppStore = create(
  devtools(
    persist(
      (set) ->
        # ── View state ──
        activeTab:    'servos'
        configView:   'wings'
        viewMode:     'split'
        waveCurves:   ['wingL', 'wingR']
        gyroCurves:   ['gyroRoll']
        activeProfile: 1

        # ── Connection state (mirror of XState machine) ──
        connectionState: 'disconnected'
        connected: false
        batteryVoltage: 0
        flapFrequency: 0

        # ── Actions ──
        setActiveTab:       (activeTab)    -> set { activeTab }
        setConfigView:      (configView)   -> set { configView }
        setViewMode:        (viewMode)     -> set { viewMode }
        setWaveCurves:      (waveCurves)   -> set { waveCurves }
        setGyroCurves:      (gyroCurves)   -> set { gyroCurves }
        setActiveProfile:   (activeProfile)-> set { activeProfile }
        setConnectionState: (connectionState, connected = false) ->
          set { connectionState, connected }
        setBattery:         (batteryVoltage, flapFrequency = 0) ->
          set { batteryVoltage, flapFrequency }
      ,
      name: 'orniflight-app'          # localStorage key
      partialize: (state) ->           # only persist view prefs, not connection
        activeTab:    state.activeTab
        configView:   state.configView
        viewMode:     state.viewMode
        waveCurves:   state.waveCurves
        gyroCurves:   state.gyroCurves
        activeProfile: state.activeProfile
    ),
    name: '📦 AppStore'               # Redux DevTools label
  )
)

export default useAppStore
