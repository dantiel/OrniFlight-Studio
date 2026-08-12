import './AircraftViewport.sass'
import { useEffect, useRef, createElement } from 'react'
import * as THREE from 'three'
import FlightTrail from './FlightTrail.coffee'
import AttitudeRings from './AttitudeRings.coffee'

# ═══════════════════════════════════════════════════════════════
# 3D Ornithopter Viewport — renders the aircraft model
# Tier 2: FlightTrail (path trace) + AttitudeRings (holographic)
# Receives attitude + wing angles from telemetry snapshot.
# ═══════════════════════════════════════════════════════════════

AircraftViewport = ({
  attitude, wingAngleL, wingAngleR, onBump, flapFrequency
}) ->

  mountRef = useRef null
  sceneRef = useRef null
  rendererRef = useRef null
  cameraRef = useRef null
  modelRef = useRef null
  wingPivotLRef = useRef null
  wingPivotRRef = useRef null
  wingMeshLRef = useRef null
  wingMeshRRef = useRef null
  animRef = useRef null
  trailRef = useRef null
  ringsRef = useRef null
  frameCount = useRef 0

  # ── Init THREE ──────────────────────────────────────────
  useEffect ->
    el = mountRef.current
    return unless el

    w = el.clientWidth
    h = el.clientHeight

    # Renderer
    renderer = new THREE.WebGLRenderer antialias: true, alpha: true
    renderer.setSize w, h
    renderer.setPixelRatio Math.min(window.devicePixelRatio, 2)
    renderer.setClearColor 0x000000, 0
    el.appendChild renderer.domElement
    rendererRef.current = renderer

    # Scene
    scene = new THREE.Scene()
    sceneRef.current = scene

    # Camera
    camera = new THREE.PerspectiveCamera 45, w / h, 0.1, 100
    camera.position.set 0.5, 0.35, 2.4
    camera.lookAt 0, 0, 0
    cameraRef.current = camera

    # Lighting
    scene.add new THREE.AmbientLight 0x334466, 1.8
    key = new THREE.DirectionalLight 0xffcc88, 2.0
    key.position.set 3, 5, 4
    scene.add key
    rim = new THREE.DirectionalLight 0x6688cc, 0.8
    rim.position.set -2, 1, -3
    scene.add rim
    fill = new THREE.DirectionalLight 0x446688, 0.5
    fill.position.set 0, -0.5, 1
    scene.add fill

    # Ground reference grid
    grid = new THREE.GridHelper 5, 10, 0x334466, 0x1c2333
    grid.position.y = -1.0
    scene.add grid

    # ═══════════════════════════════════════════════════
    # ORNITHOPTER MODEL
    # ═══════════════════════════════════════════════════
    model = new THREE.Group()
    model.scale.set 1.4, 1.4, 1.4
    scene.add model
    modelRef.current = model

    # Materials
    bodyMat = new THREE.MeshStandardMaterial
      color: 0xff8830
      roughness: 0.35
      metalness: 0.15
    wingMat = new THREE.MeshStandardMaterial
      color: 0xff9930
      roughness: 0.5
      metalness: 0.05
      side: THREE.DoubleSide
    darkMat = new THREE.MeshStandardMaterial
      color: 0xcc6620
      roughness: 0.45
      metalness: 0.1
    accentMat = new THREE.MeshStandardMaterial
      color: 0x445566
      roughness: 0.3
      metalness: 0.6

    # Fuselage
    fuseGroup = new THREE.Group()
    fuseGroup.rotation.x = Math.PI / 2
    bodyGeo = new THREE.CylinderGeometry 0.1, 0.14, 0.65, 12, 4
    fuseGroup.add new THREE.Mesh bodyGeo, bodyMat
    noseGeo = new THREE.CylinderGeometry 0.01, 0.1, 0.16, 12, 4
    nose = new THREE.Mesh noseGeo, bodyMat
    nose.position.set 0, 0.4, 0
    fuseGroup.add nose
    tailConeGeo = new THREE.CylinderGeometry 0.14, 0.04, 0.22, 12, 4
    tailCone = new THREE.Mesh tailConeGeo, bodyMat
    tailCone.position.set 0, -0.43, 0
    fuseGroup.add tailCone
    model.add fuseGroup

    # Wing pivots
    wingPivotL = new THREE.Group()
    wingPivotL.position.set 0.15, 0.03, 0.05
    model.add wingPivotL
    wingPivotLRef.current = wingPivotL

    wingPivotR = new THREE.Group()
    wingPivotR.position.set -0.15, 0.03, 0.05
    model.add wingPivotR
    wingPivotRRef.current = wingPivotR

    # Wings
    wingShape = new THREE.Shape()
    wingShape.moveTo 0, 0
    wingShape.bezierCurveTo 0.35, 0.05, 0.7, 0.02, 0.85, -0.08
    wingShape.bezierCurveTo 0.7, -0.03, 0.35, -0.01, 0, -0.04
    wingShape.closePath()
    extrudeSettings =
      steps: 1
      depth: 0.2
      bevelEnabled: true
      bevelThickness: 0.01
      bevelSize: 0.01
      bevelSegments: 3
    wingGeo = new THREE.ExtrudeGeometry wingShape, extrudeSettings
    wingGeo.translate 0, 0, -0.1

    wingMeshL = new THREE.Mesh wingGeo, wingMat
    wingMeshL.castShadow = true
    wingPivotL.add wingMeshL
    wingMeshLRef.current = wingMeshL

    wingMeshR = new THREE.Mesh wingGeo, wingMat
    wingMeshR.castShadow = true
    wingMeshR.rotation.y = PI = Math.PI
    wingPivotR.add wingMeshR
    wingMeshRRef.current = wingMeshR

    # Tail surfaces
    hstabGeo = new THREE.BoxGeometry 0.45, 0.012, 0.1
    hstab = new THREE.Mesh hstabGeo, darkMat
    hstab.position.set 0, 0.02, -0.58
    model.add hstab

    vfinGeo = new THREE.BoxGeometry 0.012, 0.12, 0.09
    vfin = new THREE.Mesh vfinGeo, accentMat
    vfin.position.set 0, 0.07, -0.58
    model.add vfin

    # Servo mounts (small visual indicators)
    mountGeo = new THREE.CylinderGeometry 0.03, 0.03, 0.04, 6
    for side in [-1, 1]
      mount = new THREE.Mesh mountGeo, accentMat
      mount.position.set side * 0.15, -0.02, 0.05
      mount.rotation.x = Math.PI / 2
      model.add mount

    # Center reference dot
    dotGeo = new THREE.SphereGeometry 0.04, 8, 8
    dotMat = new THREE.MeshBasicMaterial color: 0xffaa44
    dot = new THREE.Mesh dotGeo, dotMat
    model.add dot

    # ── Resize handler ───────────────────────────────────
    resize = ->
      return unless renderer and mountRef.current
      pw = mountRef.current.clientWidth
      ph = mountRef.current.clientHeight
      if pw > 0 and ph > 0
        renderer.setSize pw, ph
        camera.aspect = pw / ph
        camera.updateProjectionMatrix()

    window.addEventListener 'resize', resize

    # ── Click → bump ─────────────────────────────────────
    handleClick = -> onBump?()
    el.addEventListener 'click', handleClick

    # ── Flight trail + attitude rings ────────────────────
    trailRef.current = FlightTrail scene
    ringsRef.current = AttitudeRings scene

    # ── Render loop ──────────────────────────────────────
    render = ->
      animRef.current = requestAnimationFrame render
      frameCount.current += 1
      # Push trail every 3rd frame (~20 Hz)
      if frameCount.current % 3 == 0 and modelRef.current
        pos = modelRef.current.position
        trailRef.current.push pos.x, pos.y, pos.z
        trailRef.current.update()
      renderer.render scene, camera
    render()

    ->
      cancelAnimationFrame animRef.current if animRef.current
      window.removeEventListener 'resize', resize
      el.removeEventListener 'click', handleClick
      trailRef.current?.dispose()
      ringsRef.current?.dispose()
      renderer.dispose()
      if el.contains renderer.domElement
        el.removeChild renderer.domElement
  , []

  # ── Update model transforms from props ──────────────────
  useEffect ->
    hasRefs =
      modelRef.current and wingPivotLRef.current and wingPivotRRef.current
    return unless hasRefs

    roll  = attitude?.roll  or 0
    pitch = attitude?.pitch or 0
    yaw   = attitude?.yaw   or 0
    wl    = wingAngleL or 0
    wr    = wingAngleR or 0

    modelRef.current.rotation.set roll, yaw, -pitch
    wingPivotLRef.current.rotation.z = wl
    wingPivotRRef.current.rotation.z = -wr
    ringsRef.current?.update { roll, pitch, yaw }
    return
  , [attitude, wingAngleL, wingAngleR]

  # ── Render mount ───────────────────────────────────────
  createElement 'div', { className: 'viewport-canvas', ref: mountRef }

export default AircraftViewport