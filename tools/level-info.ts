// Print ground-truth planning info for a level: where the ball starts, where the
// win objectives are (goals/refs), and key obstacles — all in GAME coords (the
// same frame seed angles use: 0=right, 90=down, 180=left, 270=up). Also prints
// the bearing from the ball to each objective as a starting seed angle.
//   npx tsx tools/level-info.ts 1 2 3
import '../src/game/nape-test-setup';
import { loadLevelHeadless } from '../src/game/sim/headless';
import { LEVELS } from '../src/game/level-loader';

function bearing(fromX: number, fromY: number, toX: number, toY: number): number {
  const d = (Math.atan2(toY - fromY, toX - fromX) * 180) / Math.PI;
  return Math.round(((d % 360) + 360) % 360);
}

for (const arg of process.argv.slice(2)) {
  const i = Number(arg);
  const { g, loaded } = loadLevelHeadless(i);
  const ball = g.objects.byName('football');
  const bx = ball?.xpos ?? 0;
  const by = ball?.ypos ?? 0;
  console.log(`\n=== [${i}] "${LEVELS[i].name}" gold=${LEVELS[i].goldKicks} fail=${LEVELS[i].failKicks} ===`);
  console.log(`ball start: (${bx.toFixed(0)}, ${by.toFixed(0)})  collisionType=${ball?.collisionType}`);
  const list = (name: string): void => {
    for (const o of g.objects.allByName(name)) {
      console.log(`  ${name} (${o.xpos.toFixed(0)}, ${o.ypos.toFixed(0)})  bearing-from-ball=${bearing(bx, by, o.xpos, o.ypos)}°  dist=${Math.hypot(o.xpos - bx, o.ypos - by).toFixed(0)}`);
    }
  };
  list('goal');
  list('ref');
  list('player');
  // obstacles / mechanism objects of interest
  for (const o of g.objects.list) {
    if (/cannon|switch|magnet|worm|conveyor|post|block|crate|bird|keeper|opponent/i.test(o.name) && o.name !== 'football') {
      console.log(`  ~${o.name} (${o.xpos.toFixed(0)}, ${o.ypos.toFixed(0)})  bearing=${bearing(bx, by, o.xpos, o.ypos)}°`);
    }
  }
  const b = loaded.scrollBounds;
  console.log(`  bounds x[${b.left.toFixed(0)}..${b.right.toFixed(0)}] y[${b.top.toFixed(0)}..${b.bottom.toFixed(0)}]`);
}
