// Team picker on the original screen_pickATeam_alt layout: each team slot
// shows a live player rig wearing that team's kit. Picking for the
// player or opponent side is chosen by the caller (match select).
import type { Scene, SceneContext } from './scene';
import { drawRig } from '../game/rig';
import { DEFAULT_TEAMS, kitOverride, resolveTeam } from '../game/kits';

export class PickTeamScene implements Scene {
  private side: 'player' | 'opponent';
  private back: () => Promise<Scene>;

  constructor(side: 'player' | 'opponent', back: () => Promise<Scene>) {
    this.side = side;
    this.back = back;
  }

  private slotAt(ctx: SceneContext, x: number, y: number): number {
    const screen = ctx.ui.screen('screen_pickATeam_alt');
    if (!screen) return -1;
    for (const child of screen.frames[0].children) {
      const m = child.name.match(/^team(\d)$/);
      if (!m) continue;
      if (Math.abs(x - child.x) < 70 && Math.abs(y - child.y) < 75) return Number(m[1]) - 1;
    }
    return -1;
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    if (!inp.buttonPressed) return;
    const hit = ctx.ui.hitTest('screen_pickATeam_alt', 0, inp.x, inp.y, new Set(['btn_back']));
    if (hit === 'btn_back') {
      ctx.audio.playSfx('sfx_click');
      void this.back().then((s) => ctx.setScene(s));
      return;
    }
    const slot = this.slotAt(ctx, inp.x, inp.y);
    if (slot >= 0) {
      ctx.audio.playSfx('sfx_click');
      if (this.side === 'player') ctx.save.playerTeam = slot;
      else ctx.save.opponentTeam = slot;
      ctx.saveSave();
      if (slot === 8) {
        // "design your own" opens the kit editor
        void import('./kit-edit-scene').then(({ KitEditScene }) =>
          ctx.setScene(new KitEditScene(this.back)),
        );
      } else {
        void this.back().then((s) => ctx.setScene(s));
      }
    }
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);
    const hover = ctx.ui.hitTest('screen_pickATeam_alt', 0, ctx.input.x, ctx.input.y, new Set(['btn_back']));
    ctx.ui.draw(g, 'screen_pickATeam_alt', 0, {
      hover,
      textOverrides: { textTitle: this.side === 'player' ? 'PICK YOUR TEAM' : 'PICK OPPONENTS' },
    });

    const screen = ctx.ui.screen('screen_pickATeam_alt');
    if (!screen) {
      r.endFrame();
      return;
    }
    const selected = this.side === 'player' ? ctx.save.playerTeam : ctx.save.opponentTeam;
    for (const child of screen.frames[0].children) {
      const m = child.name.match(/^team(\d)$/);
      if (!m) continue;
      const idx = Number(m[1]) - 1;
      const team = resolveTeam(idx, ctx.save.customTeam);
      // live kit preview: the player rig at idle frame 0
      drawRig(g, ctx.atlas, 'player', 0, child.x, child.y + 45, {
        scale: 0.9,
        override: kitOverride(team),
      });
      g.save();
      g.font = '11px "Komika Axis", sans-serif';
      g.fillStyle = idx === selected ? '#f7f546' : '#ffffff';
      g.textAlign = 'center';
      g.fillText(DEFAULT_TEAMS[idx].teamName, child.x, child.y + 62);
      g.restore();
    }
    r.endFrame();
  }
}
