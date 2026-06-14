// Merge the gold-focused solve (routes.json) with the win-first solve
// (routes-win.json) into the canonical routes.json. Per level, keep the best
// outcome: gold > win > unsolved, breaking ties by fewest kicks.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import type { RoutesFile, LevelRoute } from '../src/game/sim/route-types';

const GOLD = fileURLToPath(new URL('../src/data/routes.json', import.meta.url));
const WIN = fileURLToPath(new URL('../src/data/routes-win.json', import.meta.url));
const rank: Record<string, number> = { gold: 3, win: 2, unsolved: 1 };

const load = (p: string): RoutesFile =>
  existsSync(p) ? (JSON.parse(readFileSync(p, 'utf8')) as RoutesFile) : { version: 1, levels: {} };

const gold = load(GOLD);
const win = load(WIN);
const merged: RoutesFile = { version: 1, generated: new Date().toISOString(), levels: {} };

const keys = new Set([...Object.keys(gold.levels), ...Object.keys(win.levels)]);
for (const k of [...keys].sort((a, b) => Number(a) - Number(b))) {
  const cands = [gold.levels[k], win.levels[k]].filter(Boolean) as LevelRoute[];
  cands.sort((x, y) => rank[y.status] - rank[x.status] || (x.numKicks ?? 1e9) - (y.numKicks ?? 1e9));
  merged.levels[k] = cands[0] ?? { status: 'unsolved', kicks: [] };
}

writeFileSync(GOLD, JSON.stringify(merged, null, 2) + '\n');

const by = (s: string): string[] =>
  Object.entries(merged.levels)
    .filter(([, r]) => r.status === s)
    .map(([k]) => k);
console.log(`merged -> routes.json`);
console.log(`gold:     ${by('gold').length}  [${by('gold').join(', ')}]`);
console.log(`win:      ${by('win').length}  [${by('win').join(', ')}]`);
console.log(`unsolved: ${by('unsolved').length}  [${by('unsolved').join(', ')}]`);
