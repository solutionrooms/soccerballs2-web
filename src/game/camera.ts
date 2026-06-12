// Camera mirroring Game.UpdateScroll (desktop controlMode 0):
// aiming biases toward the mouse, otherwise follows the ball; smoothed at
// c=0.1 (snap on first frame), clamped to the level scroll bounds.
import { STAGE_W, STAGE_H } from './defs';
import type { GameObj } from './gameobj';

export class Camera {
  x = 0;
  y = 0;
  private firstTime = true;

  reset(): void {
    this.firstTime = true;
  }

  update(
    ball: GameObj | null,
    mouseX: number,
    mouseY: number,
    bounds: { left: number; top: number; right: number; bottom: number },
  ): void {
    if (!ball) return;
    const c = this.firstTime ? 1 : 0.1;
    this.firstTime = false;
    const w2 = STAGE_W / 2;
    const h2 = STAGE_H / 2;

    if (ball.state === 1) {
      const tox = (mouseX - w2) * 0.5 + ball.xpos - w2;
      const toy = (mouseY - h2) * 0.5 + ball.ypos - h2;
      this.x += (tox - this.x) * c;
      this.y += (toy - this.y) * c;
    } else {
      this.x += (ball.xpos - w2 - this.x) * c;
      this.y += (ball.ypos - h2 - this.y) * c;
    }

    if (this.x < bounds.left) this.x = bounds.left;
    if (this.y < bounds.top) this.y = bounds.top;
    if (this.x + STAGE_W > bounds.right) this.x = bounds.right - STAGE_W;
    if (this.y + STAGE_H > bounds.bottom) this.y = bounds.bottom - STAGE_H;
  }
}
