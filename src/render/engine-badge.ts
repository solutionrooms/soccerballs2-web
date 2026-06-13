// Debug overlay drawn on top of every scene so it's always clear which physics
// engine is active while testing, plus the current level number during play.
// Toggled by settings.physicsEngine; meant to be hidden/removed for release.
import { STAGE_W, STAGE_H } from '../game/defs';
import { uiFont } from './ui-screen';
import type { PhysicsEngine } from '../core/settings';

export function drawEngineBadge(
  g: CanvasRenderingContext2D,
  engine: PhysicsEngine,
  level: number | null,
): void {
  const isNape = engine === 'nape';
  const label = isNape ? 'NAPE' : 'BOX2D';
  const text = level != null ? `${label}  ·  Lv ${level}` : label;

  g.save();
  g.font = uiFont(13, 800);
  const padX = 9;
  const h = 21;
  const w = Math.ceil(g.measureText(text).width) + padX * 2;
  const x = STAGE_W - w - 6;
  const y = STAGE_H - h - 6;
  // engine-specific colour so the active engine reads at a glance
  g.fillStyle = isNape ? 'rgba(214,84,28,0.88)' : 'rgba(28,96,206,0.88)';
  g.beginPath();
  g.roundRect(x, y, w, h, 6);
  g.fill();
  g.strokeStyle = 'rgba(255,255,255,0.35)';
  g.lineWidth = 1;
  g.stroke();
  g.fillStyle = '#ffffff';
  g.textAlign = 'left';
  g.textBaseline = 'middle';
  g.fillText(text, x + padX, y + h / 2 + 1);
  g.restore();
}
