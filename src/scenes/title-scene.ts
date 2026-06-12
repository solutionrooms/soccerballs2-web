// Title screen rendered from the original screen_mainMenu layout
// (UI_TitleScreen.as flow). Portal/ad buttons are hidden — the web port
// keeps play, credits, and clear-save.
import type { Scene, SceneContext } from './scene';
import { STAGE_W, STAGE_H } from '../game/defs';
import { MatchSelectScene } from './match-select-scene';
import { newSave } from '../game/save-data';

const SCREEN = 'screen_mainMenu';
// portal-era buttons that don't apply to the web port
const HIDDEN = new Set([
  'mainLogo', // portal (Hooda) branding slot
  'btn_y8',
  'btn_moregames',
  'btn_facebook',
  'btn_download',
  'btn_prequel',
  'turboBtn',
  'btn_language',
]);
const ACTIVE = new Set(['btn_playgame', 'btn_clearSaveGame', 'btn_credits']);

export class TitleScene implements Scene {
  private confirmClear = false;

  onEnter(ctx: SceneContext): void {
    ctx.audio.playMusic('menus_music');
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    if (!inp.buttonPressed) return;

    if (this.confirmClear) {
      const hit = ctx.ui.hitTest('screen_clearSave', 0, inp.x, inp.y, new Set(['btn_yes', 'btn_no']));
      if (hit === 'btn_yes') {
        Object.assign(ctx.save, newSave());
        ctx.saveSave();
        ctx.audio.playSfx('sfx_click');
      }
      if (hit) this.confirmClear = false;
      return;
    }

    const hit = ctx.ui.hitTest(SCREEN, 0, inp.x, inp.y, ACTIVE);
    if (!hit) return;
    ctx.audio.playSfx('sfx_click');
    if (hit === 'btn_playgame') {
      ctx.setScene(new MatchSelectScene());
    } else if (hit === 'btn_clearSaveGame') {
      this.confirmClear = true;
    } else if (hit === 'btn_credits') {
      void import('./credits-scene').then(({ CreditsScene }) => ctx.setScene(new CreditsScene()));
    }
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);

    if (this.confirmClear) {
      g.fillStyle = 'rgba(0,0,0,0.5)';
      g.fillRect(0, 0, STAGE_W, STAGE_H);
      const hover = ctx.ui.hitTest('screen_clearSave', 0, ctx.input.x, ctx.input.y, new Set(['btn_yes', 'btn_no']));
      ctx.ui.draw(g, 'screen_clearSave', 0, {
        hover,
        hiddenCharIds: new Set([151]), // full-screen "INFORMATION HERE" placeholder
        centerTexts: new Set(['textTitle']),
      });
    } else {
      const hover = ctx.ui.hitTest(SCREEN, 0, ctx.input.x, ctx.input.y, ACTIVE);
      ctx.ui.draw(g, SCREEN, 0, { hidden: HIDDEN, hover });
      // sound toggle in the corner (ui_hud mute buttons arrive with the HUD pass)
      ctx.font.draw(g, `SOUND ${ctx.settings.sfxOn ? 'ON' : 'OFF'}`, STAGE_W - 14, STAGE_H - 26, { align: 'right' });
      if (ctx.input.buttonPressed && ctx.input.x > STAGE_W - 160 && ctx.input.y > STAGE_H - 40) {
        ctx.settings.sfxOn = !ctx.settings.sfxOn;
        ctx.settings.musicOn = ctx.settings.sfxOn;
        ctx.audio.sfxOn = ctx.settings.sfxOn;
        ctx.audio.setMusicOn(ctx.settings.musicOn);
        ctx.saveSettings();
      }
    }
    r.endFrame();
  }
}
