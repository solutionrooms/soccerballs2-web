// Drives a recorded route by injecting the same aim + doKick a real player would.
// Used by both the headless test (runRoute) and the in-game visual replay, so what
// the test proves solvable is exactly what plays back on screen.
import { GameContext, GameObj } from '../gameobj';
import {
  ballReady,
  applyKick,
  stepWorld,
  levelWon,
  levelLost,
  ballGoalDistance,
  loadLevelHeadless,
} from './headless';
import type { RouteKick } from './route-types';

/**
 * Stateful per-frame driver. Call tick(g) once per frame BEFORE stepping the world.
 * It waits for the ball to be kickable, honours each kick's waitFrames, then commits
 * the kick — and won't fire the next one until the previous has actually launched and
 * the ball has returned to a player.
 */
export class RouteReplay {
  private k = 0;
  private waited = 0;
  private awaitingLaunch = false;

  constructor(private readonly kicks: RouteKick[]) {}

  tick(g: GameContext): void {
    const ball = g.objects.byName('football');
    // After committing a kick, wait until the ball actually leaves the foot (state 2)
    // before we consider the next one — during the kick animation the ball is still
    // "ready", which would otherwise double-fire.
    if (this.awaitingLaunch) {
      if (ball && ball.state === 2) this.awaitingLaunch = false;
      return;
    }
    if (this.k >= this.kicks.length) return;
    if (!ballReady(g)) {
      this.waited = 0;
      return;
    }
    const kick = this.kicks[this.k];
    if (this.waited >= kick.waitFrames) {
      applyKick(g, kick.angleDeg, kick.power01);
      this.k++;
      this.waited = 0;
      this.awaitingLaunch = true;
    } else {
      this.waited++;
    }
  }

  get kicksIssued(): number {
    return this.k;
  }

  /** Every kick has been committed, launched, and the ball has settled again. */
  allDone(g: GameContext): boolean {
    return this.k >= this.kicks.length && !this.awaitingLaunch && ballReady(g);
  }
}

export interface RunResult {
  success: boolean;
  failed: boolean;
  /** kicks counted by the game (numKicks) at the end. */
  numKicks: number;
  /** route kicks actually committed. */
  kicksIssued: number;
  /** closest the ball got to a goal sensor across the whole run (heuristic). */
  minGoalDist: number;
  numGoalsScored: number;
  numRefsHit: number;
  totalGoals: number;
  totalRefs: number;
  /** non-ball/player objects that changed state or were removed (switches hit,
   *  gates/blocks opened, crates broken) — a generic "made progress" signal so
   *  the solver values activating switches that unlock the path to the goal. */
  worldChanges: number;
  ballX: number;
  ballY: number;
  frames: number;
}

/**
 * Load a level fresh, replay the route headless, and report the outcome + telemetry.
 * Deterministic: same kicks -> same result. This is the single source of truth used
 * by the solver to score candidates and by the test to assert solvability.
 */
export function runRoute(
  index: number,
  kicks: RouteKick[],
  opts?: { maxFrames?: number; abortStuckFrames?: number },
): RunResult {
  const maxFrames = opts?.maxFrames ?? 4000;
  // Solver speed-up: bail when the ball has been un-kickable (in flight / lost)
  // for this many consecutive frames. A connecting kick returns the ball to a
  // player well within this window; a kick that's left the ball stranded is a
  // dead branch. Default Infinity = exact (the regression test never aborts).
  const abortStuck = opts?.abortStuckFrames ?? Infinity;
  const { g } = loadLevelHeadless(index);
  // snapshot non-ball/player objects to detect switches/gates changing later
  const baseline = g.objects.list
    .filter((o) => o.name !== 'football' && o.name !== 'player')
    .map((o) => ({ o, state: o.state }));
  const replay = new RouteReplay(kicks);
  let minGoalDist = ballGoalDistance(g);
  let frames = 0;
  let notReadyStreak = 0;

  for (; frames < maxFrames; frames++) {
    replay.tick(g);
    stepWorld(g);
    const d = ballGoalDistance(g);
    if (d < minGoalDist) minGoalDist = d;
    if (levelWon(g)) return result(g, true, false, replay, minGoalDist, baseline, frames + 1);
    if (levelLost(g)) return result(g, false, true, replay, minGoalDist, baseline, frames + 1);
    if (replay.allDone(g)) {
      frames += 1;
      break;
    }
    notReadyStreak = ballReady(g) ? 0 : notReadyStreak + 1;
    if (notReadyStreak >= abortStuck) break;
  }
  return result(g, levelWon(g), levelLost(g), replay, minGoalDist, baseline, frames);
}

function result(
  g: GameContext,
  success: boolean,
  failed: boolean,
  replay: RouteReplay,
  minGoalDist: number,
  baseline: { o: GameObj; state: number }[],
  frames: number,
): RunResult {
  const ball = g.objects.byName('football');
  let worldChanges = 0;
  for (const b of baseline) if (b.o.dead || b.o.state !== b.state) worldChanges++;
  return {
    success,
    failed,
    numKicks: g.level.numKicks,
    kicksIssued: replay.kicksIssued,
    minGoalDist,
    numGoalsScored: g.level.numGoalsScored,
    numRefsHit: g.level.numRefsHit,
    totalGoals: g.level.totalGoals,
    totalRefs: g.level.totalRefs,
    worldChanges,
    ballX: ball?.xpos ?? 0,
    ballY: ball?.ypos ?? 0,
    frames,
  };
}
