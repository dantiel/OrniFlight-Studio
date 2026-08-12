import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import coffeeScript from 'coffeescript';
import { compile as compileChaml } from 'coffeehaml';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const CHAML_RE = /\.(coffeehaml|cohaml|chaml)$/;
const COFFEE_RE = /\.coffee$/;

const fixRuntime = (code) => code
  .replace(
    'import { jsx, jsxs, Fragment } from "react/jsx-runtime";',
    "import { createElement, Fragment } from 'react';\nvar jsx = createElement;\nvar jsxs = function(type, props) { return createElement(type, props, ...(props.children || [])); };"
  )
  .replace(/jsx\(([^,]+), null\)/g, 'jsx($1, {})');

// Component registry — built once from src/components/ tree.
let componentPaths = null;
const getComponentPaths = () => {
  if (componentPaths) return componentPaths;
  componentPaths = {};
  const walk = (dir) => {
    try {
      const entries = fs.readdirSync(dir, { withFileTypes: true });
      for (const entry of entries) {
        if (!entry.isFile()) continue;
        const stem = path.basename(entry.name, path.extname(entry.name));
        if ((entry.name.endsWith('.chaml') || entry.name.endsWith('.coffee')) &&
            stem[0] === stem[0].toUpperCase()) {
          componentPaths[stem] = path.join(dir, entry.name);
        }
      }
      for (const entry of entries) {
        if (!entry.isDirectory()) continue;
        const fp = path.join(dir, entry.name);
        const chaml = path.join(fp, entry.name + '.chaml');
        const coffee = path.join(fp, entry.name + '.coffee');
        if (fs.existsSync(chaml)) componentPaths[entry.name] = chaml;
        else if (fs.existsSync(coffee)) componentPaths[entry.name] = coffee;
        walk(fp);
      }
    } catch {}
  };
  const compDir = path.resolve(__dirname, 'src/components');
  if (fs.existsSync(compDir)) walk(compDir);
  return componentPaths;
};

const generateComponentImports = (code, filePath) => {
  const paths = getComponentPaths();
  const seen = new Set();
  // Collect already-imported names to avoid duplicates.
  for (const m of code.matchAll(
    /import\s+(?:(\w+)\s*,?\s*)?(?:\{([^}]*)\})?\s*from/g
  )) {
    if (m[1]) seen.add(m[1]);
    if (m[2]) for (const n of m[2].split(',')) {
      seen.add(n.trim().split(' as ').pop().trim());
    }
  }
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

const compileChamlComponent = (realId, src, name) => {
  const result = compileChaml(src, {
    sourceMap: true, wrap: null, filename: realId,
  });
  if (result.errors.length > 0)
    throw new Error(result.errors[0].message);
  const compImports = generateComponentImports(result.code, realId);
  let code = fixRuntime(result.code);
  // Separate imports + fixRuntime vars (module-level) from body.
  // coffeehaml@0.7.4 outputs multiline `import {\n  x\n} from` stanzas.
  // fixRuntime injects `var jsx`/`var jsxs` after jsx-runtime import removal.
  const lines = code.split('\n');
  let splitAt = 0;
  let inMultiline = false;
  for (let i = 0; i < lines.length; i++) {
    const ln = lines[i].trim();
    if (!ln) { splitAt = i + 1; continue; }
    if (ln.startsWith('//')) { splitAt = i + 1; continue; }
    if (
      ln.startsWith('import ') ||
      ln.startsWith('var jsx') ||
      ln.startsWith('var jsxs')
    ) {
      splitAt = i + 1;
      inMultiline = ln.startsWith('import ') && ln.endsWith('{');
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
  // Find it and prepend `return `.
  const bodyLines = body.split('\n');
  for (let i = bodyLines.length - 1; i >= 0; i--) {
    const trimmed = bodyLines[i].trimStart();
    if (/^jsxs?\(/.test(trimmed)) {
      bodyLines[i] = bodyLines[i].replace(/^(\s*)/, '$1return ');
      break;
    }
  }

  return [
    '// @refresh reset',
    imports,
    `export default function ${name}(props) {`,
    bodyLines.join('\n'),
    '}',
  ].join('\n');
};

function prePlugin() {
  const compiled = new Map();

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
      const toRealPath = (p) => p.startsWith('/src/') ? path.resolve(__dirname, '.' + p) : p;

      // Raw .coffee
      if (id.endsWith('.coffee') && !id.endsWith('.coffee.jsx')) {
        const realId = toRealPath(id);
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        try {
          const result = coffeeScript.compile(src, { bare: true, sourceMap: true, filename: realId });
          const out = typeof result === 'string' ? result : result.js;
          compiled.set(realId, out);
          return { code: out, map: null };
        } catch (e) {
          this.error({ message: e.message, id: realId });
          return null;
        }
      }

      // Raw .chaml
      if (CHAML_RE.test(id) && !id.endsWith('.chaml.jsx')) {
        const realId = toRealPath(id);
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        const stem = path.basename(realId).split('.').shift() || 'Cmp';
        const name = stem.charAt(0).toUpperCase() + stem.slice(1);
        try {
          const code = compileChamlComponent(realId, src, name);
          compiled.set(realId, { code, map: null });
          return { code, map: null };
        } catch (e) {
          this.error({ message: e.message, id: realId });
          return null;
        }
      }

      // .chaml.jsx virtual
      if (id.endsWith('.chaml.jsx')) {
        const realId = toRealPath(id.replace(/\.jsx$/, ''));
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        const stem = path.basename(realId).split('.').shift() || 'Cmp';
        const name = stem.charAt(0).toUpperCase() + stem.slice(1);
        try {
          const code = compileChamlComponent(realId, src, name);
          compiled.set(realId, { code, map: null });
          return { code, map: null };
        } catch (e) {
          this.error({ message: e.message, id: realId });
          return null;
        }
      }

      // .coffee.jsx virtual
      if (id.endsWith('.coffee.jsx')) {
        const realId = toRealPath(id.replace(/\.jsx$/, ''));
        if (compiled.has(realId)) return compiled.get(realId);
        let src;
        try { src = fs.readFileSync(realId, 'utf8'); }
        catch { return null; }
        try {
          const result = coffeeScript.compile(src, { bare: true, sourceMap: true, filename: realId });
          const out = typeof result === 'string' ? result : result.js;
          compiled.set(realId, out);
          return { code: out, map: null };
        } catch (e) {
          this.error({ message: e.message, id: realId });
          return null;
        }
      }

      return null;
    },

    transform(code, id) {
      if (CHAML_RE.test(id)) {
        const stem = path.basename(id).split('.').shift() || 'Cmp';
        const name = stem.charAt(0).toUpperCase() + stem.slice(1);
        try {
          const out = compileChamlComponent(id, code, name);
          return { code: out, map: null };
        } catch { return null; }
      }
      if (COFFEE_RE.test(id)) {
        try {
          const result = coffeeScript.compile(code, { bare: true, sourceMap: true, filename: id });
          const out = typeof result === 'string' ? result : result.js;
          return { code: out, map: null };
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