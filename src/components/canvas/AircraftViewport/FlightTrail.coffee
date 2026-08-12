###
# ORNIFLIGHT STUDIO — Flight Trail (Three.js)
# Renders a fading polyline tracing the aircraft's path through space.
# Ring-buffer of positions, oldest segments fade to transparent.
###
import * as THREE from 'three'

MAX_POINTS = 200
TRAIL_LENGTH = 120  # visible segment count

FlightTrail = (scene) ->
  positions = new Float32Array MAX_POINTS * 3
  colors = new Float32Array MAX_POINTS * 3
  writeIndex = 0
  count = 0

  # Build geometry with MAX_POINTS pre-allocated
  geo = new THREE.BufferGeometry()
  geo.setAttribute 'position', new THREE.BufferAttribute(positions, 3)
  geo.setAttribute 'color', new THREE.BufferAttribute(colors, 3)
  geo.setDrawRange 0, 0

  mat = new THREE.LineBasicMaterial
    vertexColors: true
    transparent: true
    opacity: 0.6
    linewidth: 1
    blending: THREE.AdditiveBlending
    depthWrite: false

  line = new THREE.Line geo, mat
  line.frustumCulled = false
  scene.add line

  # ── Public API ─────────────────────────────────────────
  push: (x, y, z) ->
    i = writeIndex * 3
    positions[i]     = x
    positions[i + 1] = y
    positions[i + 2] = z
    # Color gradient: fresh = accent cyan, old = fade
    colors[i]     = 0.22
    colors[i + 1] = 0.82
    colors[i + 2] = 0.75
    writeIndex = (writeIndex + 1) % MAX_POINTS
    count = Math.min(count + 1, MAX_POINTS)

  update: ->
    # Re-color: older points dim to zero
    visible = Math.min(count, TRAIL_LENGTH)
    for j in [0...visible]
      idx = ((writeIndex - 1 - j + MAX_POINTS) % MAX_POINTS) * 3
      t = 1 - j / visible
      colors[idx]     = 0.22 * t
      colors[idx + 1] = 0.82 * t
      colors[idx + 2] = 0.75 * t

    if count <= TRAIL_LENGTH
      start = 0
    else
      start = (writeIndex - TRAIL_LENGTH + MAX_POINTS) % MAX_POINTS
    # Build an ordered index array for drawRange
    # Since BufferGeometry with non-contiguous buffer is tricky,
    # we shift positions to keep the active range contiguous.
    # For simplicity: if count > TRAIL_LENGTH, shift everything.
    if count > TRAIL_LENGTH and writeIndex == 0
      # wrapped — but we keep it simple: just show last TRAIL_LENGTH
      # by copying the last TRAIL_LENGTH to the start
      for j in [0...TRAIL_LENGTH]
        src = ((writeIndex - TRAIL_LENGTH + j + MAX_POINTS) % MAX_POINTS) * 3
        dst = j * 3
        positions[dst]     = positions[src]
        positions[dst + 1] = positions[src + 1]
        positions[dst + 2] = positions[src + 2]
        colors[dst]     = colors[src]
        colors[dst + 1] = colors[src + 1]
        colors[dst + 2] = colors[src + 2]
      writeIndex = TRAIL_LENGTH
      count = TRAIL_LENGTH

    geo.setDrawRange 0, Math.min(count, TRAIL_LENGTH)
    geo.attributes.position.needsUpdate = true
    geo.attributes.color.needsUpdate = true

  dispose: ->
    geo.dispose()
    mat.dispose()
    scene.remove line

export default FlightTrail