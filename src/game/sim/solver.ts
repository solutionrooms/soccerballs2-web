// Headless route solver: depth-limited beam search over (angle, power) kick
// sequences, scored by how close the ball gets to a goal (plus credit for goals
// scored and refs hit). Targets the gold-kick bar; falls back to any win; else
// reports unsolved.
//
// Candidate evaluation is injected as an async BatchEvaluator so the orchestrator
// can fan a ply's candidates across a pool of recyclable worker processes (a
// fresh Nape world leaks ~0.8MB, so a single process can't run the whole search).
import type { RunResult } from './replay';
import { LEVELS, clamp01 } from './headless';
import type { RouteKick, LevelRoute } from './route-types';

/** Per-run knobs passed through to runRoute (serialisable for worker processes). */
export interface EvalOpts {
  abortStuckFrames: number;
  maxFrames: number;
}

/** Evaluate a batch of candidate routes, returning one RunResult per candidate, in order. */
export type BatchEvaluator = (index: number, routes: RouteKick[][], opts: EvalOpts) => Promise<RunResult[]>;

export interface SolveOpts {
  timeBudgetMs?: number;
  angleStepDeg?: number;
  powerSteps?: number;
  beamWidth?: number;
  maxDepth?: number;
  abortStuckFrames?: number;
  /** return the FIRST winning route found (any path to completion, <= failKicks),
   *  instead of spending the whole budget hunting for a gold-kick solution. */
  winFirst?: boolean;
  log?: (msg: string) => void;
  now?: () => number;
}

interface Node {
  kicks: RouteKick[];
  res: RunResult;
  score: number;
}

const NO_ABORT = 1_000_000; // "abortStuckFrames off" sentinel for exact validation

/** lower = closer to a win. Goals/refs dominate; activating switches/gates
 *  (worldChanges) is rewarded so gated levels get a gradient toward the switch;
 *  goal distance is the fine-grained tie-breaker. */
function scoreOf(res: RunResult): number {
  // goals scored and refs hit are the win sub-objectives; closeness to the goal
  // is the fine-grained gradient; a small, capped bonus for triggering a
  // switch/gate gives a gradient toward mechanisms without distracting the beam.
  return res.minGoalDist - res.numGoalsScored * 5000 - res.numRefsHit * 2000 - Math.min(res.worldChanges, 4) * 100;
}

/** bucket a candidate by ball rest + progress so the beam stays diverse. */
function bucketKey(res: RunResult): string {
  return `${Math.round(res.ballX / 24)},${Math.round(res.ballY / 24)},${res.numGoalsScored},${res.numRefsHit}`;
}

function topKDistinct(nodes: Node[], k: number): Node[] {
  nodes.sort((a, b) => a.score - b.score);
  const seen = new Set<string>();
  const out: Node[] = [];
  for (const n of nodes) {
    const key = bucketKey(n.res);
    if (seen.has(key)) continue;
    seen.add(key);
    out.push(n);
    if (out.length >= k) break;
  }
  return out;
}

function mkRoute(status: 'gold' | 'win', kicks: RouteKick[], res: RunResult, gold: number): LevelRoute {
  return { status, kicks, numKicks: res.numKicks, goldKicks: gold };
}

/** A rough human-planned kick to seed the focused search around. */
export interface SeedKick {
  /** approximate kick angle in degrees (0=right, 90=down, 180=left, 270=up). */
  angleDeg: number;
  /** approximate power 0..1; omit to sweep the full power range. */
  power01?: number;
  /** angle half-window to search around angleDeg (default 22). */
  aSpan?: number;
  /** power half-window around power01 (default 0.3; ignored if power01 omitted). */
  pSpan?: number;
}

/**
 * Seeded solve: given a rough plan (one SeedKick per shot), search a tight cone
 * around each shot to find the exact angle/power that chains to a win. Far more
 * reliable than blind search because the human supplies the structure (which way
 * each shot goes); the solver only perfects it. Returns the route, or unsolved
 * with telemetry-bearing note on how far the plan got.
 */
export async function solveSeeded(
  index: number,
  seeds: SeedKick[],
  evaluate: BatchEvaluator,
  opts: { beamWidth?: number; abortStuckFrames?: number; log?: (m: string) => void } = {},
): Promise<LevelRoute> {
  const gold = LEVELS[index].goldKicks;
  const beamWidth = opts.beamWidth ?? 8;
  const abortStuck = opts.abortStuckFrames ?? 200;
  const log = opts.log ?? ((): void => {});

  let beam: RouteKick[][] = [[]];
  let bestProgress = Infinity;

  for (let i = 0; i < seeds.length; i++) {
    const s = seeds[i];
    const aSpan = s.aSpan ?? 22;
    const angles: number[] = [];
    for (let a = -aSpan; a <= aSpan + 1e-9; a += 1.5) angles.push(s.angleDeg + a);
    const powers: number[] = [];
    if (s.power01 != null) {
      const pSpan = s.pSpan ?? 0.3;
      for (let p = Math.max(0, s.power01 - pSpan); p <= Math.min(1, s.power01 + pSpan) + 1e-9; p += 0.025) powers.push(p);
    } else {
      for (let p = 0; p <= 1.0001; p += 0.04) powers.push(p);
    }

    const candidates: RouteKick[][] = [];
    for (const prefix of beam) {
      for (const a of angles) for (const p of powers) candidates.push([...prefix, { angleDeg: a, power01: clamp01(p), waitFrames: 0 }]);
    }
    const maxFrames = 240 * (i + 1) + 240;
    const results = await evaluate(index, candidates, { abortStuckFrames: abortStuck, maxFrames });

    const nodes: { kicks: RouteKick[]; res: RunResult; score: number }[] = [];
    let win: RouteKick[] | null = null;
    let winKicks = Infinity;
    for (let j = 0; j < candidates.length; j++) {
      const res = results[j];
      if (!res) continue;
      if (res.success && res.numKicks < winKicks) {
        win = candidates[j];
        winKicks = res.numKicks;
      }
      nodes.push({ kicks: candidates[j], res, score: scoreOf(res) });
    }
    if (win) {
      const exact = (await evaluate(index, [win], { abortStuckFrames: NO_ABORT, maxFrames: 4000 }))[0];
      if (exact?.success) {
        const status = exact.numKicks <= gold ? 'gold' : 'win';
        log(`seeded ${status} after shot ${i + 1} (numKicks=${exact.numKicks})`);
        return mkRoute(status, win, exact, gold);
      }
    }
    beam = topKDistinct(nodes, beamWidth).map((n) => n.kicks);
    bestProgress = nodes.length ? Math.min(...nodes.map((n) => n.res.minGoalDist)) : bestProgress;
    log(`shot ${i + 1}/${seeds.length} (~${s.angleDeg}°): best objective-dist=${bestProgress.toFixed(0)}, beam=${beam.length}`);
    if (beam.length === 0) break;
  }
  return {
    status: 'unsolved',
    kicks: [],
    goldKicks: gold,
    note: `seeded plan reached objective-dist ${bestProgress.toFixed(0)} but did not finish`,
  };
}

export async function solveLevel(index: number, evaluate: BatchEvaluator, opts: SolveOpts = {}): Promise<LevelRoute> {
  const def = LEVELS[index];
  const gold = def.goldKicks;
  const now = opts.now ?? ((): number => Date.now());
  const budget = opts.timeBudgetMs ?? 120_000;
  const t0 = now();
  const timeUp = (): boolean => now() - t0 > budget;
  const angleStep = opts.angleStepDeg ?? 5;
  const powerSteps = opts.powerSteps ?? 11;
  const beamWidth = opts.beamWidth ?? 16;
  // search deep enough to find a WIN (<= failKicks) even when the gold bar is
  // tight — a winning, watchable route beats "unsolved". Gold is still returned
  // the instant a <= goldKicks solution is found; deeper plies are the win hunt.
  const maxDepth = Math.min(def.failKicks, opts.maxDepth ?? 6);
  const abortStuck = opts.abortStuckFrames ?? 170;
  const log = opts.log ?? ((): void => {});

  const angles: number[] = [];
  for (let a = 0; a < 360; a += angleStep) angles.push(a);
  const powers: number[] = [];
  for (let i = 0; i < powerSteps; i++) powers.push(powerSteps === 1 ? 1 : i / (powerSteps - 1));

  let best: { route: RouteKick[]; res: RunResult } | null = null;
  let beam: RouteKick[][] = [[]];
  let trials = 0;

  for (let depth = 1; depth <= maxDepth && !timeUp(); depth++) {
    const candidates: RouteKick[][] = [];
    for (const prefix of beam) {
      for (const ang of angles) {
        for (const pow of powers) {
          candidates.push([...prefix, { angleDeg: ang, power01: pow, waitFrames: 0 }]);
        }
      }
    }
    const maxFrames = 220 * depth + 220;
    const results = await evaluate(index, candidates, { abortStuckFrames: abortStuck, maxFrames });
    trials += candidates.length;

    const nodes: Node[] = [];
    let goldCand: Node | null = null;
    for (let i = 0; i < candidates.length; i++) {
      const res = results[i];
      if (!res) continue;
      const node: Node = { kicks: candidates[i], res, score: scoreOf(res) };
      nodes.push(node);
      if (res.success) {
        if (!best || res.numKicks < best.res.numKicks) best = { route: candidates[i], res };
        if (res.numKicks <= gold && (!goldCand || res.numKicks < goldCand.res.numKicks)) goldCand = node;
      }
    }

    if (goldCand) {
      // confirm under the real ball-timeout (no abort), then accept
      const exact = (await evaluate(index, [goldCand.kicks], { abortStuckFrames: NO_ABORT, maxFrames: 4000 }))[0];
      if (exact?.success && exact.numKicks <= gold) {
        log(`gold @ depth ${depth} (numKicks=${exact.numKicks}, ${trials} trials)`);
        return mkRoute('gold', goldCand.kicks, exact, gold);
      }
    }

    // win-first: as soon as ANY winning route exists, accept it (don't burn the
    // budget chasing gold). Gold is still returned above when actually found.
    if (opts.winFirst && best !== null) {
      const b: { route: RouteKick[]; res: RunResult } = best;
      const exact = (await evaluate(index, [b.route], { abortStuckFrames: NO_ABORT, maxFrames: 4000 }))[0];
      if (exact?.success) {
        const status = exact.numKicks <= gold ? 'gold' : 'win';
        log(`win-first ${status} @ depth ${depth} (numKicks=${exact.numKicks}, ${trials} trials)`);
        return mkRoute(status, b.route, exact, gold);
      }
    }

    // local refinement: the coarse grid often gets *close* on a precise bank shot
    // but just misses. Finely vary the last kick of the few near-miss candidates
    // to nail it — cheap and catches the rebound/precision levels.
    const nearMiss = [...nodes].sort((a, b) => a.res.minGoalDist - b.res.minGoalDist).slice(0, 3).filter((n) => n.res.minGoalDist <= 130);
    if (nearMiss.length > 0 && !timeUp()) {
      const refine: RouteKick[][] = [];
      for (const n of nearMiss) {
        const last = n.kicks[n.kicks.length - 1];
        const prefix = n.kicks.slice(0, -1);
        for (let da = -8; da <= 8.001; da += 0.5) {
          for (let dp = -0.12; dp <= 0.12001; dp += 0.02) {
            if (da === 0 && dp === 0) continue;
            refine.push([...prefix, { angleDeg: last.angleDeg + da, power01: clamp01(last.power01 + dp), waitFrames: 0 }]);
          }
        }
      }
      const rres = await evaluate(index, refine, { abortStuckFrames: abortStuck, maxFrames });
      trials += refine.length;
      let goldRefine: RouteKick[] | null = null;
      let goldRefineKicks = Infinity;
      for (let i = 0; i < refine.length; i++) {
        const res = rres[i];
        if (!res) continue;
        if (res.success) {
          if (!best || res.numKicks < best.res.numKicks) best = { route: refine[i], res };
          if (res.numKicks <= gold && res.numKicks < goldRefineKicks) {
            goldRefine = refine[i];
            goldRefineKicks = res.numKicks;
          }
        }
        nodes.push({ kicks: refine[i], res, score: scoreOf(res) }); // feed back into the beam
      }
      if (goldRefine) {
        const exact = (await evaluate(index, [goldRefine], { abortStuckFrames: NO_ABORT, maxFrames: 4000 }))[0];
        if (exact?.success && exact.numKicks <= gold) {
          log(`gold @ depth ${depth} via refine (numKicks=${exact.numKicks}, ${trials} trials)`);
          return mkRoute('gold', goldRefine, exact, gold);
        }
      }
    }

    beam = topKDistinct(nodes, beamWidth).map((n) => n.kicks);
    log(`depth ${depth}: ${candidates.length} cands, best score=${nodes.length ? scoreOf(nodes[0].res).toFixed(0) : 'n/a'}, trials=${trials}`);
    if (beam.length === 0) break;
  }

  if (best !== null) {
    const b: { route: RouteKick[]; res: RunResult } = best;
    const exact = (await evaluate(index, [b.route], { abortStuckFrames: NO_ABORT, maxFrames: 4000 }))[0];
    if (exact?.success) {
      const status = exact.numKicks <= gold ? 'gold' : 'win';
      log(`fallback ${status}: numKicks=${exact.numKicks} (gold=${gold}), ${trials} trials`);
      return mkRoute(status, b.route, exact, gold);
    }
  }
  log(`unsolved after ${trials} trials`);
  return { status: 'unsolved', kicks: [], goldKicks: gold, note: 'no winning route found within budget' };
}
