import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { visualizer } from 'rollup-plugin-visualizer';
import { VitePWA } from 'vite-plugin-pwa';
import { compile as compileChaml } from 'coffeehaml';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import {
  CHAML_RE,
  COFFEE_RE,
  compileCoffee,
  compileChamlComponent,
  createComponentRegistry,
} from './scripts/chaml-shared.mjs';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/**
 * Vite 6 compat plugin.
 * resolveId redirects .chaml/.coffee → .jsx so Rollup's
 * buildImportAnalysisPlugin treats them as JS(X).
 * load compiles them to JS and returns the result.
 */
function prePlugin() {
  const compiled = new Map();
  const { generateComponentImports } = createComponentRegistry(__dirname);

  const compileChamlAt = (ctx, realId) => {
    let src;
    try { src = fs.readFileSync(realId, 'utf8'); }
    catch { return null; }
    ctx.addWatchFile(realId);
    const cached = compiled.get(realId);
    if (cached && cached.src === src) return cached.out;
    const stem = path.basename(realId).split('.').shift() || 'Cmp';
    const name = stem.charAt(0).toUpperCase() + stem.slice(1);
    const code = compileChamlComponent(realId, src, name, {
      generateComponentImports,
      useCreateElement: false,
      fail: (err) => ctx.error({ message: err.message, id: realId }),
    });
    if (code == null) return null;
    const out = { code, map: null };
    compiled.set(realId, { src, out });
    return out;
  };

  const compileCoffeeAt = (ctx, realId) => {
    let src;
    try { src = fs.readFileSync(realId, 'utf8'); }
    catch { return null; }
    ctx.addWatchFile(realId);
    const cached = compiled.get(realId);
    if (cached && cached.src === src) return cached.out;
    try {
      const out = compileCoffee(src, realId);
      compiled.set(realId, { src, out });
      return out;
    } catch (e) {
      ctx.error({ message: e.message, id: realId });
      return null;
    }
  };

  return {
    name: 'oracle-pre',
    enforce: 'pre',

    resolveId(source, importer) {
      if (CHAML_RE.test(source) || COFFEE_RE.test(source)) {
        // Strip leading / so path.resolve treats source as relative
        const rel = source.startsWith('/') ? '.' + source : source;
        const base = importer ? path.dirname(importer) : __dirname;
        return path.resolve(base, rel) + '.jsx';
      }
      return null;
    },

    load(id) {
      // Handle raw .coffee files (from HTML entry, bypassing resolveId)
      if (id.endsWith('.coffee') && !id.endsWith('.coffee.jsx')) {
        return compileCoffeeAt(this, id);
      }
      // Handle raw .chaml files (from HTML entry)
      if (CHAML_RE.test(id) && !id.endsWith('.chaml.jsx')) {
        return compileChamlAt(this, id);
      }
      // chaml virtual
      if (id.endsWith('.chaml.jsx')) {
        return compileChamlAt(this, id.replace(/\.jsx$/, ''));
      }
      // coffee virtual
      if (id.endsWith('.coffee.jsx')) {
        return compileCoffeeAt(this, id.replace(/\.jsx$/, ''));
      }
      return null;
    },

    // Fallback for dev mode (resolveId sometimes skipped)
    transform(code, id) {
      if (CHAML_RE.test(id)) {
        const result = compileChaml(code, {
          sourceMap: true,
          wrap: 'component',
          filename: id,
          componentName: path.basename(id).split('.').shift() || 'Cmp',
        });
        if (result.errors.length > 0) return null;
        const out = '// @refresh reset\n' + result.code.replace(/jsx\(([^,]+), null\)/g, 'jsx($1, {})');
        compiled.set(id, { src: code, out });
        return { code: out, map: result.sourceMap ? { mappings: result.sourceMap } : null };
      }
      if (COFFEE_RE.test(id)) {
        try {
          return compileCoffee(code, id);
        } catch (e) {
          this.error({ message: e.message, id });
          return null;
        }
      }
      return null;
    },

    // Vite dev invalidates modules via fileToModulesMap, keyed by
    // mod.file = cleanUrl(resolvedId). Our resolveId appends `.jsx` to
    // .coffee/.chaml, so the virtual module is keyed by a path that does
    // not exist on disk — a change to the real source file finds nothing
    // to invalidate and the stale transform is served forever. Map the
    // changed source back to its virtual module and invalidate it.
    handleHotUpdate(ctx) {
      const { file, server } = ctx;
      if (!CHAML_RE.test(file) && !COFFEE_RE.test(file)) return;
      compiled.delete(path.resolve(file));
      const virtualId = path.resolve(file) + '.jsx';
      const mod = server.moduleGraph.getModuleById(virtualId);
      if (mod) {
        server.moduleGraph.invalidateModule(mod);
        return [mod];
      }
      return [];
    },
  };
}

export default defineConfig({
  plugins: [
    prePlugin(),
    react(),
    VitePWA({
      registerType: 'autoUpdate',
      includeAssets: ['favicon.ico', 'icon-192.png', 'icon-512.png'],
      manifest: {
        name: 'OrniFlight Studio',
        short_name: 'OrniFlight',
        description: 'Integrated engineering environment for ornithopter flight control',
        start_url: '/',
        display: 'standalone',
        background_color: '#1a1a1c',
        theme_color: '#3a4192',
        orientation: 'landscape-primary',
        icons: [
          { src: '/icon-192.png', sizes: '192x192', type: 'image/png' },
          { src: '/icon-512.png', sizes: '512x512', type: 'image/png' },
        ],
      },
      workbox: {
        globPatterns: ['**/*.{js,css,html,ico,png,svg,woff2}'],
        runtimeCaching: [
          {
            urlPattern: /^https?:\/\/.*/i,
            handler: 'NetworkFirst',
            options: {
              cacheName: 'orniflight-cache',
              expiration: { maxEntries: 200, maxAgeSeconds: 60 * 60 * 24 * 7 },
            },
          },
        ],
      },
    }),
    visualizer({ open: true, gzipSize: true, brotliSize: true, filename: 'dist/stats.html' }),
  ],
  resolve: { alias: { '@': path.resolve(__dirname, 'src') } },
  css: { preprocessorOptions: { sass: { api: 'modern-compiler' } } },
  server: { port: 3030, open: true },
});