// Level progression mirrored from GameVars.as: the unlock chain (1-based
// [completed, unlocks...] pairs, GameVars.as:123-180), the levels that return
// to the map on completion (GameVars.as:201-216), and the feature unlocks
// (GameVars.as:81-106).
import { LEVELS } from './level-loader';

// [levelId, ...unlockedLevelIds] — 1-based, entries above 36 are vestigial
const UNLOCK_LIST: number[][] = [
  [1, 2], [2, 3], [3, 4],
  [4, 5, 6], [5, 7], [7, 9],
  [6, 8],
  [8, 9], [9, 10], [10, 11], [11, 12], [12, 13], [13, 14],
  [14, 15, 16],
  [16, 17, 19], [17, 18],
  [19, 20], [20, 21], [21, 22], [22, 23], [23, 24],
  [24, 25, 27], [25, 26], [26, 29], [27, 28], [28, 29],
  [29, 30],
  [30, 31, 34], [31, 32], [32, 33],
  [34, 35], [35, 36], [36, 37], [37, 38], [38, 39],
  [39, 40, 43], [40, 41], [41, 42],
  [43, 44], [44, 45], [45, 46], [46, 47], [47, 48], [48, 49], [49, 50],
];

const DUMP_BACK_TO_MAP = new Set([
  4, 5, 6, 7, 8, 14, 15, 16, 17, 18, 24, 25, 26, 27, 28, 30, 31, 32, 33, 39, 40, 41, 42,
]);

/** levels unlocked by completing levelId (1-based, clipped to real levels) */
export function unlockedBy(levelId: number): number[] {
  const out: number[] = [];
  for (const entry of UNLOCK_LIST) {
    if (entry[0] === levelId) {
      for (const id of entry.slice(1)) {
        if (id >= 1 && id <= LEVELS.length) out.push(id);
      }
    }
  }
  return out;
}

export function returnsToMap(levelId: number): boolean {
  return DUMP_BACK_TO_MAP.has(levelId);
}

// GameVars.IsFeatureUnlocked (GameVars.as:81-106)
export interface FeatureState {
  coinsCollected: number;
  totalCoins: number;
  trophies: number;
  goldLevels: number;
}

export function isFeatureUnlocked(feature: number, s: FeatureState): boolean {
  switch (feature) {
    case 1:
      return s.coinsCollected >= 50;
    case 2:
      return s.coinsCollected >= s.totalCoins; // all 935
    case 3:
      return s.trophies >= 10;
    case 4:
      return s.goldLevels >= LEVELS.length; // gold on all 36
    default:
      return false;
  }
}

/** score multiplier: x2 per unlocked feature (Game.as:2079-2087) */
export function scoreMultiplier(s: FeatureState): number {
  let m = 1;
  for (let f = 1; f <= 4; f++) {
    if (isFeatureUnlocked(f, s)) m *= 2;
  }
  return m;
}
