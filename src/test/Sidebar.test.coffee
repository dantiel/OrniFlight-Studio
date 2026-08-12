import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi } from 'vitest'
import Sidebar from '../components/panels/Sidebar/Sidebar.chaml'

makeServos = (n) ->
  for i in [0...n]
    { name: "Servo #{i+1}", midpoint: 1500, min: 1000, max: 2000, rate: 50, amplitudeScale: 1.0 }

makeSticks = -> { throttle: 1500, roll: 1500, pitch: 1500, yaw: 1500 }

describe 'Sidebar', ->

  it 'renders all section headings', ->
    servos = makeServos 4
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    expect(screen.getByText 'Wing Servos').toBeInTheDocument()
    expect(screen.getByText 'Pilot Input').toBeInTheDocument()
    expect(screen.getByText 'Flight Character').toBeInTheDocument()

  it 'renders all servo names', ->
    servos = makeServos 4
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    expect(screen.getByText 'Servo 1').toBeInTheDocument()
    expect(screen.getByText 'Servo 4').toBeInTheDocument()

  it 'renders channel badges', ->
    servos = makeServos 4
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    expect(screen.getByText 'CH1').toBeInTheDocument()
    expect(screen.getByText 'CH4').toBeInTheDocument()

  it 'marks selected servo as active', ->
    servos = makeServos 4
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 2, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    activeItems = document.querySelectorAll '.sidebar-item.active'
    expect(activeItems.length).toBeGreaterThan 0

  it 'calls onSelectServo when clicking a servo', ->
    servos = makeServos 3
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    fireEvent.click screen.getByText 'Servo 3'
    expect(onSelectServo).toHaveBeenCalledWith 2

  it 'renders stick input sliders', ->
    servos = makeServos 2
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    sliders = document.querySelectorAll 'input[type="range"]'
    expect(sliders.length).toBe 4

  it 'renders stick labels', ->
    servos = makeServos 2
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    expect(screen.getByText 'THR').toBeInTheDocument()
    expect(screen.getByText 'ROL').toBeInTheDocument()
    expect(screen.getByText 'PIT').toBeInTheDocument()
    expect(screen.getByText 'YAW').toBeInTheDocument()

  it 'calls onStickChange when slider moved', ->
    servos = makeServos 2
    onSelectServo = vi.fn()
    onStickChange = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange, onApplyPreset: vi.fn() }
    sliders = document.querySelectorAll 'input[type="range"]'
    fireEvent.input sliders[0], { target: { value: '1600' } }
    expect(onStickChange).toHaveBeenCalledWith 'throttle', 1600

  it 'renders preset buttons', ->
    servos = makeServos 2
    onSelectServo = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset: vi.fn() }
    expect(screen.getByText 'Gentle').toBeInTheDocument()
    expect(screen.getByText 'Acro').toBeInTheDocument()
    expect(screen.getByText 'Race').toBeInTheDocument()

  it 'calls onApplyPreset when preset clicked', ->
    servos = makeServos 2
    onSelectServo = vi.fn()
    onApplyPreset = vi.fn()
    render h Sidebar, { servos, selectedServoIndex: 0, onSelectServo, sticks: makeSticks(), onStickChange: vi.fn(), onApplyPreset }
    fireEvent.click screen.getByText 'Acro'
    expect(onApplyPreset).toHaveBeenCalledWith 'acro'