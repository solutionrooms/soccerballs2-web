// Side-effect import for Nape tests: load the compiled nape.js (a Haxe IIFE)
// into globalThis so `new NapePhysWorld(...)` can construct `globalThis.NapeWorld`.
// The project is an ES module, so we evaluate it with a CommonJS-style wrapper.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';

const path = fileURLToPath(new URL('../../public/assets/nape.js', import.meta.url));
const src = readFileSync(path, 'utf8');
const mod: { exports: Record<string, unknown> } = { exports: {} };
// eslint-disable-next-line @typescript-eslint/no-implied-eval
new Function('exports', 'module', 'window', 'global', 'self', src)(
  mod.exports,
  mod,
  undefined,
  globalThis,
  undefined,
);
(globalThis as Record<string, unknown>).NapeWorld = mod.exports.NapeWorld;
