import { describe, it, expect, vi, beforeEach } from 'vitest'
import useSensorsStore from '../stores/useSensorsStore.coffee'

state = -> useSensorsStore.getState()

makeSession = ->
  {
    readSensorConfig: vi.fn -> Promise.resolve {
      accHardware: 2, baroHardware: 4, magHardware: 4
    }
    writeSensorConfig: vi.fn (config) -> Promise.resolve { config... }
    readSensorAlignment: vi.fn -> Promise.resolve {
      gyroAlign: 1, accAlign: 1, magAlign: 2, gyroDetectionFlags: 0
      gyroToUse: 0, gyro1Align: 1, gyro2Align: 1
    }
    writeSensorAlignment: vi.fn (alignment) ->
      Promise.resolve { alignment..., accAlign: alignment.gyroAlign }
    calibrateAccelerometer: vi.fn -> Promise.resolve true
    calibrateMagnetometer: vi.fn -> Promise.resolve true
  }

describe 'useSensorsStore', ->
  beforeEach -> state().reset()

  it 'starts in sim mode with the firmware-style defaults', ->
    expect(state().mode).toBe 'sim'
    expect(state().dirty).toBe false
    expect(state().draft.sensorConfig.accHardware).toBe 0
    expect(state().draft.sensorConfig.baroHardware).toBe 0
    expect(state().draft.sensorConfig.magHardware).toBe 0
    expect(state().draft.sensorAlignment.gyroAlign).toBe 0

  it 'patches the sensor config draft and marks it dirty', ->
    state().setSensorConfig { accHardware: 2, magHardware: 4 }
    expect(state().draft.sensorConfig).toMatchObject {
      accHardware: 2, magHardware: 4
    }
    expect(state().draft.sensorConfig.baroHardware).toBe 0
    expect(state().dirty).toBe true

  it 'clamps hardware ids to u8 range', ->
    state().setSensorConfig { accHardware: 999 }
    expect(state().draft.sensorConfig.accHardware).toBe 255

  it 'patches the sensor alignment draft', ->
    state().setSensorAlignment { gyroAlign: 2, magAlign: 4 }
    expect(state().draft.sensorAlignment.gyroAlign).toBe 2
    expect(state().draft.sensorAlignment.magAlign).toBe 4
    expect(state().dirty).toBe true

  it 'saves locally in sim mode (dry-run)', ->
    state().setSensorConfig { accHardware: 2 }
    saved = await state().save()
    expect(saved.sensorConfig.accHardware).toBe 2
    expect(state().dirty).toBe false

  it 'reverts to the saved document', ->
    state().setSensorAlignment { gyroAlign: 2 }
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft.sensorAlignment.gyroAlign).toBe(
      state().saved.sensorAlignment.gyroAlign
    )

  it 'loads from a device session and pins it', ->
    session = makeSession()
    state().attachSession session
    draft = await state().loadFromDevice()
    expect(state().mode).toBe 'device'
    expect(state().loadedSession).toBe session
    expect(draft.sensorConfig.accHardware).toBe 2
    expect(draft.sensorConfig.magHardware).toBe 4
    expect(state().dirty).toBe false

  it 'saves both sub-documents through the device session', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    state().setSensorConfig { accHardware: 3 }
    saved = await state().save()
    expect(session.writeSensorConfig).toHaveBeenCalledTimes 1
    expect(session.writeSensorAlignment).toHaveBeenCalledTimes 1
    expect(saved.sensorConfig.accHardware).toBe 3
    expect(state().dirty).toBe false

  it 'refuses to save against a stale session', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    state().attachSession makeSession()
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'Read device sensor configuration'
    expect(state().lastError).toContain 'Read device sensor configuration'

  it 'calibration requires a device session (sim throws)', ->
    error = await state().calibrateAccel().catch (error) -> error
    expect(error.message).toContain 'device session'
    expect(state().lastError).toContain 'device session'

  it 'runs one-shot calibration through the device session', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    expect(await state().calibrateAccel()).toBe true
    expect(session.calibrateAccelerometer).toHaveBeenCalledTimes 1
    expect(await state().calibrateMag()).toBe true
    expect(session.calibrateMagnetometer).toHaveBeenCalledTimes 1
    expect(state().lastError).toBeNull()

  it 'records session failures as lastError', ->
    session = makeSession()
    session.calibrateAccelerometer.mockImplementation ->
      Promise.reject new Error 'firmware refused'
    state().attachSession session
    await state().loadFromDevice()
    error = await state().calibrateAccel().catch (error) -> error
    expect(error.message).toBe 'firmware refused'
    expect(state().lastError).toBe 'firmware refused'
