// Debug overlay drawn on top of every scene: the active engine (always Nape)
// and the current level number during play. Meant to be hidden for release.
import { STAGE_W, STAGE_H } from '../game/defs';
import { uiFont } from './ui-screen';

export function drawEngineBadge(
  g: CanvasRenderingContext2D,
  engine: 'nape' | 'nape-replica',
  level: number | null,
): void {
  const isReplica = engine === 'nape-replica';
  const label = isReplica ? 'NAPE·R' : 'NAPE';
  const text = level != null ? `${label}  ·  Lv ${level}` : label;

  g.save();
  g.font = uiFont(13, 800);
  const padX = 9;
  const h = 21;
  const w = Math.ceil(g.measureText(text).width) + padX * 2;
  const x = STAGE_W - w - 6;
  const y = STAGE_H - h - 6;
  // engine-specific colour so the active engine reads at a glance
  g.fillStyle = isReplica ? 'rgba(28,96,206,0.88)' : 'rgba(214,84,28,0.88)';
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
