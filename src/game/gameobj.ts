// Game entity, mirroring GameObj.as structure: position + state + dispatch
// to per-type update/render functions, optionally backed by a physics body.
import type { Atlas } from '../render/atlas';
import type { PhysWorld, PhysBody } from '../physics/world';
import type { LevelState } from './game-state';
import type { GameAudio } from '../audio/audio';

export interface GameContext {
  physics: PhysWorld;
  atlas: Atlas;
  level: LevelState;
  audio: GameAudio;
  objects: GameObjects;
  /** stage-space mouse + camera (set each frame by the scene) */
  mouseX: number;
  mouseY: number;
  cameraX: number;
  cameraY: number;
  bounds: { left: number; top: number; right: number; bottom: number };
  /** touch aim pad override: when set, the player aims by this instead of the mouse */
  aimOverride?: { dx: number; dy: number; power01: number } | null;
}

export type UpdateFn = (go: GameObj, g: GameContext) => void;
export type RenderFn = (go: GameObj, g: GameContext, ctx: CanvasRenderingContext2D) => void;
export type HitFn = (go: GameObj, hitter: GameObj, g: GameContext, sensor: boolean) => void;

export class GameObj {
  id = '';
  name = '';
  type = '';
  collisionType = 'normal';
  state = 0;
  xpos = 0;
  ypos = 0;
  zpos = 0;
  dir = 0; // degrees
  scale = 1;
  xflip = false;
  visible = true;
  dead = false;

  // graphics
  dobjName = '';
  frame = 0;
  frameVel = 0;

  // anim range playback (label-based, GameObj_Base.SetAnimRange)
  animStart = 0;
  animEnd = 0;
  animFrame = 0;

  // timers
  timer = 0;
  timerMax = 0;
  ballTimer = 0;
  stillTimer = 0;

  // tween targets (Football_MoveToPlayer)
  startx = 0;
  starty = 0;
  toPosX = 0;
  toPosY = 0;

  // physics
  body: PhysBody | null = null;
  /** when true the body is parked: transform written from xpos/ypos each frame */
  physicsStationary = false;

  params: Record<string, string> = {};

  updateFn: UpdateFn | null = null;
  renderFn: RenderFn | null = null;
  onHitFn: HitFn | null = null;

  // cross-object references (football <-> player etc.)
  refA: GameObj | null = null; // football: owning player / player: current ball
  refB: GameObj | null = null; // football: last player to have ball

  param(name: string, def = ''): string {
    const v = this.params[name];
    return v === undefined || v === '' ? def : v;
  }

  paramNum(name: string, def = 0): number {
    const v = Number(this.params[name]);
    return Number.isNaN(v) ? def : v;
  }
}

export class GameObjects {
  list: GameObj[] = [];
  private addList: GameObj[] = [];

  add(): GameObj {
    const go = new GameObj();
    this.addList.push(go);
    return go;
  }

  flushAdds(): void {
    this.list.push(...this.addList);
    this.addList = [];
  }

  removeDead(physics: PhysWorld): void {
    for (const go of this.list) {
      if (go.dead && go.body) {
        physics.destroyBody(go.body);
        go.body = null;
      }
    }
    this.list = this.list.filter((go) => !go.dead);
  }

  byName(name: string): GameObj | null {
    return this.list.find((go) => go.name === name && !go.dead) ?? null;
  }

  allByName(name: string): GameObj[] {
    return this.list.filter((go) => go.name === name && !go.dead);
  }

  nearestByName(name: string, x: number, y: number): GameObj | null {
    let best: GameObj | null = null;
    let bestD = Infinity;
    for (const go of this.list) {
      if (go.name !== name || go.dead) continue;
      const d = (go.xpos - x) ** 2 + (go.ypos - y) ** 2;
      if (d < bestD) {
        bestD = d;
        best = go;
      }
    }
    return best;
  }
}
