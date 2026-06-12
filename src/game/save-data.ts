// Persistent progress, mirroring SaveData.as / Levels.ToSharedObject
// (SharedObject "soccerballs2_9988" -> one localStorage JSON blob).
import { loadJson, saveJson, removeKey } from '../core/storage';
import { LEVELS } from './level-loader';
import { DEFAULT_TEAMS, TeamDef } from './kits';

export interface LevelProgress {
  available: boolean;
  complete: boolean;
  rating: number; // 0 = none, 1 = gold star
  bestScore: number;
  bestShots: number;
}

export interface SaveData {
  levels: LevelProgress[];
  playerTeam: number;
  opponentTeam: number;
  /** team 9 "design your own" edits (GameVars.ToSharedObject persists teams) */
  customTeam: TeamDef;
  /** coin indices collected per level (coins stay collected forever) */
  coins: Record<string, number[]>;
  trophies: number[]; // trophy indices 1..10
  totalScore: number;
}

const KEY = 'soccerballs2.save';

export function newSave(): SaveData {
  const levels: LevelProgress[] = LEVELS.map((_, i) => ({
    available: i === 0, // level 1 starts unlocked
    complete: false,
    rating: 0,
    bestScore: 0,
    bestShots: 0,
  }));
  return {
    levels,
    coins: {},
    trophies: [],
    totalScore: 0,
    playerTeam: 0,
    opponentTeam: 5,
    customTeam: { ...DEFAULT_TEAMS[8] },
  };
}

export function loadSave(): SaveData {
  const raw = loadJson<SaveData>(KEY);
  if (!raw || !Array.isArray(raw.levels) || raw.levels.length !== LEVELS.length) {
    return newSave();
  }
  return { ...newSave(), ...raw };
}

export function saveSave(s: SaveData): void {
  saveJson(KEY, s);
}

export function clearSave(): void {
  removeKey(KEY);
}

export function coinsCollectedTotal(s: SaveData): number {
  return Object.values(s.coins).reduce((sum, arr) => sum + arr.length, 0);
}

export function goldLevelCount(s: SaveData): number {
  return s.levels.filter((l) => l.complete && l.rating > 0).length;
}
