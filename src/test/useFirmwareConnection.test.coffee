import { describe, it, expect } from 'vitest'
import {
  readConnectedServoConfigurations
  writeConnectedServoConfiguration
} from '../hooks/useFirmwareConnection.coffee'

describe 'useFirmwareConnection — servo configuration guards', ->
  it 'refuses to read servo configurations without a connection', ->
    await expect(readConnectedServoConfigurations()).rejects.toThrow(
      'No flight controller is connected'
    )

  it 'refuses to write a servo configuration without a connection', ->
    await expect(writeConnectedServoConfiguration 0, {}).rejects.toThrow(
      'No flight controller is connected'
    )
