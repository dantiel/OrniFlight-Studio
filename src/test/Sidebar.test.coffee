import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi } from 'vitest'
import Sidebar from '../components/panels/Sidebar/Sidebar.chaml'

makeServos = (n) ->
  for i in [0...n]
    {
      name: "Servo #{i+1}", midpoint: 1500, min: 1000,
      max: 2000, rate: 50, amplitudeScale: 1.0
    }

makeSticks = -> { throttle: 1500, roll: 1500, pitch: 1500, yaw: 1500 }

renderSidebar = (props = {}) ->
  render h Sidebar, {
    servos: makeServos(4), selectedServoIndex: 0,
    onSelectServo: vi.fn(), sticks: makeSticks(),
    onStickChange: vi.fn(), onApplyPreset: vi.fn(), props...
  }

describe 'Sidebar', ->

  it 'renders all section headings', ->
    renderSidebar()
    expect(screen.getByText 'Wing Servos').toBeInTheDocument()
    expect(screen.getByText 'Pilot Input').toBeInTheDocument()
    expect(screen.getByText 'Flight Character').toBeInTheDocument()

  it 'renders all servo names', ->
    renderSidebar()
    expect(screen.getByText 'Servo 1').toBeInTheDocument()
    expect(screen.getByText 'Servo 4').toBeInTheDocument()

  it 'renders channel badges', ->
    renderSidebar()
    expect(screen.getByText 'CH1').toBeInTheDocument()
    expect(screen.getByText 'CH4').toBeInTheDocument()

  it 'marks selected servo as active', ->
    renderSidebar selectedServoIndex: 2
    activeItems = document.querySelectorAll '.sidebar-item.active'
    expect(activeItems.length).toBeGreaterThan 0

  it 'calls onSelectServo when clicking a servo', ->
    onSelectServo = vi.fn()
    renderSidebar { onSelectServo, servos: makeServos(3) }
    fireEvent.click screen.getByText 'Servo 3'
    expect(onSelectServo).toHaveBeenCalledWith 2

  it 'renders stick input sliders', ->
    renderSidebar servos: makeServos(2)
    sliders = document.querySelectorAll 'input[type="range"]'
    expect(sliders.length).toBe 4

  it 'renders stick labels', ->
    renderSidebar()
    expect(screen.getByText 'THR').toBeInTheDocument()
    expect(screen.getByText 'ROL').toBeInTheDocument()
    expect(screen.getByText 'PIT').toBeInTheDocument()
    expect(screen.getByText 'YAW').toBeInTheDocument()

  it 'calls onStickChange when slider moved', ->
    onStickChange = vi.fn()
    renderSidebar { onStickChange, servos: makeServos(2) }
    sliders = document.querySelectorAll 'input[type="range"]'
    fireEvent.input sliders[0], { target: { value: '1600' } }
    expect(onStickChange).toHaveBeenCalledWith 'throttle', 1600

  it 'renders preset buttons', ->
    renderSidebar()
    expect(screen.getByText 'Gentle').toBeInTheDocument()
    expect(screen.getByText 'Acro').toBeInTheDocument()
    expect(screen.getByText 'Race').toBeInTheDocument()

  it 'calls onApplyPreset when preset clicked', ->
    onApplyPreset = vi.fn()
    renderSidebar { onApplyPreset }
    fireEvent.click screen.getByText 'Acro'
    expect(onApplyPreset).toHaveBeenCalledWith 'acro'