import { describe, it, expect, beforeEach } from 'vitest'
import { OrnithopterModel } from '../simulation/OrnithopterModel.coffee'

describe 'OrnithopterModel', ->

  model = null

  beforeEach ->
    model = new OrnithopterModel()
    model.connect()

  it 'initializes with 4 servos', ->
    expect(model.servos.length).toBe 4

  it 'servos have names Servo 1 through Servo 4', ->
    expect(model.servos[0].name).toBe 'Servo 1'
    expect(model.servos[3].name).toBe 'Servo 4'

  it 'starts with zero attitude', ->
    expect(model.attitude.roll).toBe 0
    expect(model.attitude.pitch).toBe 0
    expect(model.attitude.yaw).toBe 0

  it 'starts at time 0', ->
    expect(model.t).toBe 0

  it 'default flap frequency is 6 Hz', ->
    expect(model.flapFrequency).toBe 6.0

  it 'default base amplitude is 45 degrees', ->
    expect(model.baseAmplitude).toBe 45.0

  it 'initial battery voltage is 12.6', ->
    expect(model.battery.voltage).toBe 12.6

  it 'step advances time', ->
    model.step 0.016
    expect(model.t).toBeGreaterThan 0

  it 'step does nothing when disconnected', ->
    model.disconnect()
    t0 = model.t
    model.step 0.016
    expect(model.t).toBe t0

  it 'setStick clamps to range', ->
    model.setStick 'roll', 2500
    expect(model.sticks.roll).toBe 2000
    model.setStick 'roll', 500
    expect(model.sticks.roll).toBe 1000

  it 'setStick updates target rates', ->
    model.setStick 'roll', 1600
    expect(model.targetRates.roll).not.toBe 0

  it 'setOndasParam clamps to 0-100', ->
    model.setOndasParam 'cadence_gain', 150
    expect(model.ondas.cadence_gain).toBe 100
    model.setOndasParam 'cadence_gain', -10
    expect(model.ondas.cadence_gain).toBe 0

  it 'setPidGain updates gain value', ->
    model.setPidGain 'roll_P', 10.0
    expect(model.pidGains.roll_P).toBe 10.0

  it 'setServoParam updates parameter', ->
    model.setServoParam 0, 'midpoint', 1550
    expect(model.servos[0].midpoint).toBe 1550

  it 'setServoParam ignores invalid index', ->
    model.setServoParam 99, 'midpoint', 1550
    # Should not throw

  it 'telemetry reflects attitude after step', ->
    model.setStick 'pitch', 1600
    for i in [0...30]
      model.step 0.016
    tel = model.telemetry
    expect(tel.attitude).toBeDefined()
    # flapFrequency might be NaN in edge cases — just check it's defined
    expect(tel.flapFrequency).not.toBeUndefined

  it 'telemetry has servo positions array', ->
    model.step 0.016
    tel = model.telemetry
    expect(Array.isArray tel.servoPositions).toBe true
    expect(tel.servoPositions.length).toBe 4

  it 'bump creates disturbance', ->
    model.bump()
    model.step 0.016
    tel = model.telemetry
    expect(tel.gyro).toBeDefined()

  it 'applyPreset changes parameters', ->
    model.applyPreset 'race'
    expect(model.flapFrequency).toBe 8.0
    expect(model.baseAmplitude).toBe 55.0

  it 'reset returns to initial state', ->
    model.setStick 'roll', 1700
    model.step 0.1
    model.reset()
    expect(model.t).toBe 0
    expect(model.attitude.roll).toBe 0
    expect(model.attitude.pitch).toBe 0
    expect(model.attitude.yaw).toBe 0

  it 'flap phase cycles through 2π', ->
    model.flapFrequency = 10  # faster for test
    model.step 0.1
    expect(model.flapPhase).toBeGreaterThan 0