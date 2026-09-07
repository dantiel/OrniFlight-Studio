# OrniFlight Studio — CLI Terminal

This document is the permanent record of the **CLI Terminal** magnum opus:
the polymorphic text console that maps the firmware's raw serial CLI (MSP-CLI
mode) into a live scrollback surface. It owns the *line discipline* (CRLF
collapse, backspace erase, ANSI clear), the *session takeover* (stop MSP, detach
byte routing, enter `#`), and the *sim/device polymorphism* — a dry-run echo
without a controller, the real byte stream with one.

Companion documents:

- [`MSP-PROTOCOL.md`](MSP-PROTOCOL.md) — the byte-level MSPv2 layer and
  `MspClient` whose `detach`/`attach` surface the takeover bridge sits on.
- [`ARCHITECTURE.md`](ARCHITECTURE.md) — the view-navigation and store patterns
  this view participates in.

---

## 1. Architecture

The CLI Terminal is **layered by responsibility**. A thin `h()` component owns
*what* is drawn; a pure state machine owns *how* raw bytes become lines; a
polymorphic hook owns *where* they come from (canned sim responses or the
device stream); a Zustand store is the single reactive surface.

```mermaid
flowchart TB
    subgraph UI[&quot;View layer&quot;]
        VIEW[&quot;CliTerminalView.coffee&lt;br/&gt;scrollback + input + history&quot;]
    end

    subgraph HOOK[&quot;Session layer&quot;]
        SESSION[&quot;useCliSession.coffee&lt;br/&gt;enter/submit/exit/complete&quot;]
        ASM[&quot;cliAssembler.coffee&lt;br/&gt;pure line-discipline state machine&quot;]
    end

    subgraph STATE[&quot;State layer&quot;]
        STORE[&quot;useCliStore.coffee&lt;br/&gt;lines / pending / mode / rx / tx&quot;]
        DEVICE[&quot;useDeviceStore.coffee&lt;br/&gt;source (sim|device)&quot;]
    end

    subgraph CONN[&quot;Connection layer&quot;]
        FIRM[&quot;useFirmwareConnection.coffee&lt;br/&gt;enterCli / leaveCli / writeCliBytes&quot;]
        CLIENT[&quot;MspClient&lt;br/&gt;detach / attach / transport.write&quot;]
    end

    VIEW --&gt;|&quot;enter/submit/exit/complete/clear&quot;| SESSION
    SESSION --&gt;|&quot;assembleChunk&quot;| ASM
    SESSION --&gt;|&quot;applyChunk (one set per chunk)&quot;| STORE
    SESSION --&gt;|&quot;source&quot;| DEVICE
    SESSION --&gt;|&quot;enterCli/writeCliBytes/leaveCli&quot;| FIRM
    FIRM --&gt; CLIENT
```

### Three responsibilities, three files

| File | Role | Statefulness |
|---|---|---|
| `src/components/views/CliTerminalView/CliTerminalView.coffee` | Split-UI shell: scrollback, input line, history recall, key handling | Local `useState`/`useRef` only |
| `src/hooks/useCliSession.coffee` | Polymorphic session: sim vs device, byte assembly, fold-back | Module refs + store |
| `src/hooks/cliAssembler.coffee` | Pure line discipline: CRLF collapse, erase, ANSI clear | Stateless (state in/out) |
| `src/stores/useCliStore.coffee` | Terminal surface: lines, pending, mode, byte counters | Zustand store |

---

## 2. Line discipline — `cliAssembler.coffee`

The raw byte stream is folded through a **pure state machine** that mirrors the
firmware's `cliProcess` semantics. `state` flows in, `state` flows out — no
`this`, no side effects.

| Byte | Effect |
|---|---|
| `\b` | Erase one character (`"\010 \010"` collapses to it) |
| `\r` | Finalize the pending line; the `cr` flag suppresses the `\n` half of a CRLF pair |
| `\n` | Finalize the pending line (no-op if it was just flushed by `\r`) |
| `ESC[2J` / `ESC[1;1H` | Clear screen — wipes the pending line too (mid-line clear) |
| any other ANSI | Stripped; a lone `ESC` or malformed sequence is dropped and the next byte is reprocessed through the plain path |

**Hard ceiling:** `MAX_LINE = 4096`. A hostile or broken device flooding bytes
without a line end cannot grow the pending buffer past this — the overlong line
finalizes as-is and the byte starts a fresh one (terminal auto-wrap semantics).

Exports: `assembleChunk`, `assembleByte`, `emptyState`, `MAX_LINE`.

---

## 3. Polymorphism — `useCliSession.coffee`

One hook, two behaviors. `mode` lives in the store; the hook branches on it.

### `sim` (no controller)

- Entered lines are echoed locally as `# <cmd>` (`kind: 'in'`).
- Canned responses for `help`, `version`, `status`, `clear`, `exit`.
- Unknown command → `###ERROR: unknown command: <cmd>` (`kind: 'error'`).
- `exit` → `no device attached — already in simulation` (`kind: 'info'`).

### `device` (controller attached)

- `enter()` runs the takeover: stop the MSP session, `client.detach(onData)`,
  subscribe `onError → failConnection`, wait out the firmware's 100 ms idle
  guard, then send raw `#` (`0x23`).
- `submit(cmd)` writes `cmd\r`; the firmware echoes back, landing in `pending`
  until a line end finalizes it (live echo without local duplication).
- `complete(draft)` sends `\t` (firmware-side completion).
- `exit()` writes `exit\r`; the firmware reboots, which routes the disconnect
  through `failConnection`. A 2 s grace timer folds back to sim for targets
  that stay alive (mock transports, lab rigs).

### Fold-back invariants

- `foldToSim`: a failed device write folds the session back to sim *and* calls
  `leaveDevice()` — no unhandled rejection when the transport drops
  mid-command; the store settles before the await.
- A `source` change away from `device` (controller reboot or failure) folds the
  session to sim and prints `── connection closed by controller ──`.
- Unmounting the view mid-session restores MSP routing via `leaveDevice()`.
- `enter()` resets the `TextDecoder` — a fresh session must not inherit a
  partial UTF-8 sequence from a previous stream-mode decode.

---

## 4. State surface — `useCliStore.coffee`

| Field | Type | Purpose |
|---|---|---|
| `lines` | `{ text, kind }[]` | Scrollback, capped at `MAX_LINES = 500` |
| `pending` | string | Partially echoed line (device echo, live) |
| `mode` | `'sim' \| 'device'` | Polymorphism switch |
| `rxBytes` / `txBytes` | number | Byte counters for the status bar |

`kind` is one of `in`, `out`, `prompt`, `error`, `info`, `muted`. The
`classifyLine` helper maps `###…` → `error`, `#…` → `prompt`, everything else →
`out`.

**`applyChunk(payload)`** is the performance crux: byte accounting, line
appends, the optional clear wipe and the pending tail settle in **one** store
set per device chunk — a deterministic single re-render regardless of how many
lines finalize within the chunk.

---

## 5. View — `CliTerminalView.coffee`

A split-UI terminal built with `h()` (not CHAML): autoscroll, input focus and
per-keystroke key handling need real lifecycle hooks and refs.

| Interaction | Behavior |
|---|---|
| `Enter` | Submit draft |
| `↑` / `↓` | History recall (draft is preserved when you arrow away) |
| `Tab` | Completion (`sim` matches known names; `device` sends `\t`) |
| `Ctrl/Cmd+L` | Clear screen |

The scrollback renders as React text children (`h 'div', …, line.text`) — the
line content is never interpolated as markup. The screen is `role="log"` with
`aria-live="polite"`; the badge reads `● LIVE` / `◌ SIMULATION`.

---

## 6. Connection bridge — `useFirmwareConnection.coffee`

Four module-scope functions form the takeover surface:

| Export | Effect |
|---|---|
| `enterCli(onData)` | Stop session, detach byte routing to the CLI listener, guard-delay, send `#` |
| `writeCliBytes(bytes)` | Raw transport write (throws unless the channel is detached) |
| `leaveCli()` | Reattach MSP routing, restart the session; returns `false` if the connection is gone |
| `isCliOwned()` | Whether the CLI currently owns the byte stream |

Disconnects while the CLI owns the stream route through `failConnection` — the
MSP session is stopped and cannot observe them.

---

## 7. Integration points

| File | Wiring |
|---|---|
| `src/app/App.chaml` | `<Route path="/cli">` through `AnimatedPage` |
| `src/components/controls/ConfigTabs/ConfigTabs.chaml` | `NavLink to="/cli"` with `data-glyph: '❯'` |
| `src/components/overlays/CommandPalette/CommandPalette.coffee` | `['CLI Terminal', '/cli', '❯']` |

---

## 8. Security invariants

- **XSS-immune by construction** — every line is a React text child; content is
  never interpolated as markup. A regression test asserts hostile input renders
  inert.
- **ANSI/OSC/BEL inert** — the discipline strips every escape sequence except
  the two recognized clear sequences; no cursor movement, no title-set, no
  terminal-command injection.
- **History not persisted** — the command history lives in a `useRef`, wiped on
  unmount.
- **Bounded pending** — `MAX_LINE = 4096` caps the partially echoed line, so a
  newline-free flood cannot grow unbounded state.

---

## 9. Performance

| Probe | Result |
|---|---|
| 900 KB / 75k lines | ~100 ms |
| 1 MB newline-free flood | ~276 ms, 244 bounded flushes |

Both probes exercise `applyChunk`'s single-set-per-chunk pipeline, holding
re-render count at exactly one per device chunk.

---

## 10. Testing

| File | Covers |
|---|---|
| `src/test/cliAssembler.test.coffee` | Discipline edge cases: CRLF collapse, erase, clear sequences, `MAX_LINE` auto-flush, lone-ESC reprocess |
| `src/test/useCliSession.test.coffee` | sim echo + canned responses, device write/fold-back, `applyChunk` accounting, `TextDecoder` reset |
| `src/test/CliTerminalView.test.coffee` | Render, history recall, tab completion, XSS-inert rendering, LIVE/SIM badge |

Full suite: **338 tests green**, build clean, width-check clean on all changed
files.

---

## 11. Lessons learned

1. **`h()` over CHAML for refs/keys** — autoscroll, focus stealing and
   per-keystroke history need real lifecycle hooks; CHAML cannot hold them.
2. **Reset the `TextDecoder` on entry** — `{ stream: true }` buffers a partial
   UTF-8 sequence across sessions; a fresh session inheriting it corrupts the
   first bytes.
3. **Settle before the await in fold-back** — `foldToSim` synchronously resets
   the store *before* awaiting `leaveDevice()`, so a rejected transport write
   never leaves the UI stranded in `device` mode.
4. **Grace timer for exit** — the firmware reboots on CLI exit, so the common
   return path is a transport disconnect; the 2 s timer is a fallback for
   targets that stay alive.
5. **One set per chunk** — fold byte accounting, appends, clears and the
   pending tail into `applyChunk` for deterministic single re-render.
