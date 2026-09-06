import { create } from 'zustand'
import { devtools } from 'zustand/middleware'

useDeviceStore = create(
  devtools(
    (set) ->
      source: 'simulation'
      identity: null
      status: null
      receiverChannels: []
      servoOutputs: []
      lastError: null
      setConnecting: -> set { source: 'connecting', lastError: null }
      setDevice: (identity) -> set { source: 'device', identity, status: identity.status, lastError: null }
      setStatus: (status) -> set { status }
      setLiveData: (receiverChannels, servoOutputs) -> set { receiverChannels, servoOutputs }
      setOffline: -> set { source: 'offline' }
      setSimulation: -> set { source: 'simulation', lastError: null }
      setError: (error) -> set {
        source: 'offline'
        lastError: error?.message or String(error or 'Connection failed')
      }
    ,
    name: '🛩 DeviceStore'
  )
)

export default useDeviceStore