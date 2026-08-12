#!/usr/bin/env node
// Width gate — prettier has no "line over printWidth" warning; this is ours.
// Reports lines exceeding 80 characters (code points, not bytes) and exits 1.
import { readdirSync, statSync, readFileSync } from 'node:fs'
import { join, extname } from 'node:path'

const LIMIT = Number(process.env.WIDTH_LIMIT || 80)
const EXTS = new Set(['.chaml', '.coffee', '.sass', '.scss', '.js', '.mjs', '.cjs'])
const IGNORE = new Set(['node_modules', 'dist', '.git', 'stats.html'])
const ROOT = process.argv[2] || 'src'

function walk(dir, out = []) {
  for (const name of readdirSync(dir)) {
    if (IGNORE.has(name)) continue
    const p = join(dir, name)
    const st = statSync(p)
    if (st.isDirectory()) walk(p, out)
    else if (EXTS.has(extname(name))) out.push(p)
  }
  return out
}

let total = 0
for (const f of walk(ROOT)) {
  const lines = readFileSync(f, 'utf8').split('\n')
  lines.forEach((line, i) => {
    const len = [...line].length
    if (len > LIMIT) {
      total++
      console.log(`${f}:${i + 1}: ${len} chars`)
    }
  })
}

if (total) {
  console.error(`\n${total} line(s) exceed ${LIMIT} chars`)
  process.exit(1)
}
console.log(`width clean — all lines <= ${LIMIT} chars`)
