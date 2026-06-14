// Shared worker-process pool for the route solvers. A fresh Nape world leaks, so
// each chunk runs in a short-lived process (tools/solve-chunk.ts) recycled after
// ~150 trials; this fans a batch of candidate routes across the cores.
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import os from 'node:os';
import type { BatchEvaluator, EvalOpts } from '../src/game/sim/solver';
import type { RouteKick } from '../src/game/sim/route-types';
import type { RunResult } from '../src/game/sim/replay';

const CHUNK_WORKER = fileURLToPath(new URL('./solve-chunk.ts', import.meta.url));

function runChunk(index: number, routes: RouteKick[][], opts: EvalOpts): Promise<RunResult[]> {
  return new Promise((resolve, reject) => {
    const child = spawn('node', ['--import', 'tsx', CHUNK_WORKER], { stdio: ['pipe', 'pipe', 'inherit'] });
    let out = '';
    child.stdout.setEncoding('utf8');
    child.stdout.on('data', (d) => (out += d));
    child.on('error', reject);
    child.on('close', (code) => {
      if (code !== 0) return reject(new Error(`chunk worker exited ${code}`));
      try {
        resolve(JSON.parse(out) as RunResult[]);
      } catch (e) {
        reject(new Error(`bad chunk output: ${(e as Error).message}`));
      }
    });
    child.stdin.write(JSON.stringify({ index, routes, opts }));
    child.stdin.end();
  });
}

export function makeEvaluator(
  concurrency = Math.max(1, os.cpus().length - 1),
  chunk = 150,
): BatchEvaluator {
  return async (index, routes, opts) => {
    const chunks: RouteKick[][][] = [];
    for (let i = 0; i < routes.length; i += chunk) chunks.push(routes.slice(i, i + chunk));
    const results: RunResult[][] = new Array(chunks.length);
    let next = 0;
    const worker = async (): Promise<void> => {
      for (;;) {
        const my = next++;
        if (my >= chunks.length) return;
        results[my] = await runChunk(index, chunks[my], opts);
      }
    };
    await Promise.all(Array.from({ length: Math.min(concurrency, chunks.length) }, () => worker()));
    return results.flat();
  };
}
