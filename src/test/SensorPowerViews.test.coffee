import { render, screen, fireEvent, waitFor } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest'
import SensorsView from '../components/views/SensorsView/SensorsView.coffee'
import PowerView from '../components/views/PowerView/PowerView.coffee'
import AdjustmentsView from '../components/views/AdjustmentsView/AdjustmentsView.coffee'
import useSensorsStore from '../stores/useSensorsStore.coffee'
import usePowerStore from '../stores/usePowerStore.coffee'
import useAdjustmentsStore from '../stores/useAdjustmentsStore.coffee'

sensorState = -> useSensorsStore.getState()
powerState = -> usePowerStore.getState()
adjustmentState = -> useAdjustmentsStore.getState()

describe 'Sensors, Power & Adjustments views', ->
  beforeEach ->
    vi.spyOn window, 'requestAnimationFrame', -> 1
    sensorState().reset()
    powerState().reset()
    adjustmentState().reset()

  afterEach -> vi.restoreAllMocks()

  it 'renders the sensors view with panels and sim defaults', ->
    render h SensorsView, null
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Sensors').toBeInTheDocument()
    expect(screen.getByText 'Sensor Hardware').toBeInTheDocument()
    expect(screen.getByText 'Board Alignment').toBeInTheDocument()
    expect(screen.getByText 'Calibration').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeDisabled()
    expect(screen.getByText 'Save').toBeEnabled()
    expect(screen.getByText 'Revert').toBeDisabled()
    expect(screen.getByText 'Calibrate Accelerometer').toBeDisabled()
    expect(screen.getByText 'Calibrate Magnetometer').toBeDisabled()

  it 'patches the sensor draft through a hardware select', ->
    render h SensorsView, null
    selects = document.querySelectorAll '.sensors-select'
    fireEvent.change selects[0], { target: { value: '2' } }
    expect(sensorState().draft.sensorConfig.accHardware).toBe 2
    expect(screen.getByText 'DIRTY').toBeInTheDocument()

  it 'commits locally in sim mode through the sensors save button', ->
    render h SensorsView, null
    sensorState().setSensorConfig { accHardware: 3 }
    fireEvent.click screen.getByText 'Save'
    await waitFor ->
      expect(sensorState().saved.sensorConfig.accHardware).toBe 3
    expect(sensorState().dirty).toBe false

  it 'renders the power view with the three meter documents', ->
    render h PowerView, null
    expect(screen.getByText 'SIMULATION').toBeInTheDocument()
    expect(screen.getByText 'Power').toBeInTheDocument()
    expect(screen.getByText 'Battery').toBeInTheDocument()
    expect(screen.getByText 'Meters').toBeInTheDocument()
    expect(screen.getByLabelText 'Minimum cell voltage (0.01 V)').toBeInTheDocument()
    expect(screen.getByText 'Read device').toBeDisabled()

  it 'patches the battery draft through the capacity input', ->
    render h PowerView, null
    input = screen.getByLabelText 'Capacity (mAh)'
    fireEvent.change input, { target: { value: '4500' } }
    expect(powerState().draft.battery.capacityMah).toBe 4500

  it 'renders the adjustments view with 30 slot rows', ->
    render h AdjustmentsView, null
    expect(screen.getByText 'Adjustments').toBeInTheDocument()
    expect(document.querySelectorAll '.adjustment-row').toHaveLength 30

  it 'patches an adjustment slot through its function select', ->
    render h AdjustmentsView, null
    selects = document.querySelectorAll '.adjustment-select'
    fireEvent.change selects[0], { target: { value: '5' } }
    expect(adjustmentState().draft.ranges[0].adjustmentConfig).toBe 5
    expect(screen.getByText 'DIRTY').toBeInTheDocument()