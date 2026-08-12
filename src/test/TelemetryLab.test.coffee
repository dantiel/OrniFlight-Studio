import { render, screen } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi } from 'vitest'
import TelemetryLab from '../components/panels/TelemetryLab/TelemetryLab.chaml'

describe 'TelemetryLab', ->

  it 'renders section headings', ->
    gyro = { roll: 0, pitch: 0, yaw: 0 }
    render h TelemetryLab, { waveformHistory: [], gyro, servoPositions: [1500, 1500, 1500, 1500] }
    expect(screen.getByText 'Wing Rhythm').toBeInTheDocument()
    expect(screen.getByText 'Body Response').toBeInTheDocument()
    expect(screen.getByText 'Servo Voice').toBeInTheDocument()

  it 'renders channel labels CH1-CH4', ->
    gyro = { roll: 0, pitch: 0, yaw: 0 }
    render h TelemetryLab, { waveformHistory: [], gyro, servoPositions: [1500, 1500, 1500, 1500] }
    expect(screen.getByText 'CH1').toBeInTheDocument()
    expect(screen.getByText 'CH2').toBeInTheDocument()
    expect(screen.getByText 'CH3').toBeInTheDocument()
    expect(screen.getByText 'CH4').toBeInTheDocument()

  it 'displays servo PWM values', ->
    gyro = { roll: 0, pitch: 0, yaw: 0 }
    render h TelemetryLab, { waveformHistory: [], gyro, servoPositions: [1520, 1480, 1500, 1510] }
    expect(screen.getByText '1520').toBeInTheDocument()
    expect(screen.getByText '1480').toBeInTheDocument()

  it 'renders gyro rate labels', ->
    gyro = { roll: 0, pitch: 0, yaw: 0 }
    render h TelemetryLab, { waveformHistory: [], gyro, servoPositions: [1500, 1500, 1500, 1500] }
    expect(screen.getByText 'Rate Roll').toBeInTheDocument()
    expect(screen.getByText 'Rate Pitch').toBeInTheDocument()
    expect(screen.getByText 'Rate Yaw').toBeInTheDocument()

  it 'formats gyro rate values', ->
    gyro = { roll: 1.0, pitch: 0.5, yaw: -0.3 }
    render h TelemetryLab, { waveformHistory: [], gyro, servoPositions: [1500, 1500, 1500, 1500] }
    expect(screen.getByText '1.0').toBeInTheDocument()
    expect(screen.getByText '0.5').toBeInTheDocument()
    expect(screen.getByText '-0.3').toBeInTheDocument()

  it 'handles undefined gyro gracefully', ->
    render h TelemetryLab, { waveformHistory: [], servoPositions: [1500, 1500, 1500, 1500] }
    els = screen.getAllByText '0.0'
    expect(els.length).toBeGreaterThanOrEqual 3

  it 'handles undefined servo positions', ->
    gyro = { roll: 0, pitch: 0, yaw: 0 }
    render h TelemetryLab, { waveformHistory: [], gyro }
    els = screen.getAllByText '0'
    expect(els.length).toBeGreaterThanOrEqual 4

  it 'renders telemetry lab structure', ->
    gyro = { roll: 0, pitch: 0, yaw: 0 }
    render h TelemetryLab, { waveformHistory: [], gyro, servoPositions: [1500, 1500, 1500, 1500] }
    el = document.querySelector '.studio-telemetry-lab'
    expect(el).toBeInTheDocument()
