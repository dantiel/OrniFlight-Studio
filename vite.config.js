import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { visualizer } from 'rollup-plugin-visualizer';
import { VitePWA } from 'vite-plugin-pwa';
import coffeeScript from 'coffeescript';
import { compile as compileChaml } from 'coffeehaml';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CHAML_RE = /\.(coffeehaml|cohaml|chaml)$/;
const COFFEE_RE = /\.coffee$/;

/**
 * Vite 6 compat plugin.
 * resolveId redirects .chaml/.coffee → .jsx so Rollup's
 * buildImportAnalysisPlugin treats them as JS(X).
 * load compiles them to JS and returns the result.
 */
function prePlugin() {
  const compiled = new Map();

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
        const realId = id;
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        try {
          const result = coffeeScript.compile(src, { bare: true, sourceMap: true, filename: realId });
          if (typeof result === 'string') {
            compiled.set(realId, result);
            return { code: result, map: null };
          }
          const code = result.js;
          compiled.set(realId, code);
          return { code, map: result.v3SourceMap || null };
        } catch (e) {
          this.error({ message: e.message, id: realId });
          return null;
        }
      }

      // Component registry — built once from src/components/ tree.
      // Maps PascalCase name → relative path from project root.
      let componentPaths = null;
      const getComponentPaths = () => {
        if (componentPaths) return componentPaths;
        componentPaths = {};
        const walk = (dir) => {
          try {
            const entries = fs.readdirSync(dir, { withFileTypes: true });
            // Flat .chaml/.coffee files in this directory
            for (const entry of entries) {
              if (!entry.isFile()) continue;
              const stem = path.basename(entry.name, path.extname(entry.name));
              if ((entry.name.endsWith('.chaml') || entry.name.endsWith('.coffee')) &&
                  stem[0] === stem[0].toUpperCase()) {
                componentPaths[stem] = path.join(dir, entry.name);
              }
            }
            // Recurse into subdirectories
            for (const entry of entries) {
              if (!entry.isDirectory()) continue;
              const fp = path.join(dir, entry.name);
              // Folder-per-component: look for Name/Name.ext
              const chaml = path.join(fp, entry.name + '.chaml');
              const coffee = path.join(fp, entry.name + '.coffee');
              if (fs.existsSync(chaml))
                componentPaths[entry.name] = chaml;
              else if (fs.existsSync(coffee))
                componentPaths[entry.name] = coffee;
              walk(fp);
            }
          } catch {}
        };
        const compDir = path.resolve(__dirname, 'src/components');
        if (fs.existsSync(compDir)) walk(compDir);
        return componentPaths;
      };

      // Generate import lines for components referenced in HAML output.
      const generateComponentImports = (code, filePath) => {
        const paths = getComponentPaths();
        const seen = new Set();
        // Collect already-imported names to avoid duplicates.
        for (const m of code.matchAll(
          /import\s+(?:(\w+)\s*,?\s*)?(?:\{([^}]*)\})?\s*from/g
        )) {
          if (m[1]) seen.add(m[1]);           // default import
          if (m[2]) for (const n of m[2].split(',')) {
            seen.add(n.trim().split(' as ').pop().trim());
          }
        }
        // Match jsx(ComponentName or jsxs(ComponentName
        const re = /\bjsxs?\((\p{Lu}[\w$]*)/gu;
        let imports = '';
        for (const m of code.matchAll(re)) {
          const name = m[1];
          if (name === 'Fragment' || seen.has(name)) continue;
          const compPath = paths[name];
          if (!compPath) continue;
          seen.add(name);
          const rel = path.relative(path.dirname(filePath), compPath);
          const importPath = (rel.startsWith('.') ? rel : './' + rel)
            .replace(/\\/g, '/');
          imports += `import ${name} from '${importPath}';\n`;
        }
        return imports;
      };

      // Shared: compile CoffeeHAML → clean JS component
      const compileChamlToJs = (realId, src, name) => {
        // coffeehaml@0.7.2 with wrap:'component' outputs CoffeeScript
        // arrows in the wrapper — esbuild can't parse them.
        // Use wrap:null for clean JS, then wrap manually.
        const result = compileChaml(src, {
          sourceMap: true,
          wrap: null,
          filename: realId,
        });
        if (result.errors.length > 0) {
          this.error({ message: result.errors[0].message, id: realId });
          return null;
        }
        let code = result.code.replace(
          /jsx\(([^,]+), null\)/g, 'jsx($1, {})'
        );
        // Auto-generate imports for components referenced in the output.
        const compImports = generateComponentImports(code, realId);
        // Separate imports (must stay at module level) from body.
        // coffeehaml@0.7.4 outputs multiline `import {\n  x\n} from` stanzas.
        const lines = code.split('\n');
        let splitAt = 0;
        let inMultiline = false;
        for (let i = 0; i < lines.length; i++) {
          const ln = lines[i].trim();
          if (!ln) { splitAt = i + 1; continue; }
          if (ln.startsWith('//')) { splitAt = i + 1; continue; }
          if (ln.startsWith('import ')) {
            splitAt = i + 1;
            inMultiline = ln.endsWith('{');
            continue;
          }
          if (inMultiline) {
            splitAt = i + 1;
            if (ln.startsWith('}')) inMultiline = false;
            continue;
          }
          break;
        }
        const imports = compImports + lines.slice(0, splitAt).join('\n');
        const body = lines.slice(splitAt).join('\n');
        // The JSX expression is the last top-level jsx/jsxs call.
        // Find it and prepend `return ` so the component actually renders.
        const bodyLines = body.split('\n');
        for (let i = bodyLines.length - 1; i >= 0; i--) {
          const trimmed = bodyLines[i].trimStart();
          if (/^jsxs?\(/.test(trimmed)) {
            bodyLines[i] = bodyLines[i].replace(/^(\s*)/, '$1return ');
            break;
          }
        }
        code = [
          '// @refresh reset',
          imports,
          `export default function ${name}(props) {`,
          bodyLines.join('\n'),
          '}',
        ].join('\n');
        return { code, map: null };
      };

      // Handle raw .chaml files (from HTML entry)
      if (CHAML_RE.test(id) && !id.endsWith('.chaml.jsx')) {
        const realId = id;
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        const stem = path.basename(realId).split('.').shift() || 'Cmp';
        const name = stem.charAt(0).toUpperCase() + stem.slice(1);
        const out = compileChamlToJs(realId, src, name);
        if (out) compiled.set(realId, out);
        return out;
      }

      // chaml virtual
      if (id.endsWith('.chaml.jsx')) {
        const realId = id.replace(/\.jsx$/, '');
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        const stem = path.basename(realId).split('.').shift() || 'Cmp';
        const name = stem.charAt(0).toUpperCase() + stem.slice(1);
        const out = compileChamlToJs(realId, src, name);
        if (out) compiled.set(realId, out);
        return out;
      }

      // coffee virtual
      if (id.endsWith('.coffee.jsx')) {
        const realId = id.replace(/\.jsx$/, '');
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        try {
          const result = coffeeScript.compile(src, { bare: true, sourceMap: true, filename: realId });
          if (typeof result === 'string') {
            compiled.set(realId, result);
            return { code: result, map: null };
          }
          const code = result.js;
          compiled.set(realId, code);
          return { code, map: result.v3SourceMap || null };
        } catch (e) {
          this.error({ message: e.message, id: realId });
          return null;
        }
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
        const out = '// @refresh reset\\n' + result.code.replace(/jsx\(([^,]+), null\)/g, 'jsx($1, {})');
        compiled.set(id, out);
        return { code: out, map: result.sourceMap ? { mappings: result.sourceMap } : null };
      }
      if (COFFEE_RE.test(id)) {
        try {
          const result = coffeeScript.compile(code, { bare: true, sourceMap: true, filename: id });
          if (typeof result === 'string') return { code: result, map: null };
          return { code: result.js, map: result.v3SourceMap || null };
        } catch (e) {
          this.error({ message: e.message, id });
          return null;
        }
      }
      return null;
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