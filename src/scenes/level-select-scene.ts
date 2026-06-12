// Level select rebuilt from the original UI_LevelSelect.as: screen_levelSelect
// frame + 4 pages of 9 levelIcon components in the original grid (x from 145
// step 150 wrapping past 500, y from 90 step 130, scale 1.6). Locked levels
// render through a grey filter; gold star shows for rated levels, cup for
// collected trophies.
import type { Scene, SceneContext } from './scene';
import { LEVELS } from '../game/level-loader';
import { GameScene } from './game-scene';
import { fillTextSafe } from '../render/ui-screen';
import { coinsCollectedTotal } from '../game/save-data';

const NUM_PER_PAGE = 9;
const NUM_PAGES = 4;
const ICON_SCALE = 1.6;

interface IconPos {
  x: number;
  y: number;
}

// UI_LevelSelect.InitPage (UI_LevelSelect.as:83-110)
function iconPositions(): IconPos[] {
  const out: IconPos[] = [];
  const ox = 145;
  let x = ox;
  let y = 90;
  for (let i = 0; i < NUM_PER_PAGE; i++) {
    out.push({ x, y });
    x += 150;
    if (x > 700 - 200) {
      x = ox;
      y += 130;
    }
  }
  return out;
}
const ICON_POS = iconPositions();

const SCREEN_BUTTONS = new Set(['btn_back', 'nextPage', 'prevPage']);

export class LevelSelectScene implements Scene {
  private page = 0;
  private hoverLevel = -1;

  onEnter(ctx: SceneContext): void {
    ctx.audio.playMusic('menus_music');
  }

  private iconAt(x: number, y: number): number {
    // icon art is roughly 90x90 at scale 1.6, centred near its origin
    for (let i = 0; i < NUM_PER_PAGE; i++) {
      const p = ICON_POS[i];
      if (Math.abs(x - p.x) < 60 && Math.abs(y - p.y) < 55) {
        const level = this.page * NUM_PER_PAGE + i;
        if (level < LEVELS.length) return level;
      }
    }
    return -1;
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    this.hoverLevel = this.iconAt(inp.x, inp.y);
    if (!inp.buttonPressed) return;

    const hit = ctx.ui.hitTest('screen_levelSelect', 0, inp.x, inp.y, SCREEN_BUTTONS);
    if (hit === 'btn_back') {
      // UI_LevelSelect.buttonBackPressed -> matchselect (UI_LevelSelect.as:307-311)
      ctx.audio.playSfx('sfx_click');
      void import('./match-select-scene').then(({ MatchSelectScene }) =>
        ctx.setScene(new MatchSelectScene()),
      );
      return;
    }
    // PrevPageClicked/NextPageClicked wrap around (UI_LevelSelect.as:208-219)
    if (hit === 'prevPage') {
      ctx.audio.playSfx('sfx_click');
      this.page = (this.page - 1 + NUM_PAGES) % NUM_PAGES;
      return;
    }
    if (hit === 'nextPage') {
      ctx.audio.playSfx('sfx_click');
      this.page = (this.page + 1) % NUM_PAGES;
      return;
    }

    const level = this.iconAt(inp.x, inp.y);
    if (level >= 0 && ctx.save.levels[level].available) {
      ctx.audio.playSfx('sfx_click');
      ctx.setScene(new GameScene(level));
    }
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);

    const hover = ctx.ui.hitTest('screen_levelSelect', 0, ctx.input.x, ctx.input.y, SCREEN_BUTTONS);
    const hidden = new Set<string>();
    if (this.page === 0) hidden.add('prevPage');
    if (this.page === NUM_PAGES - 1) hidden.add('nextPage');
    hidden.add('coinBox'); // baked "100/100" placeholder text — redrawn below
    hidden.add('trophies'); // baked all-gold strip — redrawn below
    ctx.ui.draw(g, 'screen_levelSelect', 0, {
      hidden,
      hover,
      textOverrides: {
        textLevelName: this.hoverLevel >= 0 ? LEVELS[this.hoverLevel].name : '',
      },
    });

    // collection status (replaces coinBox/trophies sprites): star count +
    // the ten trophies, greyed until collected
    g.save();
    g.fillStyle = 'rgba(10,25,12,0.75)';
    g.beginPath();
    g.roundRect(243, 477, 125, 35, 8);
    g.fill();
    ctx.atlas.draw(g, 'Pickups', 0, 262, 495, { scale: 1.1 });
    g.font = '14px "Komika Axis", sans-serif';
    g.fillStyle = '#f7f546';
    g.textAlign = 'left';
    g.textBaseline = 'middle';
    const totalCoins = LEVELS.reduce((s2, l) => s2 + l.totalCoins, 0);
    fillTextSafe(g, `${coinsCollectedTotal(ctx.save)}/${totalCoins}`, 280, 496);
    g.beginPath();
    g.roundRect(378, 477, 320, 35, 8);
    g.fillStyle = 'rgba(10,25,12,0.75)';
    g.fill();
    for (let t = 1; t <= 10; t++) {
      const got = ctx.save.trophies.includes(t);
      if (!got) g.filter = 'grayscale(1) brightness(0.55)';
      ctx.atlas.draw(g, 'Pickups_Trophies', t - 1, 390 + (t - 1) * 26, 505, { scale: 0.55 });
      g.filter = 'none';
    }
    g.fillStyle = '#f7f546';
    fillTextSafe(g, `${ctx.save.trophies.length}/10`, 652, 496);
    g.restore();

    for (let i = 0; i < NUM_PER_PAGE; i++) {
      const level = this.page * NUM_PER_PAGE + i;
      if (level >= LEVELS.length) continue;
      const p = ctx.save.levels[level];
      const pos = ICON_POS[i];
      const coinsTotal = LEVELS[level].totalCoins;
      const coinsGot = (ctx.save.coins[String(level)] ?? []).length;
      const coinPC = coinsTotal > 0 ? Math.floor((coinsGot * 100) / coinsTotal) : 0;
      const trophyGot =
        LEVELS[level].trophyIndex > 0 && ctx.save.trophies.includes(LEVELS[level].trophyIndex);

      const iconHidden = new Set<string>(['textLevelCreator', 'buttonName', 'greystar']);
      if (!p.rating) iconHidden.add('gold');
      if (!trophyGot) iconHidden.add('cup');
      ctx.ui.draw(g, 'levelIcon', 0, {
        offsetX: pos.x,
        offsetY: pos.y,
        scale: ICON_SCALE,
        hidden: iconHidden,
        filter: p.available ? undefined : 'grayscale(1) brightness(0.6)',
        textOverrides: {
          levelNumber: String(level + 1),
          coinpercent: `${coinPC}%`,
        },
      });
    }

    r.endFrame();
  }
}
