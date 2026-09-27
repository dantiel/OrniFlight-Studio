# OrniFlight Studio — Math Suite View (TASK / DESIGN BRIEF)

> **Status: IMPLEMENTED (T4 device path pending).** The studio-grade
> surface of the ONDAS + ESPELHO mathematics suite is live as the
> **Math view** (`/control/math`, `src/components/views/MathView/`).
>
> Delivered: T1 codec (15 keys, signed s8 wire, firmware reset
> defaults), T2 registry (`src/lib/mathSuite.coffee` — single source
> of truth for layers/params/ranges/units, consumed by the codec,
> `useTuningStore`, `OrnithopterModel`, `PidTuningView` and MathView),
> T3 nine layer cards + signal chain, T4 Espelho skew diagnostic
> (sim-derived lock-in ratios + phase dial; device `MSP_DEBUG`/
> `SET_DEBUG` codes reserved in `mspCodes.coffee`, debug[] field in
> `useTelemetryStore`), T5 preview: down/up ferocity split rendered
> live via the `strokePreviewPath` waveform (model-side split physics
> still single-waveform — future work).
>
> Implementation notes follow the pattern of
> [`PID-TUNING-VIEW.md`](PID-TUNING-VIEW.md).

## 1. Context

The firmware now carries a **15-parameter mathematics suite** on
`ornithopterProfile_t` (see `OrniFlight/src/main/cli/settings.c:1446-1461`).
It is a *system*, not a list: nine coupled layers that transform raw PID terms
into the wing's phase-locked motion. The Studio's current representation is a
flat loop of generic sliders that predates the expansion — it renders 10 keys
at uniform `0..100`, with no signed ranges, no units, no grouping, and no live
diagnostics. The gap below is the work.

## 2. The mathematics suite (what must be represented)

| Layer | Param(s) | Firmware range | Role |
|---|---|---|---|
| CADENCE | `cadence_gain` | −100..100 | P-term → phase advance (k₀ scaling) |
| FEROCITY | `ferocity_p_gain`, `ferocity_d_gain`, `ferocity_roll_gain`, `ferocity_yaw_gain` | 0..100 / −100..100 | PD blend → dwell & roll/yaw common-mode |
| FEROCITY shape | `ferocity_downstroke`, `ferocity_upstroke` | 1..100 | down/up stroke sharpness split |
| BALANCE | `balance_gain` | −100..100 | I-term → up/down thrust bias |
| WARP | `warp_gain`, `warp_yaw_gain` | −100..100 | L/R ferocity differential |
| ANCHOR | `anchor_gain` | 0..100 | variable k₂ damping |
| RESONANCE | `resonance_gain` | 0..100 | phase-locked error filter |
| PRESCIENCE | `prescience_gain` | 0..100 | stroke-ahead prediction via ω |
| ESPELHO | `espelho_gain` | 0..100 | wing-self-noise cancellation |
| SAUDADE | `saudade_gain` | 0..100 | per-stroke learning → trim bias |

**Live diagnostic (new, non-config):** the firmware commit `ESPELHO:
quadrature+skew lock-in bank and skew diagnostic` now reports, per axis,
`espelhoSkewRatio[roll|pitch|yaw]` = |2nd harmonic| / |fundamental| plus the
pitch **skew phase** (°) — the stroke-asymmetry fingerprint. It flows through
the `DEBUG_ESPELHO` debug mode (`debug[0..3]`) → blackbox and the OSD `DBG`
element, exactly like the existing `ONDAS_METRICS` debug mode.

## 3. Gap analysis (firmware ↔ Studio)

1. **Param coverage.** `ONDAS_KEYS`/`ONDAS_DEFAULTS` in
   `src/protocol/mspDecoders.coffee:448-461` define **10** keys; the firmware
   has **15**. Missing from the ONDAS tuning surface:
   `ferocity_downstroke`, `ferocity_upstroke`, `prescience_gain`,
   `espelho_gain`, `saudade_gain`. (The full set is *partially* decoded in the
   servo-config "appendix" codec at `mspDecoders.coffee:283-332`, but never
   wired into `PidTuningView`'s ONDAS section.)
2. **Uniform bounds.** `PidTuningView.chaml:37-39` renders every ONDAS key with
   `min=0, max=100`. Signed params (`cadence_gain`, `ferocity_d_gain`,
   `balance_gain`, `warp_gain`, `warp_yaw_gain` = −100..100) are mis-clamped.
3. **No signed-range / unit / description metadata** per param — the label is
   `key.split('_').join(' ')` only.
4. **No live skew diagnostic surface.** `espelhoSkewRatio` + phase has no home
   in `TelemetryLab`/`PlotWorkspace`/`WaveformPlot`, despite the telemetry
   stream (`src/streams/telemetryStream.coffee`, `useTelemetryStore`) existing.
5. **Defaults drift.** Studio `ONDAS_DEFAULTS` values are stale relative to
   firmware reset defaults — reconcile on the codec boundary.

## 4. Studio-grade representation vision

Stop treating the suite as 15 sliders. Represent it as a **layered system**,
matching the Studio's existing primitives (three.js `FeatherField`/`AircraftViewport`,
`waveform.coffee`, `OrnithopterModel.coffee`, `MetricBadge`, framer-motion):

- **Grouped layer cards** (accordion per layer, or one "ONDAS" card with
  sub-sections) instead of one flat list. Each layer card carries its role
  one-liner and signed range.
- **Param metadata registry** (single source of truth, e.g. a
  `MATH_SUITE` table mirroring `mspDecoders`): key → { layer, min, max, sign,
  unit, description }. `PidTuningView` and the codec both read it — no more
  hard-coded `min=0 max=100`.
- **Live preview**: editing a layer param re-drives `OrnithopterModel` (already
  wired via `setOndasParam`) so the FeatherField/AircraftViewport wing motion
  changes in real time; a `waveform.coffee` overlay shows the resulting
  stroke waveform (down/up split, dwell, phase advance).
- **Diagnostic gauges**: a dedicated "Espelho" readout — three skew-ratio
  `MetricBadge`s (roll/pitch/yaw) + a phase dial — fed from the telemetry
  stream when `DEBUG_ESPELHO` is selected, mirroring any existing
  `ONDAS_METRICS` debug surfacing.

## 5. Sub-tasks (acceptance criteria)

- **T1 — Codec reconciliation.** Extend `ONDAS_KEYS`/`ONDAS_DEFAULTS` to the
  15-param set with firmware-accurate defaults; add the signed-range metadata.
  *AC:* `encodeOndas`/`decodeOndas` round-trip all 15 keys; `ONDAS_KEYS.length === 15`.
- **T2 — Metadata registry.** Introduce the `MATH_SUITE` table (layer, min,
  max, sign, unit, description) and have `PidTuningView` render from it.
  *AC:* signed params show −100..100; down/up ferocity show 1..100; every row
  has a description tooltip.
- **T3 — Layer grouping.** Regroup the ONDAS section into the nine layer cards.
  *AC:* visual grouping matches the layer table above; no behavior regressions
  in `PidTuningView.test.coffee`.
- **T4 — Espelho skew diagnostic surface.** Add skew-ratio gauges + phase dial
  to the telemetry lab, fed by `DEBUG_ESPELHO`. *AC:* live values appear when
  the debug mode is set; zeros render cleanly when no device is attached.
- **T5 — Live preview fidelity.** Ensure the down/up ferocity split and
  espelho gain are reflected by `OrnithopterModel`/`waveform.coffee` (extend the
  sim model if it is single-waveform today). *AC:* changing
  `ferocity_downstroke` vs `ferocity_upstroke` visibly changes the stroke
  preview asymmetry.

## 6. References

- Firmware params: `../OrniFlight/src/main/cli/settings.c:1446-1461`
- Studio codec: `src/protocol/mspDecoders.coffee:448-472`, `:283-332`
- Studio view: `src/components/views/PidTuningView/PidTuningView.chaml:37-39`
- Companion: [`PID-TUNING-VIEW.md`](PID-TUNING-VIEW.md),
  [`CONFIGURATION_MODEL.md`](CONFIGURATION_MODEL.md)