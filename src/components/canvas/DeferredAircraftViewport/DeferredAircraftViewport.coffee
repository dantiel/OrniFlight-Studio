import './DeferredAircraftViewport.sass'
import { lazy, Suspense } from 'react'
import h from '../../../app/h.coffee'

# Three.js and the bird scene stay out of the initial Studio bundle. The
# surrounding workspace renders first; WebGL arrives only in views that use it.
AircraftViewport = lazy -> import('../AircraftViewport/AircraftViewport.coffee')

DeferredAircraftViewport = (props) ->
  h Suspense, {
    fallback: h 'div', { className: 'aircraft-deferred-placeholder', role: 'status' },
      h('span', { className: 'aircraft-deferred-mark' }, '◇'),
      h('span', null, 'Loading flight preview…')
  }, h(AircraftViewport, props)

export default DeferredAircraftViewport