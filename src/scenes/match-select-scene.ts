// Match select on the original screen_matchSelect layout: home/away kit
// previews, pick buttons opening the team picker for each side, then play.
import type { Scene, SceneContext } from './scene';
import { drawRig } from '../game/rig';
import { DEFAULT_TEAMS, kitOverride, resolveTeam } from '../game/kits';
import { PickTeamScene } from './pick-team-scene';
import { LevelSelectScene } from './level-select-scene';

const BUTTONS = new Set(['btn_back', 'btn_pick0', 'btn_pick1', 'btn_playgame']);

export class MatchSelectScene implements Scene {
  onEnter(ctx: SceneContext): void {
    ctx.audio.playMusic('menus_music');
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    if (!inp.buttonPressed) return;
    const hit = ctx.ui.hitTest('screen_matchSelect', 0, inp.x, inp.y, BUTTONS);
    if (!hit) return;
    ctx.audio.playSfx('sfx_click');
    const backHere = async (): Promise<Scene> => new MatchSelectScene();
    if (hit === 'btn_back') {
      void import('./title-scene').then(({ TitleScene }) => ctx.setScene(new TitleScene()));
    } else if (hit === 'btn_pick0') {
      ctx.setScene(new PickTeamScene('player', backHere));
    } else if (hit === 'btn_pick1') {
      ctx.setScene(new PickTeamScene('opponent', backHere));
    } else if (hit === 'btn_playgame') {
      ctx.setScene(new LevelSelectScene());
    }
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);
    const hover = ctx.ui.hitTest('screen_matchSelect', 0, ctx.input.x, ctx.input.y, BUTTONS);
    const playerTeam = resolveTeam(ctx.save.playerTeam, ctx.save.customTeam);
    const oppoTeam = resolveTeam(ctx.save.opponentTeam, ctx.save.customTeam);
    ctx.ui.draw(g, 'screen_matchSelect', 0, {
      hover,
      hidden: new Set(['homeTeam', 'awayTeam']),
      textOverrides: {
        textTeamName0: DEFAULT_TEAMS[ctx.save.playerTeam]?.teamName ?? playerTeam.teamName,
        textTeamName1: DEFAULT_TEAMS[ctx.save.opponentTeam]?.teamName ?? oppoTeam.teamName,
      },
    });

    // live kit previews at the homeTeam/awayTeam slots
    const screen = ctx.ui.screen('screen_matchSelect');
    const home = screen?.frames[0].children.find((c) => c.name === 'homeTeam');
    const away = screen?.frames[0].children.find((c) => c.name === 'awayTeam');
    if (home) drawRig(g, ctx.atlas, 'player', 0, home.x, home.y + 70, { scale: 1.6, override: kitOverride(playerTeam) });
    if (away) {
      drawRig(g, ctx.atlas, 'player', 0, away.x, away.y + 70, {
        scale: 1.6,
        xflip: true,
        override: kitOverride(oppoTeam),
      });
    }
    r.endFrame();
  }
}
