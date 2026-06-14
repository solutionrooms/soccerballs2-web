// Solvability tripwire: replay every recorded route in a FRESH worker process
// and assert it still wins within its recorded bar. Fresh-process isolation is
// required: nape.js's static pools retain history across worlds, so a route must
// be verified the way it's actually played — a clean load — not after a dozen
// other levels have been loaded in the same process.
//
// If a physics/level change breaks a route this fails loudly -> recreate that
// level's route (npx tsx tools/solve-routes.ts N). Unsolved levels are skipped.
import { describe, it, expect } from 'vitest';
import { LEVELS } from './headless';
import routesJson from '../../data/routes.json';
import type { RoutesFile } from './route-types';
import { verifyRoute } from '../../../tools/pool';

const routes = routesJson as unknown as RoutesFile;

describe('recorded routes keep levels solvable', () => {
  for (let i = 0; i < LEVELS.length; i++) {
    const def = LEVELS[i];
    const route = routes.levels[String(i)];
    const title = `level ${i + 1} "${def.name}"`;

    if (!route || route.status === 'unsolved' || route.kicks.length === 0) {
      it.skip(`${title} — no route (unsolved)`, () => {});
      continue;
    }

    it(
      `${title} — ${route.status} route still wins`,
      async () => {
        const res = await verifyRoute(i, route.kicks);
        expect(res?.success, `route no longer scores — recreate it (npx tsx tools/solve-routes.ts ${i})`).toBe(true);
        const bar = route.status === 'gold' ? def.goldKicks : def.failKicks;
        expect(res!.numKicks, `route now uses ${res!.numKicks} kicks, over the ${route.status} bar of ${bar}`).toBeLessThanOrEqual(bar);
      },
      30000,
    );
  }
});
