###
# ORNIFLIGHT STUDIO — GyroDisturb
#
# The configurator-style disturbance rig for the 3D bird: a strength
# slider governing both the random DISTURB pulse and the right-drag
# torque, plus a RESET that re-levels the rigid body. Rendered only
# inside the 3D bird stage of PlotDeck so the gyro can be poked and
# watched settle under the ONDAS/PID stabilization.
###
import h from '../../../app/h.coffee'
import useEngineStore from '../../../stores/useEngineStore.coffee'
import { useI18n } from '../../../i18n/index.coffee'

GyroDisturb = ->
  { t } = useI18n()
  disturbForce = useEngineStore (s) -> s.disturbForce
  setDisturbForce = useEngineStore (s) -> s.setDisturbForce
  bump = useEngineStore (s) -> s.bump
  resetAttitude = useEngineStore (s) -> s.resetAttitude

  h 'div', { className: 'gyro-disturb' },
    h 'span', { className: 'gyro-disturb-hint' }, t('schlagdynamik.disturbHint')
    h 'div', { className: 'gyro-disturb-row' },
      h 'label', { className: 'gyro-disturb-field' },
        h 'span', { className: 'gyro-disturb-label' },
          t('schlagdynamik.disturbForce')
        h 'input', {
          className: 'gyro-disturb-slider'
          type: 'range'
          min: '0'
          max: '400'
          step: '5'
          value: String(disturbForce)
          onInput: (e) -> setDisturbForce Number(e.target.value)
        }
        h 'span', { className: 'gyro-disturb-value' },
          String(Math.round(disturbForce))
      h 'button',
        className: 'gyro-disturb-btn'
        type: 'button'
        onClick: -> bump()
      , t('schlagdynamik.disturbBtn')
      h 'button',
        className: 'gyro-disturb-btn gyro-disturb-reset'
        type: 'button'
        onClick: -> resetAttitude()
      , t('schlagdynamik.resetAttitude')

export default GyroDisturb
