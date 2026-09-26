// OrniFlight Studio · The Forge — Cloud Firmware Build (Cloudflare Worker).
//
// Holds a GitHub token server-side (never in the browser) and drives the
// `cloud-build.yml` workflow in the OrniFlight firmware repo:
//   trigger → poll → extract .bin/.hex from the GitHub artifact zip →
//   serve raw bytes for Web Serial (USART bootloader) / Web USB (DFU) flashing.
//
// This worker is API-ONLY. The flasher UI ("The Molt") lives in OrniFlight
// Studio and reaches these endpoints cross-origin via FORGE_API_BASE. No
// static assets here — the worker must not duplicate the dashboard.
//
// Endpoints:
//   GET  /api/health                 readiness + config summary
//   POST /api/build                  dispatch a cloud build, return run id
//   GET  /api/build/:id              poll status (+ artifact + manifest meta)
//   GET  /api/build/:id/download     raw .bin (or ?format=hex → .hex)
//   GET  /api/build/:id/manifest     the build manifest.json
//   GET  /api/builds                 recent successful builds (history)
//   POST /api/build/:id/cancel       cancel a queued/in-progress run
//   GET  /                           redirect to the Studio flasher page

import { unzipSync } from "fflate";

const WORKFLOW_NAME = "OrniFlight Cloud Build";
const ARTIFACT_NAME = "orniflight-firmware";

// Curated target whitelist — must stay in sync with the workflow's
// `target` choice options. Values are interpolated into a shell command
// by the workflow, so constrain them strictly (blocks command injection).
const TARGETS = ["TINYFISH", "OMNIBUSF4", "SPRACINGF7DUAL", "BETAFLIGHTF3"];

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type, Authorization",
  "Access-Control-Max-Age": "86400",
};

function json(data, status = 200, extra = {}) {
  return new Response(JSON.stringify(data, null, 2), {
    status,
    headers: { "Content-Type": "application/json", ...CORS, ...extra },
  });
}

function githubFetch(env, path, init = {}) {
  const url = path.startsWith("https://")
    ? path
    : `https://api.github.com${path}`;
  return fetch(url, {
    ...init,
    headers: {
      Authorization: `Bearer ${env.GITHUB_TOKEN}`,
      Accept: "application/vnd.github+json",
      "User-Agent": "orniflight-forge-worker",
      "X-GitHub-Api-Version": "2022-11-28",
      ...(init.headers || {}),
    },
  });
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// workflow_dispatch returns 204 with no run id — locate the freshly queued
// run by polling the workflow's run list until it appears.
async function findNewestRun(env, workflowName, dispatchTime) {
  for (let i = 0; i < 30; i++) {
    const resp = await githubFetch(
      env,
      `/repos/${env.GITHUB_REPO}/actions/runs?event=workflow_dispatch&per_page=10`,
    );
    if (!resp.ok) {
      await sleep(1000);
      continue;
    }
    const data = await resp.json();
    const run = data.workflow_runs
      .filter((r) => r.name === workflowName)
      .filter((r) => new Date(r.created_at).getTime() >= dispatchTime - 5000)
      .sort((a, b) => b.run_number - a.run_number)[0];
    if (run) return run;
    await sleep(1000);
  }
  return null;
}

// GitHub 302-redirects the artifact zip to a pre-signed blob URL. Workers
// follow redirects and would forward the Authorization header to that
// cross-origin host, which Azure/S3 reject with 401. Follow manually and
// fetch the signed URL WITHOUT credentials.
async function fetchArtifact(env, archiveUrl) {
  const resp = await githubFetch(env, archiveUrl, { redirect: "manual" });
  if ([301, 302, 303, 307, 308].includes(resp.status)) {
    const loc = resp.headers.get("location");
    if (loc) {
      return fetch(loc, { headers: { "User-Agent": "orniflight-forge-worker" } });
    }
  }
  return resp;
}

async function getArtifact(env, id) {
  const a = await githubFetch(
    env,
    `/repos/${env.GITHUB_REPO}/actions/runs/${id}/artifacts`,
  );
  if (!a.ok) return { error: `Artifacts not available (${a.status}).`, status: a.status };
  const data = await a.json();
  const art =
    data.artifacts.find((x) => x.name === ARTIFACT_NAME) || data.artifacts[0];
  return { art };
}

// Fetch and unzip an artifact's contents once, cached per run via a simple
// in-memory Map (Workers isolate is short-lived; this only avoids duplicate
// work within a single request chain).
async function getArchiveFiles(env, art) {
  const zipResp = await fetchArtifact(env, art.archive_download_url);
  if (!zipResp.ok) {
    let hint = "";
    if (zipResp.status === 401) {
      hint =
        " Token lacks artifact-download permission (classic PAT needs `repo`; fine-grained needs Actions: read).";
    }
    return { error: `Artifact download failed (${zipResp.status}).${hint}`, status: zipResp.status };
  }
  const zipBytes = new Uint8Array(await zipResp.arrayBuffer());
  return { files: unzipSync(zipBytes) };
}

function findFile(files, pattern) {
  return Object.keys(files).find((n) => pattern.test(n));
}

async function handleBuild(request, env) {
  if (!env.GITHUB_TOKEN) {
    return json(
      { error: "Worker is not configured with a GITHUB_TOKEN secret." },
      500,
    );
  }

  let inputs;
  try {
    inputs = await request.json();
  } catch {
    return json({ error: "Invalid JSON body." }, 400);
  }
  if (!inputs || typeof inputs !== "object") {
    return json({ error: "Expected a JSON object of build inputs." }, 400);
  }

  // Validate + whitelist inputs. Values reach a shell command in the
  // workflow, so constrain them to shell-safe charsets.
  const target = String(inputs.target || "").trim().toUpperCase();
  if (!TARGETS.includes(target)) {
    return json(
      { error: `Invalid target '${target}'. Choose one of: ${TARGETS.join(", ")}.` },
      400,
    );
  }

  const versionTag = String(inputs.version_tag || "").trim();
  if (versionTag && !/^[A-Za-z0-9._-]{1,24}$/.test(versionTag)) {
    return json(
      { error: "version_tag may only contain [A-Za-z0-9._-], max 24 chars." },
      400,
    );
  }

  // Only forward keys that exist in cloud-build.yml's dispatch inputs.
  // (ONDAS gains are runtime CLI-tunable, so no compile-time defines are
  // needed — keeping the surface to target + version_tag only.)
  const dispatchInputs = {};
  for (const key of ["target", "version_tag"]) {
    const v = inputs[key];
    if (v == null || v === "") continue;
    dispatchInputs[key] = String(v);
  }

  const dispatchTime = Date.now();
  const resp = await githubFetch(
    env,
    `/repos/${env.GITHUB_REPO}/actions/workflows/cloud-build.yml/dispatches`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        ref: env.GITHUB_REF || "main",
        inputs: dispatchInputs,
      }),
    },
  );

  if (resp.status !== 204) {
    const text = await resp.text();
    return json(
      { error: `Failed to trigger build (${resp.status}): ${text}` },
      resp.status,
    );
  }

  const run = await findNewestRun(env, env.WORKFLOW_NAME || WORKFLOW_NAME, dispatchTime);
  if (!run) {
    return json(
      { error: "Build dispatched but run not found. Check the Actions tab." },
      502,
    );
  }

  return json({ run_id: run.id, html_url: run.html_url, status: run.status });
}

async function handleStatus(id, env) {
  const resp = await githubFetch(env, `/repos/${env.GITHUB_REPO}/actions/runs/${id}`);
  if (!resp.ok) {
    return json({ error: `Run ${id} not found (${resp.status}).` }, resp.status);
  }
  const run = await resp.json();

  const out = {
    run_id: run.id,
    status: run.status, // queued | in_progress | completed
    conclusion: run.conclusion, // success | failure | cancelled | null
    html_url: run.html_url,
    head_sha: run.head_sha,
    head_branch: run.head_branch,
    created_at: run.created_at,
    updated_at: run.updated_at,
    run_number: run.run_number,
    ready: run.status === "completed",
  };

  if (run.status === "completed" && run.conclusion === "success") {
    const { art, error } = await getArtifact(env, id);
    if (art) {
      out.artifact = { name: art.name, size_download: art.size_in_bytes };
      // Surface the build manifest (target/version/checksums) when present.
      const archive = await getArchiveFiles(env, art);
      if (archive.files) {
        const manifestName = findFile(archive.files, /(^|\/)manifest\.json$/i);
        if (manifestName) {
          try {
            out.manifest = JSON.parse(new TextDecoder().decode(archive.files[manifestName]));
          } catch {
            /* corrupt manifest — ignore */
          }
        }
      }
    }
    if (error) out.error = error;
  }

  return json(out);
}

async function handleManifest(id, env) {
  const { art, error } = await getArtifact(env, id);
  if (error) return json({ error }, 404);
  if (!art || !art.archive_download_url) {
    return json({ error: "No firmware artifact found for this run." }, 404);
  }
  const archive = await getArchiveFiles(env, art);
  if (archive.error) return json({ error: archive.error }, archive.status || 502);
  const manifestName = findFile(archive.files, /(^|\/)manifest\.json$/i);
  if (!manifestName) return json({ error: "No manifest.json in artifact." }, 404);
  try {
    const parsed = JSON.parse(new TextDecoder().decode(archive.files[manifestName]));
    return json(parsed);
  } catch {
    return json({ error: "Manifest is not valid JSON." }, 502);
  }
}

async function handleDownload(id, env, format = "bin") {
  const { art, error, status } = await getArtifact(env, id);
  if (error) return json({ error }, status || 502);
  if (!art || !art.archive_download_url) {
    return json({ error: "No firmware artifact found for this run." }, 404);
  }

  const archive = await getArchiveFiles(env, art);
  if (archive.error) return json({ error: archive.error }, archive.status || 502);

  // Prefer the exact staged name, then any matching suffix.
  const isHex = format === "hex";
  const exact = isHex ? "orniflight.hex" : "orniflight.bin";
  const pattern = isHex ? /(^|\/)orniflight\.hex$/i : /(^|\/)orniflight\.bin$/i;
  let name = archive.files[exact] ? exact : findFile(archive.files, pattern);
  if (!name && !isHex) name = findFile(archive.files, /\.bin$/i);
  if (!name && isHex) name = findFile(archive.files, /\.hex$/i);
  if (!name) {
    return json(
      { error: `No ${format.toUpperCase()} found inside the artifact zip.` },
      502,
    );
  }

  const bytes = archive.files[name];
  const filename = isHex ? "orniflight.hex" : "orniflight.bin";
  return new Response(bytes, {
    status: 200,
    headers: {
      "Content-Type": "application/octet-stream",
      "Content-Disposition": `attachment; filename="${filename}"`,
      "Content-Length": String(bytes.length),
      "Cache-Control": "public, max-age=3600",
      ...CORS,
    },
  });
}

async function handleHistory(env) {
  const resp = await githubFetch(
    env,
    `/repos/${env.GITHUB_REPO}/actions/runs?event=workflow_dispatch&status=success&per_page=20`,
  );
  if (!resp.ok) {
    return json({ error: `History unavailable (${resp.status}).` }, resp.status);
  }
  const data = await resp.json();
  const builds = (data.workflow_runs || [])
    .filter((r) => r.name === (env.WORKFLOW_NAME || WORKFLOW_NAME))
    .map((r) => ({
      run_id: r.id,
      run_number: r.run_number,
      head_sha: r.head_sha,
      head_branch: r.head_branch,
      created_at: r.created_at,
      html_url: r.html_url,
      conclusion: r.conclusion,
    }));
  return json({ builds });
}

async function handleCancel(id, env) {
  const resp = await githubFetch(
    env,
    `/repos/${env.GITHUB_REPO}/actions/runs/${id}/cancel`,
    { method: "POST" },
  );
  if (resp.status === 202 || resp.status === 204) {
    return json({ cancelled: true, run_id: id });
  }
  const text = await resp.text();
  return json(
    { error: `Cancel failed (${resp.status}): ${text}` },
    resp.status,
  );
}

function handleHealth(env) {
  return json({
    ok: true,
    worker: "The Forge",
    repo: env.GITHUB_REPO,
    ref: env.GITHUB_REF,
    workflow: env.WORKFLOW_NAME || WORKFLOW_NAME,
    artifact: env.ARTIFACT_NAME || ARTIFACT_NAME,
    targets: TARGETS,
    configured: Boolean(env.GITHUB_TOKEN),
  });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === "OPTIONS") {
      return new Response(null, { status: 204, headers: CORS });
    }

    // /api/health
    if (url.pathname === "/api/health") {
      return handleHealth(env);
    }

    // /api/build
    if (url.pathname === "/api/build" && request.method === "POST") {
      return handleBuild(request, env);
    }

    // /api/builds (history)
    if (url.pathname === "/api/builds") {
      return handleHistory(env);
    }

    // /api/build/:id[/download|/manifest|/cancel]
    const m = url.pathname.match(/^\/api\/build\/(\d+)(\/(download|manifest|cancel))?$/);
    if (m) {
      const id = Number(m[1]);
      const action = m[3];
      if (action === "download") {
        const format = url.searchParams.get("format") === "hex" ? "hex" : "bin";
        return handleDownload(id, env, format);
      }
      if (action === "manifest") return handleManifest(id, env);
      if (action === "cancel") return handleCancel(id, env);
      return handleStatus(id, env);
    }

    // The worker hosts no UI. Root bounces visitors to the Studio flasher.
    if (url.pathname === "/") {
      const [owner, repo] = (env.GITHUB_REPO || "dantiel/OrniFlight").split("/");
      return Response.redirect(
        `https://${owner}.github.io/${repo}/#/system/flash`,
        302,
      );
    }

    return json({ error: "Not found." }, 404);
  },
};