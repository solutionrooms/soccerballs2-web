// Diagnostic: for one level, sweep single kicks and report, for EACH win
// objective (goal/ref), the best single-kick angle to approach it and whether
// it's hit. This gives a full seed plan (one shot toward each objective) for the
// seeded solver to chain + fine-tune.
import '../src/game/nape-test-setup';
import { loadLevelHeadless, stepWorld, applyKick, ballReady } from '../src/game/sim/headless';
import { GameObj } from '../src/game/gameobj';
import { LEVELS } from '../src/game/level-loader';

const index = Number(process.argv[2] ?? 1);

interface Obj { kind: string; id: number; best: number; ang: number; pow: number; hit: boolean }
const objs = new Map<string, Obj>();

const { g: g0 } = loadLevelHeadless(index);
for (const kind of ['goal', 'ref']) for (let k = 0; k < g0.objects.allByName(kind).length; k++) objs.set(`${kind}${k}`, { kind, id: k, best: Infinity, ang: 0, pow: 0, hit: false });

for (let ang = 0; ang < 360; ang += 10) {
  for (let p = 0; p <= 1.0001; p += 0.2) {
    const { g } = loadLevelHeadless(index);
    applyKick(g, ang, Math.min(1, p));
    let launched = false;
    for (let f = 0; f < 500; f++) {
      stepWorld(g);
      const ball = g.objects.byName('football')!;
      if (ball.state === 2) launched = true;
      for (const kind of ['goal', 'ref']) {
        const arr = g.objects.allByName(kind);
        for (let k = 0; k < arr.length; k++) {
          const o = arr[k] as GameObj;
          const rec = objs.get(`${kind}${k}`);
          if (!rec) continue;
          if (o.state === 0) {
            const d = Math.hypot(o.xpos - ball.xpos, o.ypos - ball.ypos);
            if (d < rec.best) { rec.best = d; rec.ang = ang; rec.pow = p; }
          } else {
            rec.hit = true;
          }
        }
      }
      if (launched && ballReady(g)) break;
    }
  }
}

const def = LEVELS[index];
console.log(`[${index}] "${def.name}" gold=${def.goldKicks} fail=${def.failKicks}`);
const seed: { angleDeg: number; aSpan: number }[] = [];
for (const o of objs.values()) {
  console.log(`  ${o.kind}${o.id}: best ${o.best.toFixed(0)}px @ ${o.ang}deg/${o.pow.toFixed(1)} hit=${o.hit}`);
  seed.push({ angleDeg: o.ang, aSpan: 40 });
}
// emit a ready-to-paste seed plan (one shot per objective, ordered ref-ish then goals)
console.log(`  SEED ${index}: ${JSON.stringify({ kicks: seed })}`);
