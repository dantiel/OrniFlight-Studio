# Announcing OrniFlight Studio (BBCode forum version)

[b][size=4]OrniFlight Studio — a new standard for ornithopter flight control[/size][/b]

Ornithopter flight controllers have barely evolved beyond their early free-flight ancestors. Today's flapping-wing models still fly with radio gear wired straight to servos — no FPV, no OSD, no specialised flight-control software, no racing scene. That's the state of the art, and it's about to change. The future of ornithopters is FPV, OSD, racing, and purpose-built flight control — and it can only arrive as a whole, not one piece at a time.

The racing scene is already taking shape: [b]BORN-2-FLAP[/b] — [url=https://dantiel.github.io/BORN-2-FLAP/]https://dantiel.github.io/BORN-2-FLAP/[/url] — is a complete simulation framework (and a game for everyone) that loads ornithopters defined in OrniFlight Studio and PteronautOS along with their configurations, and emulates their firmware. That technological leap is exactly what OrniFlight was built to make.

OrniFlight is flight-control firmware written from the ground up for flapping flight: a real servo mixer, flap-centre PID stabilisation, glide mode, and the ONDAS waveform mixer. It runs on the same flight-controller hardware the community already flies — [b]F3, F4 and F7[/b] boards — but every line of drone logic has been stripped out and replaced with an architecture built purely for ornithopters.

That firmware has been heavily rebuilt — including a full rework of the ONDAS suite — and is now in an intensive stabilisation and tuning phase. It isn't stable enough to fly confidently yet, which is exactly why it needs testers now. Today I'm announcing its companion: [b]OrniFlight Studio[/b] — the next-generation configuration and engineering environment that will replace the aging orniflight-configurator entirely.

[b]What it is[/b]

OrniFlight Studio is a full engineering workspace, not just a configurator:

You can already check it out online — [url=https://dantiel.github.io/OrniFlight-Studio/]https://dantiel.github.io/OrniFlight-Studio/[/url] — though please note it is still in active development: only some parts are yet completely functional.

[list]
[*][b]Configuration[/b] — a polymorphic airframe/mixer configuration surface with live 3D preview and MSP servo sync.
[*][b]Waveform laboratory[/b] — design and tune ONDAS flapping waveforms with live parameter control and 2D curve plotting.
[*][b]Live telemetry[/b] — high-frequency telemetry streams with buffered 60fps rendering while the engine runs at 500Hz internally.
[*][b]Simulation[/b] — a built-in ornithopter model (servo mixer, PID, gyro physics, sensor noise, multi-wing arrangements) that runs with [b]no flight controller required[/b]. You can develop and test configuration changes before ever touching hardware.
[*][b]PID tuning[/b] — a tuning surface with a live engine mirror.
[*][b]OSD editor[/b] — drag-and-drop layout editing with read-back sync.
[/list]

It's a new-generation web app: React 18, Three.js rendering, XState state machines, RxJS streams, Zod validation, PWA-capable — and a Tauri desktop shell on the roadmap.

[b]New filters — the ONDAS suite[/b]

Because ornithopters flap, their own wingbeat shows up in the gyro signal as a periodic "noise" that a multicopter PID would either fight or ignore. The ONDAS suite was rebuilt around that fact — a set of stroke-locked filters that work [i]with[/i] the flapping frequency instead of against it:

[list]
[*][b]Resonance[/b] — a phase-locked error filter (a lock-in amplifier for attitude). It extracts the error component coherent with the wingbeat and amplifies it, so the wing can "resonate" against disturbance at its own frequency.
[*][b]Espelho[/b] (mirror) — self-noise cancellation. It learns the flap-coherent gyro component (fundamental plus 2nd harmonic, phase-true) and subtracts it, leaving only real external disturbance for the PID to see.
[*][b]SSFF + Prescience[/b] — stroke-synchronous feed-forward that measures pitch error over each half-stroke and biases the next stroke, plus a stroke-ahead predictor that removes the half-stroke measurement delay.
[*][b]Saudade[/b] — slow per-stroke learning that absorbs persistent SSFF bias into a learned trim: transients are handled stroke-by-stroke, and the patterns are remembered.
[*][b]Order tracker + consensus gate[/b] — a Vold–Kalman tracking bandpass whose centre follows the instantaneous flap frequency, gated by a statistical envelope (ondas_metrics) so the two extractors only blend when they agree.
[/list]

These are all new and under active tuning — and they're exactly why the firmware needs a round of stabilisation before I'd call it stable.

[b]Status[/b]

[list]
[*][b]OrniFlight firmware[/b] — heavily rebuilt, now being stabilised and tuned. The ONDAS suite and several new filters are fresh and need testing.
[*][b]OrniFlight Studio[/b] — v0.2 prototype. The architectural foundation, simulation engine, 3D visualisation, and ONDAS waveform mixer are working; the configuration and tuning surfaces are being filled in against the real firmware behaviour.
[*][b]Try it[/b] — [url=https://dantiel.github.io/OrniFlight-Studio/]https://dantiel.github.io/OrniFlight-Studio/[/url] (some parts still incomplete — early development build).
[/list]

[b]Why it matters[/b]

The goal is a technological leap for the whole class: FPV, OSD, racing, and specialised flight-control software for ornithopters. None of it works in isolation — the flight controller, the servo mixing, the stabilisation, and the configurator all have to advance together. OrniFlight Studio is the ground-station half of that leap: a tool that understands flap-centre stabilisation, glide, and multi-wing mixing as first-class concepts.

And because BORN-2-FLAP carries the complete simulation framework, the same loop can close the other way: tune our flight-control software by AI simulation — define the bird in Studio, load it into BORN-2-FLAP, let the simulator emulate the firmware, and evolve the tuning without ever risking a real airframe.

[b]Get involved[/b]

The firmware is in active stabilisation and needs testers and bug reports. The Studio is open and looking for early testers, feedback, and contributors. If you fly ornithopters and want a tool that treats them as more than a novelty, now is the time.

[list]
[*]Firmware: OrniFlight
[*]Configurator (being replaced): orniflight-configurator
[*]Studio: OrniFlight Studio
[*]Simulation: [url=https://dantiel.github.io/BORN-2-FLAP/]BORN-2-FLAP[/url]
[/list]

[i]GPL-3.0 — fly it, break it, tell me what's wrong.[/i]