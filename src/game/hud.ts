// Gameplay HUD: the original ui_hud layout (score text + mute buttons) plus
// the kicks/coins counters in the in-game bitmap font.
import type { SceneContext } from '../scenes/scene';
import type { LevelState } from './game-state';
import { STAGE_W } from './defs';

export const HUD_BUTTONS = new Set(['btn_sfxMute', 'btn_musicMute']);

export function renderHud(ctx: SceneContext, level: LevelState): void {
  const g = ctx.r.ctx;
  const hover = ctx.ui.hitTest('ui_hud', 0, ctx.input.x, ctx.input.y, HUD_BUTTONS);
  ctx.ui.draw(g, 'ui_hud', 0, {
    hover,
    textOverrides: { textScore: String(level.score), textTitle: '' },
  });

  const kicksLeft = Math.max(0, level.maxKicks - level.numKicks);
  ctx.font.draw(g, `SHOTS ${kicksLeft}`, 12, 8);
  ctx.font.draw(g, `COINS ${level.coinsCollectedThisLevel}/${level.totalLevelCoins}`, STAGE_W - 12, 8, {
    align: 'right',
  });
}

/** mute button clicks; returns true when the click was consumed */
export function hudHandleClick(ctx: SceneContext): boolean {
  const hit = ctx.ui.hitTest('ui_hud', 0, ctx.input.x, ctx.input.y, HUD_BUTTONS);
  if (!hit) return false;
  if (hit === 'btn_sfxMute') {
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
