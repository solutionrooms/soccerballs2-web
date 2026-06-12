// Numeric helpers mirrored from Utils.as / Ease.as.

export function scaleTo(f0: number, f1: number, o0: number, o1: number, val: number): number {
  return ((f1 - f0) * (val - o0)) / (o1 - o0) + f0;
}

export function scaleToPreLimit(f0: number, f1: number, o0: number, o1: number, val: number): number {
  if (val < o0) val = o0;
  if (val > o1) val = o1;
  return scaleTo(f0, f1, o0, o1, val);
}

export function distBetween(x0: number, y0: number, x1: number, y1: number): number {
  return Math.hypot(x1 - x0, y1 - y0);
}

function powerIn(t: number, power = 2): number {
  return Math.pow(t, power);
}

function powerOut(t: number, power = 2): number {
  return 1 - Math.pow(1 - t, power);
}

export function easePowerInOut(t: number, power = 2): number {
  if (t < 0.5) return powerIn(t * 2, power) * 0.5;
  return 0.5 + powerOut((t - 0.5) * 2, power) * 0.5;
}
