// Gameplay scene mirroring Game.as UpdateGameplay: input -> pre-update ->
// physics step -> write-back -> object logic -> win/fail tests -> render
// layers sorted by zpos.
import { uiFont } from '../render/ui-screen';
import type { Scene, SceneContext } from './scene';
import { PhysicsWorld } from '../physics/world';
import { GameObjects, GameContext, GameObj } from '../game/gameobj';
import { LevelState } from '../game/game-state';
import { loadLevel, LoadedLevel, LEVELS } from '../game/level-loader';
import { Camera } from '../game/camera';
import { AimPad } from '../render/aim-pad';
import { kickAim } from '../game/behaviors/core';
import { renderBallPath } from '../game/ballpath';
import { renderTerrainLine } from '../game/terrain';
import { renderHud, hudHandleClick } from '../game/hud';
import { STAGE_W, STAGE_H, FPS, VARS } from '../game/defs';
import { unlockedBy, returnsToMap } from '../game/progression';
import { kitOverride, resolveTeam } from '../game/kits';
import { scaleTo, scaleToPreLimit } from '../game/utils';
import objectsJson from '../data/objects.json';

const PAUSE_BUTTONS = new Set(['ButtonRestart', 'ButtonQuit', 'ButtonContinue']);

// portal/ad-era children hidden on the level-complete screen
const LC_HIDDEN = new Set([
  'adBox',
  'btn_moregames',
  'btn_walkthrough',
  'btn_prequel',
  'buttonPlayWithHighcores',
  'highscore',
  'coinBox',
  'trophies',
  'btn_feature1',
  'btn_feature2',
  'btn_feature3',
  'btn_feature4',
  'info1',
  'info2',
  'info3',
  'info4',
]);
const LC_BUTTONS = new Set(['buttonLevelSelect']);
// these sprites' PNG exports carry the FLA TextFields' placeholder text baked
// in — hide them and draw the rows cleanly instead
for (const n of ['levelName', 'scoreText1', 'scoreText2']) LC_HIDDEN.add(n);

export class GameScene implements Scene {
  private paused = false;
  private lcFrame = 0; // level-complete screen animation (ui runs at 30fps)
  private physics!: PhysicsWorld;
  private objects!: GameObjects;
  private level!: LevelState;
  private loaded!: LoadedLevel;
  private camera = new Camera();
  private aimPad = new AimPad();
  private g!: GameContext;
  private levelIndex: number;

  constructor(levelIndex = 0) {
    this.levelIndex = levelIndex;
  }

  onEnter(ctx: SceneContext): void {
    this.physics = new PhysicsWorld(
      (objectsJson as unknown as { materials: Record<string, never> }).materials,
    );
    this.objects = new GameObjects();
    this.level = new LevelState();
    this.camera.reset();
    this.aimPad.reset();

    this.g = {
      physics: this.physics,
      atlas: ctx.atlas,
      level: this.level,
      audio: ctx.audio,
      objects: this.objects,
      mouseX: 0,
      mouseY: 0,
      cameraX: 0,
      cameraY: 0,
      bounds: { left: -2000, top: -2000, right: 2000, bottom: 2000 },
    };

    this.level.collectedCoinIndices = new Set(ctx.save.coins[String(this.levelIndex)] ?? []);
    this.level.playerKit = kitOverride(resolveTeam(ctx.save.playerTeam, ctx.save.customTeam));
    this.level.opponentKit = kitOverride(resolveTeam(ctx.save.opponentTeam, ctx.save.customTeam));
    this.loaded = loadLevel(this.g, this.levelIndex);
    this.level.maxKicks = this.loaded.def.failKicks;
    this.level.goldKicks = this.loaded.def.goldKicks;
    // ball out-of-bounds rectangle is the scroll area (Game.boundingRectangle)
    this.g.bounds = this.loaded.scrollBounds;
    this.level.phase = 'play';

    ctx.audio.playMusic('music_ingame1');
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    this.g.mouseX = inp.x;
    this.g.mouseY = inp.y;
    this.g.cameraX = this.camera.x;
    this.g.cameraY = this.camera.y;

    // pause (P / Escape, or while the pause screen is up)
    if (inp.keyPressed('KeyP') || inp.keyPressed('Escape')) this.paused = !this.paused;
    if (this.paused) {
      if (inp.buttonPressed) {
        const hit = ctx.ui.hitTest('screen_paused', 0, inp.x, inp.y, PAUSE_BUTTONS);
        if (hit) ctx.audio.playSfx('sfx_click');
        if (hit === 'ButtonContinue') this.paused = false;
        else if (hit === 'ButtonRestart') ctx.setScene(new GameScene(this.levelIndex));
        else if (hit === 'ButtonQuit') {
          void import('./level-select-scene').then(({ LevelSelectScene }) =>
            ctx.setScene(new LevelSelectScene()),
          );
        }
      }
      return;
    }

    // aiming: a touch player AIMS with the corner pad (finger off the field)
    // and then TAPS the field/player to kick; a mouse player aims by pointing
    // and clicks to kick.
    const playerAiming = this.level.phase === 'play' && this.objects.byName('football')?.state === 1;
    if (inp.isTouch) {
      // mute buttons are checked first, unconditionally, so a tap on them is
      // never swallowed by the pad/kick logic
      const muteHit = inp.buttonPressed && hudHandleClick(ctx);
      const onPad = this.aimPad.contains(inp, ctx.r);
      this.aimPad.update(inp, ctx.r, !!playerAiming);
      // the pad aim persists, so the trajectory keeps showing
      this.g.aimOverride = this.aimPad.hasAim ? this.aimPad.vector : null;
      // a tap on the field (not the pad, not a mute button) commits the kick
      // with the current aim — releasing the pad never fires
      if (inp.buttonPressed && !muteHit && !onPad && inp.y < 487 && playerAiming && this.aimPad.hasAim) {
        this.level.doKick = true;
      }
    } else {
      this.g.aimOverride = null;
      // HUD mute buttons consume the click before kick handling
      if (inp.buttonPressed && hudHandleClick(ctx)) {
        // consumed
      } else if (this.level.phase === 'play' && inp.buttonPressed && inp.y < 487) {
        // click-to-kick (GameObj.as:5031-5038 — only above the HUD strip)
        this.level.doKick = true;
      }
    }

    if (this.level.phase === 'end') {
      if (this.level.success) this.lcFrame += 0.5;
      if (inp.buttonPressed) {
        if (this.level.success) {
          const hit = ctx.ui.hitTest('screen_levelComplete', 28, inp.x, inp.y, LC_BUTTONS);
          if (hit === 'buttonLevelSelect') {
            ctx.audio.playSfx('sfx_click');
            void import('./level-select-scene').then(({ LevelSelectScene }) =>
              ctx.setScene(new LevelSelectScene()),
            );
          } else if (returnsToMap(this.levelIndex + 1) || this.levelIndex + 1 >= LEVELS.length) {
            void import('./level-select-scene').then(({ LevelSelectScene }) =>
              ctx.setScene(new LevelSelectScene()),
            );
          } else {
            ctx.setScene(new GameScene(this.levelIndex + 1));
          }
        } else {
          ctx.setScene(new GameScene(this.levelIndex));
        }
      }
      return;
    }

    // physics: park stationary bodies, step, write back
    for (const go of this.objects.list) {
      if (go.body && go.physicsStationary) {
        PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir);
        PhysicsWorld.setVelPx(go.body, 0, 0);
        go.body.setAngularVelocity(0);
      }
    }
    this.physics.step();
    for (const go of this.objects.list) {
      if (go.body && !go.physicsStationary && go.body.isDynamic()) {
        const p = PhysicsWorld.getPosPx(go.body);
        go.xpos = p.x;
        go.ypos = p.y;
        go.dir = p.rot;
      }
    }

    // contacts -> onHit callbacks (BEGIN events only — Nape onHitFunction semantics)
    for (const c of this.physics.takeContacts()) {
      const a = c.a.owner as GameObj;
      const b = c.b.owner as GameObj;
      if (a?.onHitFn) a.onHitFn(a, b, this.g, c.sensor);
      if (b?.onHitFn) b.onHitFn(b, a, this.g, c.sensor);
    }

    // object logic
    kickAim.active = false;
    for (const go of this.objects.list) {
      if (!go.dead && go.updateFn) go.updateFn(go, this.g);
    }
    this.objects.flushAdds();
    this.objects.removeDead(this.physics);

    // win test (Game.as:1524-1556)
    if (this.level.phase === 'play') {
      this.level.levelTimer++;
      const gotRefs = this.level.totalRefs === 0 || this.level.numRefsHit >= this.level.totalRefs;
      if (this.level.totalGoals > 0 && this.level.numGoalsScored >= this.level.totalGoals && gotRefs) {
        this.level.success = true;
        ctx.audio.playSfx('sfx_levelcomplete');
        this.level.phase = 'complete';
        this.level.phaseTimer = 0;
      }
    } else if (this.level.phase === 'complete') {
      this.level.phaseTimer++;
      if (this.level.success) this.lcFrame += 0.5;
      if (this.level.phaseTimer > FPS) {
        this.level.phase = 'end';
        if (this.level.success) this.applyProgress(ctx);
      }
    }

    // camera follows the ball
    const ball = this.objects.byName('football');
    // touch aims via the corner pad, so don't bias the camera toward the
    // finger — keep the ball centred
    const camMouseX = inp.isTouch ? STAGE_W / 2 : inp.x;
    const camMouseY = inp.isTouch ? STAGE_H / 2 : inp.y;
    this.camera.update(ball, camMouseX, camMouseY, this.loaded.scrollBounds);
  }

  // DoEndLevelStuff (Game.as:752-775): rating, unlock chain, coins, trophies
  private applyProgress(ctx: SceneContext): void {
    const p = ctx.save.levels[this.levelIndex];
    p.complete = true;
    if (this.level.numKicks <= this.level.goldKicks) p.rating = Math.max(p.rating, 1);
    p.bestScore = Math.max(p.bestScore, this.level.score);
    p.bestShots = p.bestShots === 0 ? this.level.numKicks : Math.min(p.bestShots, this.level.numKicks);
    for (const id of unlockedBy(this.levelIndex + 1)) {
      ctx.save.levels[id - 1].available = true;
    }
    const key = String(this.levelIndex);
    const coins = new Set(ctx.save.coins[key] ?? []);
    for (const c of this.level.coinsThisRun) coins.add(c);
    ctx.save.coins[key] = [...coins];
    if (this.level.trophyCollectedThisRun) {
      const t = this.loaded.def.trophyIndex;
      if (t > 0 && !ctx.save.trophies.includes(t)) ctx.save.trophies.push(t);
    }
    ctx.save.totalScore += this.level.score;
    ctx.saveSave();
  }

  render(ctx: SceneContext): void {
    const r = ctx.r;
    r.beginFrame();
    const g = r.ctx;

    // background (bg frame fills the stage; parallax arrives with M2 polish)
    ctx.atlas.draw(g, 'backgrounds', this.loaded.def.bgFrame - 1, 0, 0);

    g.save();
    g.translate(-this.camera.x, -this.camera.y);

    // render order: zpos descending (Far_Background 2000 ... Near_Foreground -200)
    const sorted = [...this.objects.list].sort((a, b) => b.zpos - a.zpos);
    let terrainDrawn = false;
    for (const go of sorted) {
      // terrain polys live at Polys_1 (-20) / Polys_2 (-30); draw all lines
      // when we first reach that depth so fills sit under nearer objects
      if (!terrainDrawn && go.zpos <= -5) {
        this.renderTerrain(g, ctx);
        terrainDrawn = true;
      }
      if (go.renderFn && !go.dead) go.renderFn(go, this.g, g);
    }
    if (!terrainDrawn) this.renderTerrain(g, ctx);
    g.restore();

    // aim path + power arrow (RenderFootballOverlayObject, GameObj.as:4885-4945)
    if (kickAim.active && this.level.phase === 'play') {
      renderBallPath(g, kickAim.ballX, kickAim.ballY, kickAim.jx, kickAim.jy, kickAim.mass, this.camera.x, this.camera.y);
      // arrow offset = (0,-10) rotated by aim angle + 90deg, scaled by drag distance
      const rot = Math.atan2(kickAim.jy, kickAim.jx) + Math.PI / 2;
      const ox = Math.sin(rot) * 10;
      const oy = -Math.cos(rot) * 10;
      const scl = scaleToPreLimit(0.5, 1, VARS.kick_dist0, VARS.kick_dist1, kickAim.dist);
      ctx.atlas.draw(g, 'powerArrow', 0, kickAim.ballX + ox - this.camera.x, kickAim.ballY + oy - this.camera.y, {
        rot: (rot * 180) / Math.PI,
        scale: scl,
      });
    }

    // ball countdown dial once past the 4s mark (GameObj.as:4947-4953)
    const ballGO = this.objects.byName('football');
    if (ballGO && ballGO.state === 2 && ballGO.ballTimer > this.level.ballTimerShowTimerMax) {
      const frames = ctx.atlas.frameCount('generalTimer');
      const f = scaleTo(0, frames - 1, 0, this.level.ballTimerMax, ballGO.ballTimer);
      ctx.atlas.draw(
        g,
        'generalTimer',
        f | 0,
        Math.round(ballGO.xpos) - Math.round(this.camera.x),
        Math.round(ballGO.ypos) - 20 - Math.round(this.camera.y),
      );
    }

    renderHud(ctx, this.level);

    if (this.paused) {
      g.fillStyle = 'rgba(0,0,0,0.5)';
      g.fillRect(0, 0, STAGE_W, STAGE_H);
      const hover = ctx.ui.hitTest('screen_paused', 0, ctx.input.x, ctx.input.y, PAUSE_BUTTONS);
      ctx.ui.draw(g, 'screen_paused', 0, { hover });
    }

    if ((this.level.phase === 'complete' || this.level.phase === 'end') && this.level.success) {
      // animated screen_levelComplete with dynamic texts (UI_LevelComplete.as)
      const frame = Math.min(this.lcFrame | 0, 28);
      const hover =
        this.level.phase === 'end'
          ? ctx.ui.hitTest('screen_levelComplete', 28, ctx.input.x, ctx.input.y, LC_BUTTONS)
          : null;
      const gold = this.level.numKicks <= this.level.goldKicks;
      const hidden = new Set(LC_HIDDEN);
      if (!gold) hidden.add('levelrating');
      ctx.ui.draw(g, 'screen_levelComplete', frame, { hidden, hover });
      // clean dynamic rows inside the black panel (panel spans x 36..330)
      if (frame >= 20) {
        g.save();
        g.textAlign = 'center';
        g.textBaseline = 'top';
        g.font = uiFont(18);
        g.fillStyle = '#f7f546';
        g.fillText(this.loaded.def.name.toUpperCase(), 183, 88);
        g.font = uiFont(16);
        g.fillStyle = '#ffffff';
        g.fillText(`SCORE: ${this.level.score}`, 183, 142);
        g.fillText(`SHOTS: ${this.level.numKicks}  (GOLD: ${this.level.goldKicks})`, 183, 176);
        g.restore();
        if (this.level.phase === 'end') {
          ctx.font.draw(g, 'CLICK TO CONTINUE', STAGE_W / 2, STAGE_H - 36, { align: 'center' });
        }
      }
    } else if (this.level.phase === 'complete' || this.level.phase === 'end') {
      g.fillStyle = 'rgba(0,0,0,0.45)';
      g.fillRect(0, STAGE_H / 2 - 60, STAGE_W, 120);
      ctx.font.draw(g, 'LEVEL FAILED', STAGE_W / 2, STAGE_H / 2 - 30, { align: 'center', scale: 1.5 });
      if (this.level.phase === 'end') {
        ctx.font.draw(g, 'CLICK TO RETRY', STAGE_W / 2, STAGE_H / 2 + 14, { align: 'center' });
      }
    }

    r.endFrame();

    // aim pad drawn in screen space (outside the stage clip), touch only,
    // while the player can kick
    if (ctx.input.isTouch && this.level.phase === 'play' && this.objects.byName('football')?.state === 1) {
      this.aimPad.render(g);
      if (this.aimPad.hasAim) {
        g.save();
        g.globalAlpha = 0.85;
        g.fillStyle = '#fff';
        g.font = '600 16px sans-serif';
        g.textAlign = 'center';
        g.fillText('TAP TO KICK', r.width / 2, r.height - 14);
        g.restore();
      }
    }
  }

  private renderTerrain(g: CanvasRenderingContext2D, ctx: SceneContext): void {
    // Polys_2 (mud, deeper) first, then Polys_1 (grass) on top
    const order = [...this.loaded.lines].sort((a, b) => b.go.zpos - a.go.zpos);
    for (const line of order) {
      // poly_switch lines are invisible sensors (InitGameObjLine_Switch)
      if (line.polymat === 'poly_switch') continue;
      if (line.initType === 'poly' || line.initType === 'nophysics') {
        renderTerrainLine(g, ctx.atlas, line);
      }
    }
  }
}
