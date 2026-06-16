// Seeded route solver: reads a rough human plan from tools/seeds.json and uses
// the focused cone-search to perfect each shot, writing winning routes into
// src/data/routes.json (only overwriting a level when it improves on what's there).
//
//   npx tsx tools/solve-seeded.ts          # solve every seeded level
//   npx tsx tools/solve-seeded.ts 5,13     # only these
//
// seeds.json shape: { "<levelIndex>": { "kicks": [ { "angleDeg": 300, "power01": 0.9 }, ... ] } }
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { solveSeeded, type SeedKick } from '../src/game/sim/solver';
import { LEVELS } from '../src/game/level-loader';
import type { RoutesFile, RouteStatus } from '../src/game/sim/route-types';
import { makeEvaluator, verifyRoute } from './pool';

const OUT = fileURLToPath(new URL('../src/data/routes.json', import.meta.url));
const SEEDS = fileURLToPath(new URL('./seeds.json', import.meta.url));
const rank: Record<RouteStatus, number> = { gold: 3, win: 2, unsolved: 1 };

async function main(): Promise<void> {
  const seeds = JSON.parse(readFileSync(SEEDS, 'utf8')) as Record<string, { kicks: SeedKick[] }>;
  const routes: RoutesFile = existsSync(OUT)
    ? (JSON.parse(readFileSync(OUT, 'utf8')) as RoutesFile)
    : { version: 1, levels: {} };
  const only = process.argv[2] ? new Set(process.argv[2].split(',').map((s) => s.trim())) : null;
  const evaluate = makeEvaluator();
  const log = process.env.SEED_LOG ? (m: string): void => console.log(`      ${m}`) : undefined;

  for (const [key, plan] of Object.entries(seeds)) {
    if (only && !only.has(key)) continue;
    const i = Number(key);
    const t0 = Date.now();
    process.stdout.write(`[${key}] "${LEVELS[i].name}" gold=${LEVELS[i].goldKicks} seeded(${plan.kicks.length}) ... `);
    const route = await solveSeeded(i, plan.kicks, evaluate, { log });
    // accept only fresh-process-reproducible routes (nape pool state is history-dependent)
    if (route.status !== 'unsolved' && route.kicks.length) {
      const fresh = await verifyRoute(i, route.kicks);
      if (!fresh?.success || fresh.numKicks > LEVELS[i].failKicks) {
        route.status = 'unsolved';
        route.kicks = [];
      } else {
        route.status = fresh.numKicks <= LEVELS[i].goldKicks ? 'gold' : 'win';
        route.numKicks = fresh.numKicks;
      }
    }
    const existing = routes.levels[key];
    if (!existing || rank[route.status] > rank[existing.status]) routes.levels[key] = route;
    console.log(`${route.status.toUpperCase()} ${route.kicks.length}k ${route.note ? `(${route.note})` : ''} ${((Date.now() - t0) / 1000).toFixed(0)}s`);
    routes.generated = new Date().toISOString();
    writeFileSync(OUT, JSON.stringify(routes, null, 2) + '\n');
  }
  console.log('done');
}

void main();
