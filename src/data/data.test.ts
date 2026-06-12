// Sanity checks that the extraction pipeline produced coherent data.
import { describe, it, expect } from 'vitest';
import atlas from './atlas.json';
import objects from './objects.json';
import levels from './levels.json';
import rigs from './rigs.json';
import labels from './labels.json';
import vars from './vars.json';

describe('atlas', () => {
  it('has the bitmap font with the ASCII range', () => {
    const font = atlas.objects['font1'];
    expect(font).toBeDefined();
    expect(font.frames.length).toBeGreaterThanOrEqual(127);
  });
  it('has core gameplay sprites', () => {
    for (const name of ['football', 'goalposts', 'Pickups', 'player_head', 'ref_head', 'backgrounds']) {
      expect(atlas.objects[name as keyof typeof atlas.objects], name).toBeDefined();
    }
  });
});

describe('objects', () => {
  it('has the football material with original constants', () => {
    const m = objects.materials['football'];
    expect(m).toEqual({
      density: 0.5,
      frictionStatic: 0.1,
      frictionDynamic: 0.1,
      frictionRolling: 0.1,
      elasticity: 1,
    });
  });
  it('has ball_normal physobj with a circle shape', () => {
    const ball = objects.physobjs['ball_normal'];
    expect(ball).toBeDefined();
    expect(ball.bodies[0].shapes[0].type).toBe('circle');
  });
  it('has all 14 game layers', () => {
    expect(Object.keys(objects.gamelayers)).toHaveLength(14);
    expect(objects.gamelayers['Centre']).toBe(0);
    expect(objects.gamelayers['Far_Background']).toBe(2000);
  });
});

describe('levels', () => {
  it('has 36 levels, 935 coins, 10 trophies (GameVars totals)', () => {
    expect(levels.levels).toHaveLength(36);
    const coins = levels.levels.reduce((s, l) => s + l.totalCoins, 0);
    expect(coins).toBe(935);
    expect(levels.levels.filter((l) => l.trophyIndex > 0)).toHaveLength(10);
  });
  it('level 1 matches the XML (Intro 1, gold 2, fail 6)', () => {
    const l1 = levels.levels[0];
    expect(l1.name).toBe('Intro 1');
    expect(l1.goldKicks).toBe(2);
    expect(l1.failKicks).toBe(6);
    const types = l1.instances.map((i) => i.type);
    for (const t of ['player', 'referee', 'goal2', 'ball_normal', 'pickup_trophy_1']) {
      expect(types).toContain(t);
    }
  });
  it('every instance type resolves to a physobj def', () => {
    for (const l of levels.levels) {
      for (const inst of l.instances) {
        expect(objects.physobjs[inst.type as keyof typeof objects.physobjs], `${l.id}:${inst.type}`).toBeDefined();
      }
    }
  });
  it('every line material resolves to a polymat', () => {
    for (const l of levels.levels) {
      for (const line of l.lines) {
        const mat = line.params['line_material'];
        expect(objects.polymats[mat as keyof typeof objects.polymats], `${l.id}:${mat}`).toBeDefined();
      }
    }
  });
});

describe('rigs + labels', () => {
  it('rig frame counts match the SWF timelines', () => {
    expect(rigs.player).toHaveLength(335);
    expect(rigs.ref).toHaveLength(107);
    expect(rigs.keeper).toHaveLength(163);
  });
  it('player parts reference atlas clips', () => {
    for (const part of rigs.player[0]) {
      expect(atlas.objects[part.clip as keyof typeof atlas.objects], part.clip).toBeDefined();
    }
  });
  it('kick anims have release_ball labels', () => {
    const playerLabels = labels.player.map((l) => l.label);
    expect(playerLabels.filter((l) => l === 'release_ball')).toHaveLength(3); // kick1/2/3
    expect(playerLabels).toContain('kick3');
    expect(labels.keeper.map((l) => l.label)).toContain('air');
  });
});

describe('vars', () => {
  it('has the original balance constants', () => {
    expect(vars.gravity).toBe(1000);
    expect(vars.kick_power0).toBe(80);
    expect(vars.kick_power1).toBe(200);
    expect(vars.kick_dist0).toBe(150);
    expect(vars.kick_dist1).toBe(300);
    expect(vars.cannonLaunchForce).toBe(1000);
  });
});
