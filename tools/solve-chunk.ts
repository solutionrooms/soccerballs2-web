// One-shot chunk evaluator for the route solver. Reads a job from stdin, runs
// each candidate route headless, writes the results to stdout, exits. Kept
// short-lived on purpose: a fresh Nape world leaks ~0.8MB and nape.js can't
// reset a Space, so the orchestrator bounds each process to ~150 trials and
// spawns a new one for the next chunk (see tools/solve-routes.ts).
import '../src/game/nape-test-setup';
import { runRoute, type RunResult } from '../src/game/sim/replay';
import type { RouteKick } from '../src/game/sim/route-types';

interface ChunkJob {
  index: number;
  routes: RouteKick[][];
  opts: { abortStuckFrames: number; maxFrames: number };
}

// A candidate route can throw deep in Nape (e.g. destroying a welded body leaves
// a dangling joint on some levels). Treat that as a failed candidate so one bad
// kick doesn't kill the whole chunk (and the level).
const FAILED: RunResult = {
  success: false,
  failed: true,
  numKicks: 999,
  kicksIssued: 0,
  minGoalDist: 1e9, // JSON-safe "very far"
  numGoalsScored: 0,
  numRefsHit: 0,
  totalGoals: 0,
  totalRefs: 0,
  worldChanges: 0,
  ballX: 0,
  ballY: 0,
  frames: 0,
};

let buf = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (d) => (buf += d));
process.stdin.on('end', () => {
  const job = JSON.parse(buf) as ChunkJob;
  const out: RunResult[] = job.routes.map((r) => {
    try {
      return runRoute(job.index, r, job.opts);
    } catch {
      return FAILED;
    }
  });
  process.stdout.write(JSON.stringify(out));
});
