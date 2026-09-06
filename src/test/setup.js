import '@testing-library/jest-dom'
import { vi } from 'vitest'
import { createElement as h, useEffect } from 'react'
import { getActor } from '../hooks/useConnection.coffee'
import useDeviceStore from '../stores/useDeviceStore.coffee'

// Mock canvas components — jsdom doesn't support Canvas API
vi.mock('../components/canvas/WaveformPlot/WaveformPlot.coffee', () => ({
  default: (props) => h('div', {
    className: 'waveform-canvas-mock', 'data-testid': 'waveform-canvas',
  }),
}))

vi.mock('../components/canvas/GyroBars/GyroBars.coffee', () => ({
  default: (props) => h('div', {
    className: 'gyro-readout-mock', 'data-testid': 'gyro-readout',
  }),
}))

vi.mock(
  '../components/canvas/AircraftViewport/AircraftViewport.coffee',
  () => ({
    default: (props) => h('div', {
      className: 'viewport-mock', 'data-testid': 'viewport',
    }),
  }),
)

// Mock the simulation hook for App tests. The real hook is a push-only
// producer: when the sim transport is the active source it drives the
// connection machine to streaming (polymorphic handshake) and runs the
// engine rAF loop. jsdom tests need the machine transition but skip the
// heavy engine loop — views read stores, never the hook's return value.
vi.mock('../simulation/useSimulation.coffee', () => ({
  useSimulation: () => {
    const source = useDeviceStore((state) => state.source)
    useEffect(() => {
      if (source !== 'simulation') return
      const actor = getActor()
      if (actor.getSnapshot().value !== 'streaming') {
        actor.send({ type: 'CONNECT' })
        actor.send({ type: 'CONNECTED' })
        actor.send({ type: 'FIRMWARE_READY', version: 'sim' })
      }
    }, [source])
    return null
  },
}))

// Mock requestAnimationFrame
global.requestAnimationFrame = (cb) => setTimeout(cb, 0)
global.cancelAnimationFrame = (id) => clearTimeout(id)