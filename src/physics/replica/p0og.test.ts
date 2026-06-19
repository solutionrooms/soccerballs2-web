// Gate — ONGOING contact events vs ORIGINAL Nape AS3. Golden from harness-p0og.as: a dynamic
// block falls onto a static floor with BEGIN + ONGOING collision listeners registered. The
// replica previously emitted BEGIN only, so the game's `onHitPersistFunction` (level-8
// switch_weight timer reset, wind `OnHit_Wind`) never fired. Nape dispatches ONGOING every
// step a pair persists while AWAKE, and skips it once all the interaction's arbiters sleep
// (ZPP_Space.as:1903-1919). The shipped SWF shows: BEGIN@15, ONGOING 15..76 contiguous (incl.
// the begin step), block sleeps @77 → ONGOING stops exactly there. We assert the replica's
// takeOngoing()/takeContacts() reproduce that exact step pattern. Centered boxes → no trig.
import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { NapeReplica } from './nape-core';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/p0og.json', import.meta.url)), 'utf8'),
).lines;

// expected firing steps, parsed straight from the golden (a real differential check)
const beginGold = new Set<number>();
const ongoingGold = new Set<number>();
let sleepStepGold = Infinity;
for (const l of lines) {
  let m: RegExpMatchArray | null;
  if ((m = l.match(/\[P0OG\] BEGIN (\d+)/))) beginGold.add(Number(m[1]));
  else if ((m = l.match(/\[P0OG\] ONGOING (\d+)/))) ongoingGold.add(Number(m[1]));
  else if ((m = l.match(/\[P0OG\] STEP (\d+) sleeping=1/))) sleepStepGold = Math.min(sleepStepGold, Number(m[1]));
}

const MAT = [1.0, 0.5, 0.1, 0.0, 1, 0xffff, false] as const; // density,friction,rolling,elasticity,group,mask,sensor

describe('ONGOING contact events (drives onHitPersistFunction) vs ORIGINAL Nape AS3', () => {
  it('takeOngoing fires every awake step a contact persists and stops on sleep — matching the SWF step-for-step', () => {
    const w = new NapeReplica(1000);
    const floor = w.createBody(true, 200, 400, 0, 0, 0);
    w.addPolygon(floor, [-150, -20, 150, -20, 150, 20, -150, 20], ...MAT);
    w.finalizeBody(floor, false);
    const block = w.createBody(false, 200, 330, 0, 0, 0);
    w.addPolygon(block, [-20, -20, 20, -20, 20, 20, -20, 20], ...MAT);
    w.finalizeBody(block, false);

    const beginGot = new Set<number>();
    const ongoingGot = new Set<number>();
    for (let i = 1; i <= 130; i++) {
      w.step(1 / 60, 10, 10);
      const begun = w.takeContacts(); // [hA,hB,flag,...]
      const ongoing = w.takeOngoing();
      // exactly one pair in this scene (block↔floor, solid → flag 0)
      if (begun.length > 0) {
        expect(begun.length, `step ${i} one begin triple`).toBe(3);
        expect(begun[2], `step ${i} begin is solid`).toBe(0);
        beginGot.add(i);
      }
      if (ongoing.length > 0) {
        expect(ongoing.length, `step ${i} one ongoing triple`).toBe(3);
        expect(ongoing[2], `step ${i} ongoing is solid`).toBe(0);
        // the pair is the block↔floor handles, in either internal order
        expect(new Set([ongoing[0], ongoing[1]]), `step ${i} ongoing pair`).toEqual(new Set([floor, block]));
        ongoingGot.add(i);
      }
    }

    // sanity on the golden itself: ONGOING covers BEGIN..(sleep-1), contiguously
    expect(beginGold).toEqual(new Set([15]));
    expect(Math.max(...ongoingGold)).toBe(sleepStepGold - 1);

    // the replica reproduces the SWF's exact begin + ongoing step sets
    expect([...beginGot].sort((a, b) => a - b)).toEqual([...beginGold].sort((a, b) => a - b));
    expect([...ongoingGot].sort((a, b) => a - b)).toEqual([...ongoingGold].sort((a, b) => a - b));
  });
});
