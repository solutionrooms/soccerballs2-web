// Solvability tripwire: replay every recorded route headless and assert it still
// wins within its recorded bar. If a physics/level change breaks a route this
// fails loudly -> recreate that level's route (npx tsx tools/solve-routes.ts N).
// Unsolved levels (no route found) are reported as skipped, not failures.
import '../nape-test-setup';
import { describe, it, expect } from 'vitest';
import { runRoute } from './replay';
import { LEVELS } from './headless';
import routesJson from '../../data/routes.json';
import type { RoutesFile } from './route-types';

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

    it(`${title} — ${route.status} route still wins`, () => {
      const res = runRoute(i, route.kicks);
      expect(res.success, `route no longer scores — recreate it (npx tsx tools/solve-routes.ts ${i})`).toBe(true);
      const bar = route.status === 'gold' ? def.goldKicks : def.failKicks;
      expect(res.numKicks, `route now uses ${res.numKicks} kicks, over the ${route.status} bar of ${bar}`).toBeLessThanOrEqual(bar);
    });
  }
});
