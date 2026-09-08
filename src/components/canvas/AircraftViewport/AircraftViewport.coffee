import './AircraftViewport.sass'
import { useEffect, useRef, createElement } from 'react'
import * as THREE from 'three'
import FlightTrail from './FlightTrail.coffee'
import AttitudeRings from './AttitudeRings.coffee'

# ═══════════════════════════════════════════════════════════════
# 3D Ornithopter Viewport — renders the aircraft model.
# Multi-pair wings: pairCount + per-pair servo mounts (fore/aft
# station, vertical station, mount angle, phase shift) drive a
# staggered, dihedral flapping rig. Aeroelastic coefficients add
# wing twist along the flap cycle. Receives attitude + wing angles
# + flap phase from the telemetry snapshot.
# ═══════════════════════════════════════════════════════════════

PI = Math.PI

AircraftViewport = ({
  attitude, wingAngleL, wingAngleR, flapFrequency, flapPhase,
  amplitude, pairCount, servoMounts,
  aeroelasticFlapCoefficient, aeroelasticGlideCoefficient, onBump
}) ->

  mountRef = useRef null
  sceneRef = useRef null
  rendererRef = useRef null
  cameraRef = useRef null
  modelRef = useRef null
  pairRefs = useRef []
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

    renderer = new THREE.WebGLRenderer antialias: true, alpha: true
    renderer.setSize w, h
    renderer.setPixelRatio Math.min(window.devicePixelRatio, 2)
    renderer.setClearColor 0x000000, 0
    renderer.shadowMap.enabled = true
    renderer.shadowMap.type = THREE.PCFSoftShadowMap
    el.appendChild renderer.domElement
    rendererRef.current = renderer

    scene = new THREE.Scene()
    scene.fog = new THREE.FogExp2 0x0a0e14, 0.06
    sceneRef.current = scene

    camera = new THREE.PerspectiveCamera 45, w / h, 0.1, 100
    camera.position.set 0.5, 0.35, 2.4
    camera.lookAt 0, 0, 0
    cameraRef.current = camera

    # Lighting — warm key, cool rim, soft hemisphere fill.
    scene.add new THREE.HemisphereLight 0x334466, 0x1a1208, 1.2
    key = new THREE.DirectionalLight 0xffcc88, 2.2
    key.position.set 3, 5, 4
    key.castShadow = true
    scene.add key
    rim = new THREE.DirectionalLight 0x6688cc, 1.0
    rim.position.set -2, 1, -3
    scene.add rim
    fill = new THREE.DirectionalLight 0x446688, 0.5
    fill.position.set 0, -0.5, 1
    scene.add fill

    grid = new THREE.GridHelper 5, 10, 0x2a3a55, 0x141b28
    grid.position.y = -1.0
    scene.add grid

    # ── Materials ─────────────────────────────────────────
    bodyMat = new THREE.MeshStandardMaterial
      color: 0xff8830, roughness: 0.32, metalness: 0.18
    wingMat = new THREE.MeshStandardMaterial
      color: 0xff9930, roughness: 0.5, metalness: 0.06, side: THREE.DoubleSide
    wingTipMat = new THREE.MeshStandardMaterial
      color: 0xcc6620, roughness: 0.45, metalness: 0.08, side: THREE.DoubleSide
    darkMat = new THREE.MeshStandardMaterial
      color: 0xcc6620, roughness: 0.45, metalness: 0.1
    accentMat = new THREE.MeshStandardMaterial
      color: 0x445566, roughness: 0.28, metalness: 0.62

    model = new THREE.Group()
    model.scale.set 1.4, 1.4, 1.4
    scene.add model
    modelRef.current = model

    # ── Fuselage ──────────────────────────────────────────
    fuseGroup = new THREE.Group()
    fuseGroup.rotation.x = PI / 2
    bodyGeo = new THREE.CylinderGeometry 0.1, 0.14, 0.65, 16, 4
    fuseGroup.add new THREE.Mesh bodyGeo, bodyMat
    noseGeo = new THREE.CylinderGeometry 0.01, 0.1, 0.16, 16, 4
    nose = new THREE.Mesh noseGeo, bodyMat
    nose.position.set 0, 0.4, 0
    fuseGroup.add nose
    tailConeGeo = new THREE.CylinderGeometry 0.14, 0.04, 0.22, 16, 4
    tailCone = new THREE.Mesh tailConeGeo, bodyMat
    tailCone.position.set 0, -0.43, 0
    fuseGroup.add tailCone
    model.add fuseGroup

    # ── Shared wing geometry (tapered, swept) ─────────────
    wingShape = new THREE.Shape()
    wingShape.moveTo 0, 0
    wingShape.bezierCurveTo 0.35, 0.05, 0.7, 0.02, 0.85, -0.08
    wingShape.bezierCurveTo 0.7, -0.03, 0.35, -0.01, 0, -0.04
    wingShape.closePath()
    wingGeo = new THREE.ExtrudeGeometry wingShape,
      steps: 1, depth: 0.2, bevelEnabled: true
      bevelThickness: 0.01, bevelSize: 0.01, bevelSegments: 3
    wingGeo.translate 0, 0, -0.1

    # ── Build N wing pairs from servo mounts ──────────────
    n = Math.max 1, Number(pairCount) or 2
    mounts = servoMounts or []
    pairs = []
    for i in [0...n]
      mount = mounts[i] ? {}
      zStation = Number(mount.z) or 0
      yStation = Number(mount.y) or 0
      mountAngle = (Number(mount.angle) or 0) * PI / 180
      phaseShift = Number(mount.phaseShift) or (i * 0.6)

      pair = new THREE.Group()
      # Fore/aft + vertical station along the fuselage.
      pair.position.set 0, yStation * 0.12, zStation * 0.55
      model.add pair

      pivotL = new THREE.Group()
      pivotL.position.set 0.16, 0.03, 0
      pivotL.rotation.x = mountAngle   # dihedral from mount angle
      pair.add pivotL

      pivotR = new THREE.Group()
      pivotR.position.set -0.16, 0.03, 0
      pivotR.rotation.x = -mountAngle
      pair.add pivotR

      wingL = new THREE.Mesh wingGeo, if i % 2 == 0 then wingMat else wingTipMat
      wingL.castShadow = true
      pivotL.add wingL

      wingR = new THREE.Mesh wingGeo, if i % 2 == 0 then wingMat else wingTipMat
      wingR.castShadow = true
      wingR.rotation.y = PI
      pivotR.add wingR

      pairs.push {
        pivotL, pivotR, wingL, wingR, mountAngle, phaseShift, zStation
      }

    pairRefs.current = pairs

    # ── Tail surfaces ─────────────────────────────────────
    hstabGeo = new THREE.BoxGeometry 0.45, 0.012, 0.1
    hstab = new THREE.Mesh hstabGeo, darkMat
    hstab.position.set 0, 0.02, -0.58
    model.add hstab

    vfinGeo = new THREE.BoxGeometry 0.012, 0.12, 0.09
    vfin = new THREE.Mesh vfinGeo, accentMat
    vfin.position.set 0, 0.07, -0.58
    model.add vfin

    dotGeo = new THREE.SphereGeometry 0.04, 8, 8
    dotMat = new THREE.MeshBasicMaterial color: 0xffaa44
    dot = new THREE.Mesh dotGeo, dotMat
    model.add dot

    # ── Resize / click / trail / rings ────────────────────
    resize = ->
      return unless renderer and mountRef.current
      pw = mountRef.current.clientWidth
      ph = mountRef.current.clientHeight
      if pw > 0 and ph > 0
        renderer.setSize pw, ph
        camera.aspect = pw / ph
        camera.updateProjectionMatrix()

    window.addEventListener 'resize', resize
    handleClick = -> onBump?()
    el.addEventListener 'click', handleClick
    trailRef.current = FlightTrail scene
    ringsRef.current = AttitudeRings scene

    render = ->
      animRef.current = requestAnimationFrame render
      frameCount.current += 1
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
    hasRefs = modelRef.current and pairRefs.current.length > 0
    return unless hasRefs

    roll  = attitude?.roll  or 0
    pitch = attitude?.pitch or 0
    yaw   = attitude?.yaw   or 0

    modelRef.current.rotation.set roll, yaw, -pitch
    ringsRef.current?.update { roll, pitch, yaw }

    # Flap amplitude (rad) — from telemetry amplitude (deg).
    amp = ((amplitude ? 45) * PI / 180)
    # L/R differential extracted from the engine's asymmetric angles.
    diff = ((wingAngleL or 0) - (wingAngleR or 0)) / 2
    phase = flapPhase or 0

    # Aeroelastic twist: wing tip whips with flap velocity.
    aero = (aeroelasticFlapCoefficient ? 20) * 0.004

    for pair, i in pairRefs.current
      pairPhase = phase + pair.phaseShift
      base = amp * Math.sin pairPhase
      leftAngle  = base + diff
      rightAngle = base - diff

      # Twist proportional to flap velocity (cosine of phase).
      twist = Math.cos(pairPhase) * aero

      pair.pivotL.rotation.z = leftAngle
      pair.pivotR.rotation.z = -rightAngle
      pair.wingL.rotation.x = twist
      pair.wingR.rotation.x = twist
    return
  , [attitude, wingAngleL, wingAngleR, flapPhase, amplitude, pairCount]

  # ── Render mount ───────────────────────────────────────
  createElement 'div', { className: 'viewport-canvas', ref: mountRef }

export default AircraftViewport