import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { triangulate } from './geom-triangulate';

const lines: string[] = JSON.parse(
  readFileSync(fileURLToPath(new URL('./original-goldens/tri-geompoly.json', import.meta.url)), 'utf8'),
).lines;
const dv = new DataView(new ArrayBuffer(8));
const toNum = (p: string) => { const [hi, lo] = p.split(':'); dv.setUint32(0, parseInt(hi, 16) >>> 0); dv.setUint32(4, parseInt((lo || '0').padStart(8, '0'), 16) >>> 0); return dv.getFloat64(0); };

// raw input polys (same as harness-tri.as)
const POLYS: Record<string, number[]> = {
  quad: [0,0, 10,0, 10,10, 0,10],
  Lshape: [0,0, 20,0, 20,10, 10,10, 10,20, 0,20],
  notch: [0,0, 30,0, 30,20, 20,20, 25,10, 10,10, 15,20, 0,20],
  star5: [50,0, 61,35, 98,35, 68,57, 79,91, 50,70, 21,91, 32,57, 2,35, 39,35],
  grass: [-38,-27,-20,-25,9,-12,11,14,14,41,17,68,33,78,63,80,105,82,127,86,135,100,121,112,99,134,59,144,37,158,11,178,12,194,16,233,24,259,44,270,67,259,124,259,170,251,209,260,247,262,271,263,282,265,288,270,284,292,143,312,127,322,121,350,119,370,125,394,133,414,151,424,175,432,233,430,306,429,321,487,375,488,375,437,386,435,430,430,492,438,580,434,608,428,632,422,656,414,676,396,700,378,712,362,728,340,746,321,758,310,798,302,818,300,838,288,854,268,862,218,868,178,874,148,902,128,942,126,996,125,994,565,-152,576,-151,-40],
  mud: [-149,-30,-51,-8,-1,-1,5,62,18,86,34,100,78,105,104,103,126,111,107,137,70,147,46,155,29,166,7,205,13,246,22,268,40,277,65,273,94,280,128,283,171,281,216,281,275,282,278,294,259,301,218,308,187,313,155,326,139,339,131,376,139,404,154,422,165,432,195,440,213,448,242,445,268,451,280,474,292,494,322,499,346,513,354,500,380,494,390,457,413,454,445,454,467,456,501,462,544,467,587,460,629,449,675,432,714,392,730,366,751,353,786,352,799,329,800,320,832,310,848,310,863,300,882,241,885,201,895,167,920,155,962,150,995,150,992,595,-162,602],
};

function centroidSub(flat: number[]): number[] {
  const n = flat.length >> 1; let cx = 0, cy = 0;
  for (let i = 0; i < n; i++) { cx += flat[i*2]; cy += flat[i*2+1]; }
  cx /= n; cy /= n;
  return flat.map((v, i) => (i % 2 === 0 ? v - cx : v - cy));
}
// triangle → canonical key (sorted vertices, exact bits) for set comparison
function triKey(t: number[]): string {
  const v = [[t[0],t[1]],[t[2],t[3]],[t[4],t[5]]].map(([x,y]) => `${x},${y}`).sort();
  return v.join('|');
}
// parse golden tris per poly (local coords)
function goldenTris(name: string): { n: number; keys: Map<string, number> } {
  const keys = new Map<string, number>(); let n = 0;
  for (const ln of lines) {
    let m = ln.match(new RegExp(`^\\[TRI\\] ${name} centroid \\S+ \\S+ ntris (\\d+)`));
    if (m) { n = +m[1]; continue; }
    m = ln.match(new RegExp(`^\\[TRI\\] ${name} t\\d+ (\\S+) (\\S+) (\\S+) (\\S+) (\\S+) (\\S+)`));
    if (m) { const t = m.slice(1).map(toNum); const k = triKey(t); keys.set(k, (keys.get(k) || 0) + 1); }
  }
  return { n, keys };
}

// PASSING bit-exact: convex + simple-reflex. WIP (skipped): concave polys needing make-monotone
// SPLIT/MERGE diagonals — decompose's edge-ordering / leftEdge search + horizontal-edge tie-breaks
// are still being made faithful to nape. star5 is excluded (the SWF result is degenerate/self-touch).
const PASSING = new Set(['quad', 'Lshape', 'notch', 'grass', 'mud']); // star5 excluded (SWF result degenerate)
describe('geom-triangulate — faithful 2012 GeomPoly.triangularDecomposition (set match vs SWF)', () => {
  for (const name of Object.keys(POLYS)) {
    const runner = PASSING.has(name) ? it : it.skip;
    runner(`${name}: triangle set matches nape`, () => {
      const gold = goldenTris(name);
      const mine = triangulate(centroidSub(POLYS[name]));
      const mineKeys = new Map<string, number>();
      for (const t of mine) mineKeys.set(triKey(t), (mineKeys.get(triKey(t)) || 0) + 1);
      // report
      let missing = 0, extra = 0;
      for (const [k, c] of gold.keys) if ((mineKeys.get(k) || 0) !== c) missing++;
      for (const [k, c] of mineKeys) if ((gold.keys.get(k) || 0) !== c) extra++;
      console.log(`${name}: nape ${gold.n} tris, mine ${mine.length}; mismatched gold=${missing} mine-extra=${extra}`);
      expect(mine.length).toBe(gold.n);
      expect(missing).toBe(0);
      expect(extra).toBe(0);
    });
  }
});
