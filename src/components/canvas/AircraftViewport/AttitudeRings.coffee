###
# ORNIFLIGHT STUDIO — Attitude Reference Rings (Three.js)
# Holographic rings: pitch ladder + roll ring orbiting the model.
# Pure visual reference — no interaction.
###
import * as THREE from 'three'

AttitudeRings = (scene) ->
  group = new THREE.Group()
  scene.add group

  ringMat = new THREE.MeshBasicMaterial
    color: 0x446688
    transparent: true
    opacity: 0.25
    side: THREE.DoubleSide
    depthWrite: false

  # ── Pitch ring (horizontal, larger) ─────────────────────
  pitchGeo = new THREE.TorusGeometry 0.38, 0.008, 16, 64
  pitchRing = new THREE.Mesh pitchGeo, ringMat
  pitchRing.rotation.x = Math.PI / 2
  group.add pitchRing

  # ── Roll ring (vertical, smaller) ───────────────────────
  rollGeo = new THREE.TorusGeometry 0.26, 0.008, 16, 48
  rollRing = new THREE.Mesh rollGeo, ringMat
  group.add rollRing

  # ── Yaw ring (horizontal top) ───────────────────────────
  yawGeo = new THREE.TorusGeometry 0.30, 0.007, 16, 56
  yawRing = new THREE.Mesh yawGeo, ringMat.clone()
  yawRing.rotation.x = Math.PI / 2
  yawRing.position.y = 0.28
  group.add yawRing

  # ── Heading tick marks ──────────────────────────────────
  tickMat = new THREE.MeshBasicMaterial
    color: 0x6688aa
    transparent: true
    opacity: 0.35
    depthWrite: false

  for i in [0...12]
    angle = (i / 12) * Math.PI * 2
    tickGeo = new THREE.BoxGeometry 0.012, 0.003, 0.025
    tick = new THREE.Mesh tickGeo, tickMat
    tick.position.set(
      Math.cos(angle) * 0.38,
      0,
      Math.sin(angle) * 0.38
    )
    group.add tick

  # ── Public API ─────────────────────────────────────────
  update: (attitude) ->
    return unless attitude
    roll  = attitude.roll  or 0
    pitch = attitude.pitch or 0
    yaw   = attitude.yaw   or 0

    pitchRing.rotation.x = Math.PI / 2 + pitch
    rollRing.rotation.z = roll
    yawRing.rotation.y = yaw

  dispose: ->
    scene.remove group
    pitchGeo.dispose()
    rollGeo.dispose()
    yawGeo.dispose()
    ringMat.dispose()
    tickMat.dispose()

export default AttitudeRings
