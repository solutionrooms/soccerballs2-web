// Per-level gameplay counters, mirroring the GameVars.as statics the level
// loop reads/writes.
import type { RigPartOverride } from './rig';

export class LevelState {
  /** kit tints for the player team / opponent team (set by the scene) */
  playerKit: RigPartOverride | null = null;
  opponentKit: RigPartOverride | null = null;

  numKicks = 0;
  maxKicks = 3; // failKicks from level data
  goldKicks = 1;
  numGoalsScored = 0;
  totalGoals = 0;
  numRefsHit = 0;
  totalRefs = 0;
  totalLevelCoins = 0;
  coinsCollectedThisLevel = 0;
  score = 0;
  levelTimer = 0;

  // ball timers (GameVars.as:55-56, in frames)
  readonly ballTimerShowTimerMax = 4 * 60;
  readonly ballTimerMax = 6 * 60;

  /** coin indices already collected in earlier runs (render small, inert) */
  collectedCoinIndices = new Set<number>();
  /** coin indices collected during this run */
  coinsThisRun: number[] = [];
  trophyCollectedThisRun = false;

  doKick = false;
  success = false;
  phase: 'start' | 'play' | 'complete' | 'end' = 'start';
  phaseTimer = 0;

  addScore(points: number): void {
    this.score += points;
  }
}
