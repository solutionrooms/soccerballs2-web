// On-screen aiming pad for touch play. Lives in a screen-space corner (in the
// letterbox, away from the play field) so the finger never covers the ball.
// Drag sets kick direction + power; lift fires. Mirrors the original mobile
// joystick aim (Game.controlMode 1) but relocated off the field.
import type { Renderer } from './renderer';
import type { InputManager } from '../core/input';

export interface AimVector {
  /** unit direction in world axes (y down), or 0,0 when centred */
  dx: number;
  dy: number;
  /** 0..1 of the pad radius — drives kick power between min and max */
  power01: number;
}

export class AimPad {
  private cx = 0;
  private cy = 0;
  private radius = 70;
  private knobX = 0;
  private knobY = 0;
  /** a pad drag is in progress */
  aiming = false;

  private layout(r: Renderer): void {
    // bottom-right corner, sized to the screen, thumb-reachable
    this.radius = Math.max(48, Math.min(r.height * 0.16, 92));
    const margin = this.radius * 0.55;
    this.cx = r.width - margin - this.radius;
    this.cy = r.height - margin - this.radius;
  }

  /**
   * Process input. Returns true on the frame the pad is released (kick).
   * `enabled` gates new grabs (e.g. only while the player is aiming).
   */
  update(input: InputManager, r: Renderer, enabled: boolean): boolean {
    this.layout(r);
    const dx = input.screenX - this.cx;
    const dy = input.screenY - this.cy;
    const within = dx * dx + dy * dy <= (this.radius * 1.35) ** 2;

    if (!this.aiming && enabled && input.buttonPressed && within) {
      this.aiming = true;
    }
    if (this.aiming && input.buttonDown) {
      const d = Math.hypot(dx, dy);
      const k = d > this.radius ? this.radius / d : 1;
      this.knobX = dx * k;
      this.knobY = dy * k;
    }
    if (this.aiming && input.buttonReleased) {
      this.aiming = false;
      return true;
    }
    return false;
  }

  get vector(): AimVector {
    const d = Math.hypot(this.knobX, this.knobY);
    if (d < 1) return { dx: 0, dy: 0, power01: 0 };
    return { dx: this.knobX / d, dy: this.knobY / d, power01: Math.min(1, d / this.radius) };
  }

  reset(): void {
    this.aiming = false;
    this.knobX = 0;
    this.knobY = 0;
  }

  /** Draw in screen space (call after the world/HUD, outside the stage clip). */
  render(ctx: CanvasRenderingContext2D): void {
    ctx.save();
    ctx.globalAlpha = this.aiming ? 0.85 : 0.5;
    // base ring
    ctx.beginPath();
    ctx.arc(this.cx, this.cy, this.radius, 0, Math.PI * 2);
    ctx.fillStyle = 'rgba(0,0,0,0.35)';
    ctx.fill();
    ctx.lineWidth = 3;
    ctx.strokeStyle = 'rgba(255,255,255,0.6)';
    ctx.stroke();
    // direction line + knob
    const kx = this.cx + this.knobX;
    const ky = this.cy + this.knobY;
    if (this.aiming && (this.knobX || this.knobY)) {
      ctx.beginPath();
      ctx.moveTo(this.cx, this.cy);
      ctx.lineTo(kx, ky);
      ctx.strokeStyle = 'rgba(247,245,70,0.9)';
      ctx.lineWidth = 4;
      ctx.stroke();
    }
    ctx.beginPath();
    ctx.arc(kx, ky, this.radius * 0.32, 0, Math.PI * 2);
    ctx.fillStyle = this.aiming ? 'rgba(247,245,70,0.95)' : 'rgba(255,255,255,0.55)';
    ctx.fill();
    ctx.restore();
  }
}
