// Settings / dev menu (not part of the original game — added for testing, and
// meant to be hidden or trimmed for the final build): sound + music toggles and
// an "Open all levels" debug unlock.
import type { Scene, SceneContext } from './scene';
import { STAGE_W } from '../game/defs';
import { uiFont, fillTextSafe } from '../render/ui-screen';
import { setReplicaEngine } from '../physics/world';

interface Row {
  y: number;
  h: number;
  label: string;
  value: () => string;
  hint?: () => string;
  onClick: (ctx: SceneContext) => void;
}

const PANEL_X = 110;
const PANEL_W = STAGE_W - 220;
const ROW_X = PANEL_X + 24;
const ROW_W = PANEL_W - 48;
const PANEL_Y = 44;
const PANEL_H = 470;
const ROW_Y0 = 100;
const ROW_STEP = 72;
const BACK_Y = 460;

export class SettingsScene implements Scene {
  private rows: Row[] = [];

  onEnter(ctx: SceneContext): void {
    ctx.audio.playMusic('menus_music');
    this.buildRows();
  }

  private buildRows(): void {
    this.rows = [];
    let y = ROW_Y0;
    const mk = (label: string, value: () => string, onClick: Row['onClick'], hint?: () => string): void => {
      this.rows.push({ y, h: 50, label, value, hint, onClick });
      y += ROW_STEP;
    };
    mk(
      'Sound',
      () => (this.s.sfxOn ? 'ON' : 'OFF'),
      (ctx) => {
        ctx.settings.sfxOn = !ctx.settings.sfxOn;
        ctx.audio.sfxOn = ctx.settings.sfxOn;
        ctx.saveSettings();
      },
    );
    mk(
      'Music',
      () => (this.s.musicOn ? 'ON' : 'OFF'),
      (ctx) => {
        ctx.settings.musicOn = !ctx.settings.musicOn;
        ctx.audio.setMusicOn(ctx.settings.musicOn);
        ctx.saveSettings();
      },
    );
    mk(
      'Open all levels',
      () => {
        const lv = this.ctxRef!.save.levels;
        return `${lv.filter((l) => l.available).length}/${lv.length}`;
      },
      (ctx) => {
        for (const l of ctx.save.levels) l.available = true;
        ctx.saveSave();
      },
      () => 'unlock every level (debug), then pick from Level Select',
    );
    mk(
      'Dev walkthroughs',
      () => (this.s.devMode ? 'ON' : 'OFF'),
      (ctx) => {
        ctx.settings.devMode = !ctx.settings.devMode;
        ctx.saveSettings();
      },
      () => 'show the in-level "Watch" button to replay the recorded route',
    );
    mk(
      'Physics engine',
      () => (this.s.replicaPhysics ? 'Replica' : 'Nape.js'),
      (ctx) => {
        ctx.settings.replicaPhysics = !ctx.settings.replicaPhysics;
        setReplicaEngine(ctx.settings.replicaPhysics);
        ctx.saveSettings();
      },
      () => 'Replica = bit-exact port of the original engine — applies on level restart / next level',
    );
  }

  private get s() {
    return this.ctxRef!.settings;
  }
  private ctxRef: SceneContext | null = null;

  update(ctx: SceneContext): void {
    this.ctxRef = ctx;
    const inp = ctx.input;
    if (!inp.buttonPressed) return;

    // BACK button (bottom)
    if (inp.x >= ROW_X && inp.x <= ROW_X + ROW_W && inp.y >= BACK_Y && inp.y <= BACK_Y + 50) {
      ctx.audio.playSfx('sfx_click');
      void import('./title-scene').then(({ TitleScene }) => ctx.setScene(new TitleScene()));
      return;
    }

    for (const row of this.rows) {
      if (inp.x >= ROW_X && inp.x <= ROW_X + ROW_W && inp.y >= row.y && inp.y <= row.y + row.h) {
        ctx.audio.playSfx('sfx_click');
        row.onClick(ctx);
        return;
      }
    }
  }

  render(ctx: SceneContext): void {
    this.ctxRef = ctx;
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;
    ctx.atlas.draw(g, 'backgrounds', 0, 0, 0);

    // panel
    g.save();
    g.fillStyle = 'rgba(8,22,12,0.82)';
    g.beginPath();
    g.roundRect(PANEL_X, PANEL_Y, PANEL_W, PANEL_H, 14);
    g.fill();

    g.textAlign = 'center';
    g.textBaseline = 'middle';
    g.fillStyle = '#f7f546';
    g.font = uiFont(34);
    fillTextSafe(g, 'SETTINGS', STAGE_W / 2, PANEL_Y + 34);

    for (const row of this.rows) {
      const hover =
        ctx.input.x >= ROW_X && ctx.input.x <= ROW_X + ROW_W && ctx.input.y >= row.y && ctx.input.y <= row.y + row.h;
      this.drawButton(g, row.y, row.label, row.value(), hover);
      if (row.hint) {
        g.font = uiFont(13, 600);
        g.fillStyle = 'rgba(255,255,255,0.65)';
        g.textAlign = 'left';
        fillTextSafe(g, row.hint(), ROW_X + 6, row.y + row.h + 11);
      }
    }

    // BACK
    const backHover =
      ctx.input.x >= ROW_X && ctx.input.x <= ROW_X + ROW_W && ctx.input.y >= BACK_Y && ctx.input.y <= BACK_Y + 50;
    this.drawButton(g, BACK_Y, 'Back', '', backHover, true);
    g.restore();

    r.endFrame();
  }

  private drawButton(
    g: CanvasRenderingContext2D,
    y: number,
    label: string,
    value: string,
    hover: boolean,
    center = false,
  ): void {
    g.fillStyle = hover ? 'rgba(255,255,255,0.18)' : 'rgba(255,255,255,0.08)';
    g.strokeStyle = 'rgba(255,255,255,0.25)';
    g.lineWidth = 2;
    g.beginPath();
    g.roundRect(ROW_X, y, ROW_W, 50, 10);
    g.fill();
    g.stroke();

    g.textBaseline = 'middle';
    g.font = uiFont(22);
    if (center) {
      g.textAlign = 'center';
      g.fillStyle = '#ffffff';
      fillTextSafe(g, label, ROW_X + ROW_W / 2, y + 25);
      return;
    }
    g.textAlign = 'left';
    g.fillStyle = '#ffffff';
    fillTextSafe(g, label, ROW_X + 18, y + 25);
    g.textAlign = 'right';
    g.fillStyle = '#9fe870';
    fillTextSafe(g, value, ROW_X + ROW_W - 18, y + 25);
  }
}
