// Single source of truth for CoffeeHAML / CoffeeScript compilation.
// vite.config.js and vitest.config.js both import from here so the
// .chaml → JSX component transform can never drift between build and test.
// (It drifted once — the missing `return` injection — and 100/100 tests
// stayed green while the live app rendered blank.)

import coffeeScript from 'coffeescript';
import { compile as compileChaml } from 'coffeehaml';
import fs from 'fs';
import path from 'path';

export const CHAML_RE = /\.(coffeehaml|cohaml|chaml)$/;
export const COFFEE_RE = /\.coffee$/;

// vitest/jsdom has no esbuild JSX transform, so it swaps react/jsx-runtime
// for createElement + hand-rolled jsx/jsxs. vite keeps jsx-runtime.
const fixRuntime = (code) => code
  .replace(
    'import { jsx, jsxs, Fragment } from "react/jsx-runtime";',
    "import { createElement, Fragment } from 'react';\nvar jsx = createElement;\nvar jsxs = function(type, props) { return createElement(type, props, ...(props.children || [])); };"
  )
  .replace(/jsx\(([^,]+), null\)/g, 'jsx($1, {})');

// Compile .coffee source → { code, map }. Handles CoffeeScript's dual
// return shape (string when no sourcemap requested, { js, v3SourceMap } otherwise).
export const compileCoffee = (src, realId) => {
  const result = coffeeScript.compile(src, { bare: true, sourceMap: true, filename: realId });
  if (typeof result === 'string') return { code: result, map: null };
  return { code: result.js, map: result.v3SourceMap || null };
};

// Memoized PascalCase → file-path registry built from src/components/.
export const createComponentRegistry = (rootDir) => {
  let componentPaths = null;

  const getComponentPaths = () => {
    if (componentPaths) return componentPaths;
    componentPaths = {};
    const walk = (dir) => {
      let entries;
      try { entries = fs.readdirSync(dir, { withFileTypes: true }); }
      catch { return; }
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
    };
    const compDir = path.resolve(rootDir, 'src/components');
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

  return { getComponentPaths, generateComponentImports };
};

// Compile .chaml source → an ES module default-exporting a component.
// The JSX expression is the last top-level jsx/jsxs call — prepend `return`
// so the component actually renders (this was the empty-app root cause).
// `fail(err)` reports compile errors (vite uses this.error, vitest throws).
export const compileChamlComponent = (
  realId, src, name, { generateComponentImports, useCreateElement = false, fail }
) => {
  const result = compileChaml(src, { sourceMap: true, wrap: null, filename: realId });
  if (result.errors.length > 0) {
    const err = new Error(result.errors[0].message);
    if (fail) fail(err);
    return null;
  }

  const compImports = generateComponentImports(result.code, realId);
  let code = useCreateElement
    ? fixRuntime(result.code)
    : result.code.replace(/jsx\(([^,]+), null\)/g, 'jsx($1, {})');

  // Separate module-level lines (imports + fixRuntime vars) from the body.
  // coffeehaml@0.7.4 outputs multiline `import {\n  x\n} from` stanzas.
  const lines = code.split('\n');
  let splitAt = 0;
  let inMultiline = false;
  for (let i = 0; i < lines.length; i++) {
    const ln = lines[i].trim();
    if (!ln) { splitAt = i + 1; continue; }
    if (ln.startsWith('//')) { splitAt = i + 1; continue; }
    if (ln.startsWith('import ') || ln.startsWith('var jsx') || ln.startsWith('var jsxs')) {
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

  // The JSX expression is the last top-level jsx/jsxs call — prepend `return`.
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
