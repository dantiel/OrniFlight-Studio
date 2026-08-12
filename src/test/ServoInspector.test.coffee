import { render, screen, fireEvent } from '@testing-library/react'
import { createElement as h } from 'react'
import { describe, it, expect, vi } from 'vitest'
import ServoInspector from '../components/panels/ServoInspector/ServoInspector.chaml'

makeServo = ->
  {
    name: 'Left Wing', midpoint: 1500, min: 1000,
    max: 2000, rate: 50, amplitudeScale: 1.0
  }
makePidGains = ->
  {
    roll_P: 8.0, roll_I: 0.02, roll_D: 15.0,
    pitch_P: 8.0, pitch_I: 0.02, pitch_D: 15.0,
    yaw_P: 6.0, yaw_I: 0.01, yaw_D: 10.0
  }
makeOndas = ->
  {
    cadence_gain: 50, ferocity_p_gain: 30, ferocity_d_gain: 20,
    balance_gain: 40, warp_gain: 25, anchor_gain: 35, resonance_gain: 45
  }

renderInspector = (props = {}) ->
  render h ServoInspector, {
    servo: makeServo(), index: 0,
    onParamChange: vi.fn(), pidGains: makePidGains(),
    onPidChange: vi.fn(), ondasParams: makeOndas(),
    onOndasChange: vi.fn(), props...
  }

describe 'ServoInspector', ->

  it 'renders servo heading with 1-based index', ->
    renderInspector()
    expect(screen.getByText(/Servo 1/)).toBeInTheDocument()

  it 'renders section headings', ->
    renderInspector()
    expect(screen.getByText 'PID Response').toBeInTheDocument()
    expect(screen.getByText 'ONDAS Mixer').toBeInTheDocument()

  it 'renders servo parameter labels', ->
    renderInspector()
    expect(screen.getByText 'Midpoint').toBeInTheDocument()
    expect(screen.getByText 'Min PWM').toBeInTheDocument()
    expect(screen.getByText 'Max PWM').toBeInTheDocument()
    expect(screen.getByText 'Rate').toBeInTheDocument()
    expect(screen.getByText 'Amplitude').toBeInTheDocument()

  it 'renders PID gain labels', ->
    renderInspector()
    expect(screen.getByText 'Roll P').toBeInTheDocument()
    expect(screen.getByText 'Pitch I').toBeInTheDocument()
    expect(screen.getByText 'Yaw D').toBeInTheDocument()

  it 'renders ONDAS parameter labels', ->
    renderInspector()
    expect(screen.getByText 'Cadence').toBeInTheDocument()
    expect(screen.getByText 'Ferocity P').toBeInTheDocument()
    expect(screen.getByText 'Resonance').toBeInTheDocument()

  it 'displays rate value with % suffix', ->
    renderInspector()
    expect(screen.getByText '50%').toBeInTheDocument()

  it 'displays amplitude value with 1 decimal', ->
    renderInspector()
    expect(screen.getByText '1.0').toBeInTheDocument()

  it 'calls onParamChange when servo slider moved', ->
    onParamChange = vi.fn()
    renderInspector { onParamChange }
    sliders = document.querySelectorAll '.param-slider'
    fireEvent.input sliders[0], { target: { value: '1550' } }
    expect(onParamChange).toHaveBeenCalledWith 0, 'midpoint', 1550

  it 'calls onPidChange when PID slider moved', ->
    onPidChange = vi.fn()
    renderInspector { onPidChange }
    sliders = document.querySelectorAll '.param-slider'
    fireEvent.input sliders[5], { target: { value: '8.5' } }
    expect(onPidChange).toHaveBeenCalledWith 'roll_P', 8.5

  it 'calls onOndasChange when ONDAS slider moved', ->
    onOndasChange = vi.fn()
    renderInspector { onOndasChange }
    sliders = document.querySelectorAll '.param-slider'
    fireEvent.input sliders[14], { target: { value: '60' } }
    expect(onOndasChange).toHaveBeenCalledWith 'cadence_gain', 60
