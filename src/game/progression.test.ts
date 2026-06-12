import { describe, it, expect } from 'vitest';
import { unlockedBy, returnsToMap, scoreMultiplier } from './progression';
import { newSave, coinsCollectedTotal, goldLevelCount } from './save-data';

describe('progression', () => {
  it('unlock chain matches GameVars.unlockList (clipped to 36 levels)', () => {
    expect(unlockedBy(1)).toEqual([2]);
    expect(unlockedBy(4)).toEqual([5, 6]); // branch
    expect(unlockedBy(30)).toEqual([31, 34]); // branch
    expect(unlockedBy(36)).toEqual([]); // 37 is vestigial, clipped
  });
  it('back-to-map levels match GameVars list', () => {
    expect(returnsToMap(4)).toBe(true);
    expect(returnsToMap(9)).toBe(false);
    expect(returnsToMap(42)).toBe(true);
  });
  it('score multiplier doubles per feature', () => {
    expect(scoreMultiplier({ coinsCollected: 0, totalCoins: 935, trophies: 0, goldLevels: 0 })).toBe(1);
    expect(scoreMultiplier({ coinsCollected: 60, totalCoins: 935, trophies: 0, goldLevels: 0 })).toBe(2);
    expect(scoreMultiplier({ coinsCollected: 935, totalCoins: 935, trophies: 10, goldLevels: 36 })).toBe(16);
  });
  it('fresh save: only level 1 unlocked', () => {
    const s = newSave();
    expect(s.levels[0].available).toBe(true);
    expect(s.levels.slice(1).every((l) => !l.available)).toBe(true);
    expect(coinsCollectedTotal(s)).toBe(0);
    expect(goldLevelCount(s)).toBe(0);
  });
});
