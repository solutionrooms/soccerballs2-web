// A recorded solution route for a level: an ordered list of kicks. Each kick is
// the player's drag expressed as angle + power, plus the timing (how long to wait
// after the ball becomes kickable before committing — matters for moving platforms
// / switches). This is exactly what the user sees as "angle, speed, timing".

export interface RouteKick {
  /** screen-space kick angle in degrees (0 = right, 90 = down). */
  angleDeg: number;
  /** drag strength 0..1 -> impulse kick_power0..kick_power1 (80..200). */
  power01: number;
  /** frames to wait after the ball is ready before kicking (timing; usually 0). */
  waitFrames: number;
}

export type RouteStatus = 'gold' | 'win' | 'unsolved';

export interface LevelRoute {
  status: RouteStatus;
  kicks: RouteKick[];
  /** kicks actually used when the route was found (<= goldKicks for 'gold'). */
  numKicks?: number;
  /** the gold bar at solve time, for reference. */
  goldKicks?: number;
  /** human note (e.g. why unsolved, or "hand-authored"). */
  note?: string;
}

export interface RoutesFile {
  version: number;
  /** ISO timestamp the routes were generated (stamped by the solver runner). */
  generated?: string;
  /** keyed by 0-based level index. */
  levels: Record<string, LevelRoute>;
}
