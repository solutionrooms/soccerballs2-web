// Route solver orchestrator. Runs the beam-search solver for each level, fanning
// every ply's candidate kicks across a pool of recyclable worker processes
// (tools/solve-chunk.ts) so the search runs at machine speed across all cores.
// Writes src/data/routes.json (checkpointed after every level) and prints a
// gold / win / unsolved breakdown.
//
//   npx tsx tools/solve-routes.ts            # all 36 levels
//   npx tsx tools/solve-routes.ts 0,5,13     # only these levels
//   LEVEL_BUDGET_MS=180000 npx tsx tools/...  # per-level time budget
import { spawn } from 'node:child_process';
import { writeFileSync, readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import os from 'node:os';
import { LEVELS } from '../src/game/level-loader';
import { solveLevel, type BatchEvaluator, type EvalOpts } from '../src/game/sim/solver';
import type { RouteKick, RoutesFile } from '../src/game/sim/route-types';
import type { RunResult } from '../src/game/sim/replay';
import { verifyRoute } from './pool';

const CHUNK_WORKER = fileURLToPath(new URL('./solve-chunk.ts', import.meta.url));
const OUT = process.env.OUT_FILE
  ? fileURLToPath(new URL(process.env.OUT_FILE, import.meta.url))
  : fileURLToPath(new URL('../src/data/routes.json', import.meta.url));
const WIN_FIRST = process.env.WIN_FIRST === '1';
// when two solvers run at once, split the cores between them
const CONCURRENCY = Math.max(1, Number(process.env.WORKERS ?? os.cpus().length - 1));
const CHUNK = Number(process.env.CHUNK_SIZE ?? 150); // worlds per process before recycle
const TIME_BUDGET = Number(process.env.LEVEL_BUDGET_MS ?? 90_000);

/** Spawn a fresh worker for one chunk; resolves with one RunResult per route. */
function runChunk(index: number, routes: RouteKick[][], opts: EvalOpts): Promise<RunResult[]> {
  return new Promise((resolve, reject) => {
    const child = spawn('node', ['--import', 'tsx', CHUNK_WORKER], { stdio: ['pipe', 'pipe', 'inherit'] });
    let out = '';
    child.stdout.setEncoding('utf8');
    child.stdout.on('data', (d) => (out += d));
    child.on('error', reject);
    child.on('close', (code) => {
      if (code !== 0) return reject(new Error(`chunk worker exited ${code}`));
      try {
        resolve(JSON.parse(out) as RunResult[]);
      } catch (e) {
        reject(new Error(`bad chunk output: ${(e as Error).message}`));
      }
    });
    child.stdin.write(JSON.stringify({ index, routes, opts }));
    child.stdin.end();
  });
}

/** BatchEvaluator that splits a ply's candidates into chunks and runs up to CONCURRENCY at once. */
const evaluate: BatchEvaluator = async (index, routes, opts) => {
  const chunks: RouteKick[][][] = [];
  for (let i = 0; i < routes.length; i += CHUNK) chunks.push(routes.slice(i, i + CHUNK));
  const results: RunResult[][] = new Array(chunks.length);
  let next = 0;
  const worker = async (): Promise<void> => {
    for (;;) {
      const my = next++;
      if (my >= chunks.length) return;
      results[my] = await runChunk(index, chunks[my], opts);
    }
  };
  await Promise.all(Array.from({ length: Math.min(CONCURRENCY, chunks.length) }, () => worker()));
  return results.flat();
};

async function main(): Promise<void> {
  const only = process.argv[2] ? process.argv[2].split(',').map((s) => Number(s.trim())) : null;
  // resume from an existing routes.json so partial / subset runs accumulate
  const routes: RoutesFile = existsSync(OUT)
    ? (JSON.parse(readFileSync(OUT, 'utf8')) as RoutesFile)
    : { version: 1, levels: {} };
  routes.version = 1;

  console.log(`Solving with ${CONCURRENCY} workers, chunk=${CHUNK}, budget=${TIME_BUDGET / 1000}s/level`);
  for (let i = 0; i < LEVELS.length; i++) {
    if (only && !only.includes(i)) continue;
    const def = LEVELS[i];
    const t0 = Date.now();
    process.stdout.write(`[${String(i).padStart(2)}] "${def.name}" gold=${def.goldKicks} ... `);
    try {
      const log = process.env.SOLVE_LOG ? (m: string): void => console.log(`      ${m}`) : undefined;
      const route = await solveLevel(i, evaluate, {
        timeBudgetMs: TIME_BUDGET,
        log,
        winFirst: WIN_FIRST,
        angleStepDeg: process.env.ANGLE_STEP ? Number(process.env.ANGLE_STEP) : undefined,
        powerSteps: process.env.POWER_STEPS ? Number(process.env.POWER_STEPS) : undefined,
        beamWidth: process.env.BEAM_WIDTH ? Number(process.env.BEAM_WIDTH) : undefined,
        maxDepth: process.env.MAX_DEPTH ? Number(process.env.MAX_DEPTH) : undefined,
      });
      // accept only routes that reproduce in a fresh process (nape pool state is
      // history-dependent, so a route validated mid-chunk may be fragile)
      if (route.status !== 'unsolved' && route.kicks.length) {
        const fresh = await verifyRoute(i, route.kicks);
        if (!fresh?.success || fresh.numKicks > def.failKicks) {
          route.status = 'unsolved';
          route.kicks = [];
        } else {
          route.status = fresh.numKicks <= def.goldKicks ? 'gold' : 'win';
          route.numKicks = fresh.numKicks;
        }
      }
      // never downgrade: keep the best route per level across runs
      const rank: Record<string, number> = { gold: 3, win: 2, unsolved: 1 };
      const cur = routes.levels[String(i)];
      const better = !cur || rank[route.status] > rank[cur.status] || (route.status === cur.status && (route.numKicks ?? 1e9) < (cur.numKicks ?? 1e9));
      if (better) routes.levels[String(i)] = route;
      console.log(`${route.status.toUpperCase()} ${route.kicks.length}k${better ? '' : ' (kept existing)'}  ${((Date.now() - t0) / 1000).toFixed(0)}s`);
    } catch (e) {
      if (!routes.levels[String(i)]) routes.levels[String(i)] = { status: 'unsolved', kicks: [], goldKicks: def.goldKicks };
      console.log(`ERROR: ${(e as Error).message}`);
    }
    routes.generated = new Date().toISOString();
    writeFileSync(OUT, JSON.stringify(routes, null, 2) + '\n');
  }

  // breakdown
  const all = Object.entries(routes.levels);
  const by = (s: string): string[] => all.filter(([, r]) => r.status === s).map(([k]) => k);
  console.log(`\n=== DONE ===`);
  console.log(`gold:     ${by('gold').length}  [${by('gold').join(', ')}]`);
  console.log(`win:      ${by('win').length}  [${by('win').join(', ')}]`);
  console.log(`unsolved: ${by('unsolved').length}  [${by('unsolved').join(', ')}]`);
  console.log(`-> ${OUT}`);
}

void main();
