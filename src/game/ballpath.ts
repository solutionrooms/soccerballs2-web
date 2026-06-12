// Kick aim preview, mirroring Game.RenderBallPath: simulate the ball's
// trajectory with Nape's integrator (v' = (1-d)^h * (v + a*h)) for 0.7s and
// draw a fading line in camera space.
import { VARS } from './defs';
import { NAPE_LINEAR_DRAG } from '../physics/world';
import { scaleTo } from './utils';

const STEPS = Math.floor(60 * 0.7);

export function renderBallPath(
  ctx: CanvasRenderingContext2D,
  ballX: number,
  ballY: number,
  jx: number,
  jy: number,
  mass: number,
  cameraX: number,
  cameraY: number,
): void {
  let x = ballX;
  let y = ballY;
  let vx = jx / mass;
  let vy = jy / mass;
  const h = 1 / 60;
  const g = VARS.gravity;
  const z = Math.pow(1 - NAPE_LINEAR_DRAG, h);

  ctx.save();
  ctx.lineWidth = 2;
  let prevX = x;
  let prevY = y;
  for (let i = 0; i < STEPS; i++) {
    vx = vx * z;
    vy = (vy + g * h) * z;
    x += vx * h;
    y += vy * h;
    const alpha = scaleTo(1, 0, 0, STEPS, i);
    ctx.strokeStyle = `rgba(255,255,255,${Math.max(0, alpha).toFixed(3)})`;
    ctx.beginPath();
    ctx.moveTo(prevX - cameraX, prevY - cameraY);
    ctx.lineTo(x - cameraX, y - cameraY);
    ctx.stroke();
    prevX = x;
    prevY = y;
  }
  ctx.restore();
}
