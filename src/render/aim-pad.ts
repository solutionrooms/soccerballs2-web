// On-screen aiming pad for touch play. Lives in a screen-space corner (in the
// letterbox, away from the play field) so the finger never covers the ball.
// The pad ONLY aims — it sets direction + power and the aim persists. Kicking
// is a separate tap on the field/player, so releasing the pad never fires a
// stray kick.
import type { Renderer } from './renderer';
import type { InputManager } from '../core/input';

export interface AimVector {
  dx: number; // unit direction, world axes (y down)
  dy: number;
  power01: number; // 0..1 of pad radius -> kick power
}

export class AimPad {
  private cx = 0;
  private cy = 0;
  private radius = 70;
  private knobX = 0;
  private knobY = 0;
  /** a pad drag is currently in progress */
  private grabbing = false;

  private layout(r: Renderer): void {
    this.radius = Math.max(48, Math.min(r.height * 0.16, 92));
    const margin = this.radius * 0.55;
    this.cx = r.width - margin - this.radius;
    this.cy = r.height - margin - this.radius;
  }

  /** is the pointer within the pad's grab area? */
  contains(input: InputManager, r: Renderer): boolean {
    this.layout(r);
    const dx = input.screenX - this.cx;
    const dy = input.screenY - this.cy;
    return dx * dx + dy * dy <= (this.radius * 1.35) ** 2;
  }

  /** Update the knob while the pad is being dragged. Never fires a kick. */
  update(input: InputManager, r: Renderer, enabled: boolean): void {
    this.layout(r);
    const dx = input.screenX - this.cx;
    const dy = input.screenY - this.cy;
    if (!this.grabbing && enabled && input.buttonPressed && this.contains(input, r)) {
      this.grabbing = true;
    }
    if (this.grabbing && input.buttonDown) {
      const d = Math.hypot(dx, dy);
      const k = d > this.radius ? this.radius / d : 1;
      this.knobX = dx * k;
      this.knobY = dy * k;
    }
    if (this.grabbing && input.buttonReleased) {
      this.grabbing = false; // knob persists — the aim stays set
    }
  }

  /** the player has set a meaningful aim */
  get hasAim(): boolean {
    return Math.hypot(this.knobX, this.knobY) > this.radius * 0.12;
  }

  get aiming(): boolean {
    return this.grabbing;
  }

  get vector(): AimVector {
    const d = Math.hypot(this.knobX, this.knobY);
    if (d < 1) return { dx: 0, dy: 0, power01: 0 };
    return { dx: this.knobX / d, dy: this.knobY / d, power01: Math.min(1, d / this.radius) };
  }

  reset(): void {
    this.grabbing = false;
    this.knobX = 0;
    this.knobY = 0;
  }

  /** Draw in screen space (after the world/HUD, outside the stage clip). */
  render(ctx: CanvasRenderingContext2D): void {
    ctx.save();
    ctx.globalAlpha = this.grabbing ? 0.9 : 0.55;
    ctx.beginPath();
    ctx.arc(this.cx, this.cy, this.radius, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0,0,0,0.35)';
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = 'rgba(255,255,255,0.6)';
    ctx.stroke();
    const kx = this.cx + this.knobX;
    const ky = this.cy + this.knobY;
    if (this.knobX || this.knobY) {
      ctx.beginPath();
      ctx.moveTo(this.cx, this.cy);
      ctx.lineTo(kx, ky);
      ctx.strokeStyle = 'rgba(247,245,70,0.9)';
      ctx.lineWidth = 4;
      ctx.stroke();
    }
    ctx.beginPath();
    ctx.arc(kx, ky, this.radius * 0.32, 0, Math.PI * 2);
    ctx.fillStyle = this.hasAim ? 'rgba(247,245,70,0.95)' : 'rgba(255,255,255,0.55)';
    ctx.fill();
    // hint label
    ctx.globalAlpha = 0.8;
    ctx.fillStyle = '#fff';
    ctx.font = `${Math.round(this.radius * 0.22)}px sans-serif`;
    ctx.textAlign = 'center';
    ctx.fillText('AIM', this.cx, this.cy - this.radius - 6);
    ctx.restore();
  }
}
