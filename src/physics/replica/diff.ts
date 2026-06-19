// Bit-exact differential testing primitives shared by every milestone gate.
//
// "100% accurate at the function level" means *bit-identical* doubles, not
// epsilon-close. So comparisons use Object.is, which (unlike ===) treats
// NaN===NaN as equal and -0===0 as NOT equal — exactly IEEE-754 bit identity
// for the doubles JS produces. f64hex renders the raw 8 bytes so a divergence
// report shows the actual bit pattern, not a rounded decimal.

/** Raw IEEE-754 bytes of a double, big-endian, as a 0x… hex string. */
export function f64hex(x: number): string {
  const buf = new ArrayBuffer(8);
  const dv = new DataView(buf);
  dv.setFloat64(0, x);
  let s = '';
  for (let i = 0; i < 8; i++) s += dv.getUint8(i).toString(16).padStart(2, '0');
  return '0x' + s;
}

/** True iff a and b are the identical double (bit-for-bit). */
export function bitEq(a: number, b: number): boolean {
  return Object.is(a, b);
}

/** A handle-based world exposing the readouts the harness diffs each step. */
export interface NapeLike {
  setGravity(gpxY: number): void;
  createBody(isStatic: boolean, x: number, y: number, rotDeg: number, linDamp: number, angDamp: number): number;
  addCircle(h: number, posX: number, posY: number, radius: number, density: number, friction: number, rolling: number, elasticity: number, colCat: number, colMask: number, isSensor: boolean): void;
  finalizeBody(h: number, bullet: boolean): void;
  step(dt: number, velIters: number, posIters: number): void;
  getX(h: number): number;
  getY(h: number): number;
  getRot(h: number): number;
  getVX(h: number): number;
  getVY(h: number): number;
  getAngVel(h: number): number;
  getMass(h: number): number;
}

/** The per-body fields compared after every step. */
export const STATE_FIELDS = ['getX', 'getY', 'getRot', 'getVX', 'getVY', 'getAngVel'] as const;
export type StateField = (typeof STATE_FIELDS)[number];

export interface Divergence {
  step: number;
  handle: number;
  field: StateField;
  oracle: number;
  replica: number;
}

/**
 * Step `oracle` and `replica` in lockstep for `steps` frames and return the
 * FIRST per-body state divergence (or null if they stay bit-identical the whole
 * way). First divergence is what matters: in a chaotic system any mismatch
 * compounds, so the earliest one localizes the bug; later diffs are noise.
 */
export function runLockstep(
  oracle: NapeLike,
  replica: NapeLike,
  handles: number[],
  steps: number,
  dt: number,
  velIters: number,
  posIters: number,
): Divergence | null {
  for (let s = 1; s <= steps; s++) {
    oracle.step(dt, velIters, posIters);
    replica.step(dt, velIters, posIters);
    for (const h of handles) {
      for (const field of STATE_FIELDS) {
        const o = oracle[field](h);
        const r = replica[field](h);
        if (!bitEq(o, r)) return { step: s, handle: h, field, oracle: o, replica: r };
      }
    }
  }
  return null;
}

/** Human-readable one-liner for a divergence, including raw bit patterns. */
export function describeDivergence(d: Divergence): string {
  return (
    `step ${d.step} body#${d.handle} ${d.field}: ` +
    `oracle=${d.oracle} (${f64hex(d.oracle)}) ` +
    `replica=${d.replica} (${f64hex(d.replica)})`
  );
}
