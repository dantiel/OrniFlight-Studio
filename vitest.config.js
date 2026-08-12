import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
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

function prePlugin() {
  const compiled = new Map();
  const { generateComponentImports } = createComponentRegistry(__dirname);
  // vitest resolves absolute /src/... ids relative to the project root.
  const toRealPath = (p) => p.startsWith('/src/') ? path.resolve(__dirname, '.' + p) : p;

  const compileChamlAt = (realId) => {
    if (compiled.has(realId)) return compiled.get(realId);
    let src;
    try { src = fs.readFileSync(realId, 'utf8'); }
    catch { return null; }
    const stem = path.basename(realId).split('.').shift() || 'Cmp';
    const name = stem.charAt(0).toUpperCase() + stem.slice(1);
    const code = compileChamlComponent(realId, src, name, {
      generateComponentImports,
      useCreateElement: true,
      fail: (err) => { throw err; },
    });
    if (code == null) return null;
    const out = { code, map: null };
    compiled.set(realId, out);
    return out;
  };

  const compileCoffeeAt = (realId) => {
    if (compiled.has(realId)) return compiled.get(realId);
    let src;
    try { src = fs.readFileSync(realId, 'utf8'); }
    catch { return null; }
    try {
      const out = compileCoffee(src, realId);
      compiled.set(realId, out);
      return out;
    } catch (e) {
      this.error({ message: e.message, id: realId });
      return null;
    }
  };

  return {
    name: 'oracle-pre',
    enforce: 'pre',

    resolveId(source, importer) {
      if (CHAML_RE.test(source) || COFFEE_RE.test(source)) {
        const rel = source.startsWith('/') ? '.' + source : source;
        const base = source.startsWith('/') ? __dirname : (importer ? path.dirname(importer) : __dirname);
        return path.resolve(base, rel) + '.jsx';
      }
      return null;
    },

    load(id) {
      // Raw .coffee
      if (id.endsWith('.coffee') && !id.endsWith('.coffee.jsx')) {
        return compileCoffeeAt(toRealPath(id));
      }
      // Raw .chaml
      if (CHAML_RE.test(id) && !id.endsWith('.chaml.jsx')) {
        return compileChamlAt(toRealPath(id));
      }
      // .chaml.jsx virtual
      if (id.endsWith('.chaml.jsx')) {
        return compileChamlAt(toRealPath(id.replace(/\.jsx$/, '')));
      }
      // .coffee.jsx virtual
      if (id.endsWith('.coffee.jsx')) {
        return compileCoffeeAt(toRealPath(id.replace(/\.jsx$/, '')));
      }
      return null;
    },

    transform(code, id) {
      if (CHAML_RE.test(id)) {
        const stem = path.basename(id).split('.').shift() || 'Cmp';
        const name = stem.charAt(0).toUpperCase() + stem.slice(1);
        try {
          const out = compileChamlComponent(id, code, name, {
            generateComponentImports,
            useCreateElement: true,
            fail: (err) => { throw err; },
          });
          return { code: out, map: null };
        } catch { return null; }
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
  };
}

export default defineConfig({
  plugins: [prePlugin(), react()],
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['./src/test/setup.js'],
    css: true,
    include: ['src/test/**/*.test.{coffee,js,mjs}'],
  },
  resolve: {
    extensions: ['.coffee', '.chaml', '.js', '.jsx', '.ts', '.tsx'],
  },
});
