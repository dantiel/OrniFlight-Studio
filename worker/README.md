# The Forge — Cloud Firmware Build Worker

Cloudflare Worker backend for OrniFlight Studio's on-demand firmware build.
It mirrors (and extends) the PteronautOS "Fossil Etcher" worker, adapted to
OrniFlight's STM32 targets.

## How it works

```
Studio (GitHub Pages) ──► The Forge (this worker) ──► GitHub API
        ▲                                                 │
        └────────────── .bin / .hex / manifest ──────────┘
                           (unzipped from artifact)
```

The worker holds the GitHub token **server-side** — it never reaches the
browser. It dispatches the `cloud-build.yml` workflow in the firmware repo,
polls for completion, unzips the artifact, and serves the raw bytes for the
"Molt" flasher.

## Endpoints

| Method | Path | Purpose |
|---|---|---|
| `GET`  | `/api/health` | readiness + config summary |
| `POST` | `/api/build` | dispatch a build (`{ target, version_tag? }`) |
| `GET`  | `/api/build/:id` | poll status (+ artifact & manifest metadata) |
| `GET`  | `/api/build/:id/download` | raw `.bin` (`?format=hex` → `.hex`) |
| `GET`  | `/api/build/:id/manifest` | build manifest JSON |
| `GET`  | `/api/builds` | recent successful builds (history) |
| `POST` | `/api/build/:id/cancel` | cancel a queued/in-progress run |

## Deploy

```bash
cd worker
npm install
wrangler secret put GITHUB_TOKEN   # fine-grained: Actions read/write on dantiel/OrniFlight
wrangler deploy                    # → orniflight-forge.<subdomain>.workers.dev
```

Then point the Studio at it (one of):

1. Build-time: `VITE_FORGE_API_BASE=https://orniflight-forge.<subdomain>.workers.dev npm run build`
2. Runtime: append `?forge=https://orniflight-forge.<subdomain>.workers.dev` to the Studio URL
3. Same-origin: serve the Studio `dist/` from the worker (not currently wired)

## Deluxe vs. PteronautOS

- Multi-format artifact (`.bin` for DFU/WebUSB, `.hex` for USART/WebSerial)
- Build manifest with per-format SHA-256 for client-side verification
- `/api/builds` history and `/api/build/:id/cancel`
- `/api/health` readiness probe
- Stricter input whitelisting (target list + shell-safe charsets)