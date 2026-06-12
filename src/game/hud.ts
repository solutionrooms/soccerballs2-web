// Gameplay HUD: the original ui_hud layout (score text + mute buttons) plus
// the kicks/coins counters in the in-game bitmap font.
import type { SceneContext } from '../scenes/scene';
import type { LevelState } from './game-state';
import { STAGE_W } from './defs';

export const HUD_BUTTONS = new Set(['btn_sfxMute', 'btn_musicMute']);

// Mute button hit boxes in stage space (from the ui_hud layout). Generous for
// finger taps; the visible art is smaller.
const SFX_BOX = { x0: 50, y0: 462, x1: 110, y1: 520 };
const MUSIC_BOX = { x0: 0, y0: 462, x1: 58, y1: 520 };

function inBox(b: { x0: number; y0: number; x1: number; y1: number }, x: number, y: number): boolean {
  return x >= b.x0 && x <= b.x1 && y >= b.y0 && y <= b.y1;
}

export function renderHud(ctx: SceneContext, level: LevelState): void {
  const g = ctx.r.ctx;
  ctx.ui.draw(g, 'ui_hud', 0, {
    textOverrides: { textScore: String(level.score), textTitle: '' },
  });

  // muted-state feedback: a red strike through the button when its sound is off
  strikeIfMuted(g, MUSIC_BOX, ctx.settings.musicOn);
  strikeIfMuted(g, SFX_BOX, ctx.settings.sfxOn);

  const kicksLeft = Math.max(0, level.maxKicks - level.numKicks);
  ctx.font.draw(g, `SHOTS ${kicksLeft}`, 12, 8);
  ctx.font.draw(g, `COINS ${level.coinsCollectedThisLevel}/${level.totalLevelCoins}`, STAGE_W - 12, 8, {
    align: 'right',
  });
}

function strikeIfMuted(
  g: CanvasRenderingContext2D,
  b: { x0: number; y0: number; x1: number; y1: number },
  on: boolean,
): void {
  if (on) return;
  g.save();
  g.strokeStyle = 'rgba(220,40,40,0.9)';
  g.lineWidth = 3;
  g.beginPath();
  g.moveTo(b.x0 + 16, b.y0 + 18);
  g.lineTo(b.x1 - 16, b.y1 - 18);
  g.stroke();
  g.restore();
}

/** mute button taps; returns true when consumed. */
export function hudHandleClick(ctx: SceneContext): boolean {
  const x = ctx.input.x;
  const y = ctx.input.y;
  let hit: 'sfx' | 'music' | null = null;
  if (inBox(SFX_BOX, x, y)) hit = 'sfx';
  else if (inBox(MUSIC_BOX, x, y)) hit = 'music';
  if (!hit) return false;

  if (hit === 'sfx') {
    ctx.settings.sfxOn = !ctx.settings.sfxOn;
    ctx.audio.sfxOn = ctx.settings.sfxOn;
  } else {
    ctx.settings.musicOn = !ctx.settings.musicOn;
    ctx.audio.setMusicOn(ctx.settings.musicOn);
  }
  ctx.saveSettings();
  ctx.audio.playSfx('sfx_click');
  return true;
}
