// Custom kit editor on the original screen_modifyTeam layout
// (UI_ModifyTeam.as): pick a part (shirt/pattern/shorts/socks), pick a color
// from the 16-swatch kit palette, choose plain/stripes/hoops. The live
// preview is the player rig wearing the edited kit.
import type { Scene, SceneContext } from './scene';
import { drawRig } from '../game/rig';
import { KIT_COLORS, kitOverride } from '../game/kits';

const BUTTONS = new Set([
  'btn_back',
  'btn_shirt',
  'btn_pattern',
  'btn_shorts',
  'btn_socks',
  'btn_shirtPlain',
  'btn_shirtStripes',
  'btn_shirtHoops',
]);

type Part = 'kitColorShirt' | 'kitColorPattern' | 'kitColorShorts' | 'kitColorSocks';

export class KitEditScene implements Scene {
  private back: () => Promise<Scene>;
  private part: Part = 'kitColorShirt';

  constructor(back: () => Promise<Scene>) {
    this.back = back;
  }

  private paletteBox(ctx: SceneContext): { x: number; y: number } | null {
    const screen = ctx.ui.screen('screen_modifyTeam');
    const pal = screen?.frames[0].children.find((c) => c.name === 'palette');
    return pal ? { x: pal.x, y: pal.y } : null;
  }

  private swatchAt(ctx: SceneContext, x: number, y: number): number {
    const pal = this.paletteBox(ctx);
    if (!pal) return -1;
    // 4x4 swatch grid, 30px cells, anchored at the palette child
    const col = Math.floor((x - pal.x) / 30);
    const row = Math.floor((y - pal.y) / 30);
    if (col < 0 || col > 3 || row < 0 || row > 3) return -1;
    return row * 4 + col;
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    if (!inp.buttonPressed) return;
    const team = ctx.save.customTeam;

    const hit = ctx.ui.hitTest('screen_modifyTeam', 0, inp.x, inp.y, BUTTONS);
    if (hit) ctx.audio.playSfx('sfx_click');
    switch (hit) {
      case 'btn_back':
        ctx.save.playerTeam = 8;
        ctx.saveSave();
        void this.back().then((s) => ctx.setScene(s));
        return;
      case 'btn_shirt':
        this.part = 'kitColorShirt';
        return;
      case 'btn_pattern':
        this.part = 'kitColorPattern';
        return;
      case 'btn_shorts':
        this.part = 'kitColorShorts';
        return;
      case 'btn_socks':
        this.part = 'kitColorSocks';
        return;
      case 'btn_shirtPlain':
        team.kitStyle = 0;
        ctx.saveSave();
        return;
      case 'btn_shirtStripes':
        team.kitStyle = 2;
        ctx.saveSave();
        return;
      case 'btn_shirtHoops':
        team.kitStyle = 1;
        ctx.saveSave();
        return;
    }

    const swatch = this.swatchAt(ctx, inp.x, inp.y);
    if (swatch >= 0) {
      ctx.audio.playSfx('sfx_click');
      team[this.part] = swatch;
      ctx.saveSave();
    }
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);
    const hover = ctx.ui.hitTest('screen_modifyTeam', 0, ctx.input.x, ctx.input.y, BUTTONS);
    ctx.ui.draw(g, 'screen_modifyTeam', 0, {
      hover,
      hidden: new Set(['kit']),
      textOverrides: { textTeamName: ctx.save.customTeam.teamName, textTitle: 'DESIGN YOUR KIT' },
    });

    // palette swatches (4x4 of the 16 kit colors)
    const pal = this.paletteBox(ctx);
    if (pal) {
      for (let i = 0; i < KIT_COLORS.length; i++) {
        const c = KIT_COLORS[i];
        const x = pal.x + (i % 4) * 30;
        const y = pal.y + Math.floor(i / 4) * 30;
        g.fillStyle = `rgb(${c[0]},${c[1]},${c[2]})`;
        g.fillRect(x, y, 26, 26);
        if (ctx.save.customTeam[this.part] === i) {
          g.strokeStyle = '#ffffff';
          g.lineWidth = 3;
          g.strokeRect(x - 2, y - 2, 30, 30);
        }
      }
    }

    // live preview where the screen's kit display sits
    const screen = ctx.ui.screen('screen_modifyTeam');
    const kitChild = screen?.frames[0].children.find((c) => c.name === 'kit');
    if (kitChild) {
      drawRig(g, ctx.atlas, 'player', 0, kitChild.x, kitChild.y + 80, {
        scale: 2,
        override: kitOverride(ctx.save.customTeam),
      });
    }
    r.endFrame();
  }
}
