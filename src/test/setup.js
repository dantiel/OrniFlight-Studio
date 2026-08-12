import '@testing-library/jest-dom'
import { vi } from 'vitest'
import { createElement as h } from 'react'

// Mock canvas components — jsdom doesn't support Canvas API
vi.mock('../components/canvas/WaveformPlot/WaveformPlot.coffee', () => ({
  default: (props) => h('div', { className: 'waveform-canvas-mock', 'data-testid': 'waveform-canvas' }),
}))

vi.mock('../components/canvas/GyroBars/GyroBars.coffee', () => ({
  default: (props) => h('div', { className: 'gyro-readout-mock', 'data-testid': 'gyro-readout' }),
}))

vi.mock('../components/canvas/AircraftViewport/AircraftViewport.coffee', () => ({
  default: (props) => h('div', { className: 'viewport-mock', 'data-testid': 'viewport' }),
}))

// Mock the simulation hook for App tests
vi.mock('../simulation/useSimulation.coffee', () => ({
  useSimulation: () => ({
    snapshot: {
      attitude: [0, 0, 0],
      gyro: { roll: 0, pitch: 0, yaw: 0 },
      wingAngleL: 0,
      wingAngleR: 0,
      flapFrequency: 6.0,
      amplitude: 45.0,
      batteryVoltage: 12.6,
      servoPositions: [1500, 1500, 1500, 1500],
      waveformHistory: [],
      t: 0,
    },
    servos: [
      { name: 'Servo 1', midpoint: 1500, min: 1000, max: 2000, rate: 50, amplitudeScale: 1.0 },
      { name: 'Servo 2', midpoint: 1500, min: 1000, max: 2000, rate: 50, amplitudeScale: 1.0 },
      { name: 'Servo 3', midpoint: 1500, min: 1000, max: 2000, rate: 50, amplitudeScale: 1.0 },
      { name: 'Servo 4', midpoint: 1500, min: 1000, max: 2000, rate: 50, amplitudeScale: 1.0 },
    ],
    pidGains: { roll_P: 4.0, roll_I: 0.03, roll_D: 23.0, pitch_P: 6.0, pitch_I: 0.04, pitch_D: 28.0, yaw_P: 3.0, yaw_I: 0.05, yaw_D: 0.0 },
    ondas: { cadence_gain: 30 },
    sticks: { throttle: 1500, roll: 1500, pitch: 1500, yaw: 1500 },
    connected: true,
    selectedServoIndex: 0,
    setStick: vi.fn(),
    setOndasParam: vi.fn(),
    setPidGain: vi.fn(),
    setServoParam: vi.fn(),
    selectServo: vi.fn(),
    bump: vi.fn(),
    applyPreset: vi.fn(),
  }),
}))

// Mock requestAnimationFrame
global.requestAnimationFrame = (cb) => setTimeout(cb, 0)
global.cancelAnimationFrame = (id) => clearTimeout(id)
