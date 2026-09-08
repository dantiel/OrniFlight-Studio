import { describe, it, expect, vi, beforeEach } from 'vitest'
import usePowerStore from '../stores/usePowerStore.coffee'

state = -> usePowerStore.getState()

makeSession = ->
  {
    readBatteryConfig: vi.fn -> Promise.resolve {
      minCellVoltage: 330, maxCellVoltage: 430, warningCellVoltage: 350
      capacityMah: 0, voltageMeterSource: 0, currentMeterSource: 0
    }
    writeBatteryConfig: vi.fn (config) -> Promise.resolve { config... }
    readVoltageMeterConfig: vi.fn -> Promise.resolve {
      id: 10, type: 0, scale: 110, dividerValue: 10, dividerMultiplier: 1
    }
    writeVoltageMeterConfig: vi.fn (meter) ->
      Promise.resolve { meter..., type: 0 }
    readCurrentMeterConfig: vi.fn -> Promise.resolve {
      id: 10, type: 1, scale: 400, offset: 0
    }
    writeCurrentMeterConfig: vi.fn (meter) ->
      Promise.resolve { meter..., type: 1 }
  }

describe 'usePowerStore', ->
  beforeEach -> state().reset()

  it 'starts in sim mode with firmware-style defaults', ->
    expect(state().mode).toBe 'sim'
    expect(state().draft.battery.minCellVoltage).toBe 330
    expect(state().draft.battery.maxCellVoltage).toBe 430
    expect(state().draft.battery.warningCellVoltage).toBe 350
    expect(state().draft.voltageMeter.scale).toBe 110
    expect(state().draft.currentMeter.scale).toBe 400

  it 'patches and clamps the battery draft', ->
    state().setBattery { minCellVoltage: 70000, capacityMah: 4500 }
    expect(state().draft.battery.minCellVoltage).toBe 65535
    expect(state().draft.battery.capacityMah).toBe 4500
    expect(state().dirty).toBe true

  it 'patches the voltage and current meter drafts', ->
    state().setVoltageMeter { scale: 200 }
    state().setCurrentMeter { scale: 350, offset: 10 }
    expect(state().draft.voltageMeter.scale).toBe 200
    expect(state().draft.currentMeter.scale).toBe 350
    expect(state().draft.currentMeter.offset).toBe 10
    expect(state().dirty).toBe true

  it 'saves locally in sim mode (dry-run)', ->
    state().setBattery { capacityMah: 2000 }
    saved = await state().save()
    expect(saved.battery.capacityMah).toBe 2000
    expect(state().dirty).toBe false

  it 'reverts to the saved document', ->
    state().setVoltageMeter { scale: 220 }
    state().revert()
    expect(state().dirty).toBe false
    expect(state().draft.voltageMeter.scale).toBe(
      state().saved.voltageMeter.scale
    )

  it 'loads all three documents from a device session', ->
    session = makeSession()
    state().attachSession session
    draft = await state().loadFromDevice()
    expect(state().loadedSession).toBe session
    expect(draft.battery.minCellVoltage).toBe 330
    expect(draft.voltageMeter.id).toBe 10
    expect(draft.currentMeter.scale).toBe 400

  it 'saves all three documents through the device session', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    state().setCurrentMeter { scale: 500 }
    saved = await state().save()
    expect(session.writeBatteryConfig).toHaveBeenCalledTimes 1
    expect(session.writeVoltageMeterConfig).toHaveBeenCalledTimes 1
    expect(session.writeCurrentMeterConfig).toHaveBeenCalledTimes 1
    expect(saved.currentMeter.scale).toBe 500
    expect(state().dirty).toBe false

  it 'refuses to save against a stale session', ->
    session = makeSession()
    state().attachSession session
    await state().loadFromDevice()
    state().attachSession makeSession()
    error = await state().save().catch (error) -> error
    expect(error.message).toContain 'Read device power configuration'
    expect(state().lastError).toContain 'Read device power configuration'

  it 'records read failures as lastError', ->
    session = makeSession()
    session.readBatteryConfig.mockImplementation ->
      Promise.reject new Error 'battery read failed'
    state().attachSession session
    error = await state().loadFromDevice().catch (error) -> error
    expect(error.message).toBe 'battery read failed'
    expect(state().lastError).toBe 'battery read failed'
