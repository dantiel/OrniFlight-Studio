###
# ORNIFLIGHT STUDIO — Simulation flash transport (dry-run)
#
# Faithful no-hardware backend behind run()/reboot(). Drives the
# machine through erase → write → verify with chunked progress and
# synthetic timing. No port required — the "molting" without a bird.
###
sleep = (ms) -> new Promise (resolve) -> setTimeout resolve, ms

run = (actor, fw, options = {}, onLog = (->)) ->
  { verify = true, fullErase = false, reboot = true } = options

  eraseMsg = if fullErase then 'Full chip erase…' else 'Erasing app region…'
  onLog 'ERASE', eraseMsg
  await sleep (if fullErase then 900 else 500)
  actor.send { type: 'ERASE_DONE' }

  total = fw.size or 262144
  onLog 'WRITE', "Writing #{fw.name} v#{fw.version} (#{total} bytes)… [dry-run]"
  chunk = Math.max 1024, Math.floor(total / 40)
  written = 0
  lastPct = -1
  while written < total
    written = Math.min total, written + chunk
    pct = Math.round written / total * 100
    if pct != lastPct
      actor.send { type: 'WRITE_PROGRESS', progress: pct }
      lastPct = pct
    await sleep 18
  actor.send { type: 'WRITE_DONE' }

  if verify
    onLog 'VERIFY', 'Verifying checksum against manifest…'
    await sleep 350
    digest = (fw.sha256 or 'deadbeef').slice 0, 8
    onLog 'VERIFY', "sha256 #{digest}… ✓ [dry-run]"
    actor.send { type: 'VERIFY_DONE' }

  onLog 'DONE', "#{fw.name} v#{fw.version} transmigrated (simulated)."
  if reboot
    onLog 'REBOOT', 'Rebooting into new plumage…'
    actor.send { type: 'REBOOT' }
    await sleep 900
    actor.send { type: 'REBOOT_DONE' }
    onLog 'READY', 'The bird is ready.'

reboot = (actor, onLog = (->)) ->
  onLog 'REBOOT', 'Rebooting into new plumage…'
  await sleep 900
  actor.send { type: 'REBOOT_DONE' }
  onLog 'READY', 'The bird is ready.'

export { run, reboot }