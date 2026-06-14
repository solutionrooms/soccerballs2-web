// Gameplay scene mirroring Game.as UpdateGameplay: input -> pre-update ->
// physics step -> write-back -> object logic -> win/fail tests -> render
// layers sorted by zpos.
import { uiFont } from '../render/ui-screen';
import type { Scene, SceneContext } from './scene';
import { PhysicsWorld, NapePhysWorld, type PhysWorld } from '../physics/world';
import type { MaterialDef } from '../physics/world';
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
import { RouteReplay } from '../game/sim/replay';
import type { RoutesFile } from '../game/sim/route-types';
import routesJson from '../data/routes.json';
import objectsJson from '../data/objects.json';

const ROUTES = routesJson as unknown as RoutesFile;

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
  private physics!: PhysWorld;
  private objects!: GameObjects;
  private level!: LevelState;
  private loaded!: LoadedLevel;
  private camera = new Camera();
  private aimPad = new AimPad();
  private g!: GameContext;
  private levelIndex: number;
  // dev "watch walkthrough": replay the recorded route with input suppressed
  private replay: RouteReplay | null = null;
  private replayActive = false;

  constructor(levelIndex = 0) {
    this.levelIndex = levelIndex;
  }

  /** 1-based level number, for the debug engine/level badge overlay. */
  get levelNumber(): number {
    return this.levelIndex + 1;
  }

  onEnter(ctx: SceneContext): void {
    this.buildLevel(ctx);
    ctx.audio.playMusic('music_ingame1');
  }

  /** (Re)build a fresh playable level — used on enter and to reset for a replay. */
  private buildLevel(ctx: SceneContext): void {
    // Nape is the only engine; it's preloaded at boot (ensureNapeLoaded)
    const materials = (objectsJson as unknown as { materials: Record<string, MaterialDef> }).materials;
    this.physics = new NapePhysWorld(materials);
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
  }

  /** the recorded route for this level, if one was solved. */
  private get route() {
    const r = ROUTES.levels?.[String(this.levelIndex)];
    return r && r.kicks.length > 0 ? r : null;
  }

  /** dev "Watch" button is offered only in dev mode and only when a route exists. */
  private get canWatch(): boolean {
    return !!this.route;
  }

  private startReplay(ctx: SceneContext): void {
    const route = this.route;
    if (!route) return;
    this.buildLevel(ctx); // restart the level clean, then drive the recorded kicks
    this.paused = false;
    this.replay = new RouteReplay(route.kicks);
    this.replayActive = true;
  }

  private stopReplay(ctx: SceneContext): void {
    this.replayActive = false;
    this.replay = null;
    this.buildLevel(ctx); // back to a fresh, player-controlled level
  }

  // bottom-left button rect (screen space), clear of the HUD strip
  private static readonly WATCH_BTN = { x: 12, y: 432, w: 150, h: 40 };
  private watchBtnHit(x: number, y: number): boolean {
    const b = GameScene.WATCH_BTN;
    return x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h;
  }

  update(ctx: SceneContext): void {
    const inp = ctx.input;
    this.g.mouseX = inp.x;
    this.g.mouseY = inp.y;
    this.g.cameraX = this.camera.x;
    this.g.cameraY = this.camera.y;

    // ---- dev "watch walkthrough": drive the recorded route, suppress input ----
    if (this.replayActive) {
      if (this.level.phase !== 'play') {
        this.replayActive = false; // replay reached the result screen — resume normal flow
        this.replay = null;
      } else {
        if (inp.keyPressed('Escape') || (inp.buttonPressed && this.watchBtnHit(inp.x, inp.y))) {
          this.stopReplay(ctx);
          return;
        }
        this.g.aimOverride = null;
        this.replay?.tick(this.g);
        // fall through to the physics step; the user-input block is skipped
      }
    }

    if (!this.replayActive) {
      // dev: a click on the Watch button restarts the level and plays the route
      if (
        ctx.settings.devMode &&
        this.canWatch &&
        this.level.phase === 'play' &&
        inp.buttonPressed &&
        this.watchBtnHit(inp.x, inp.y)
      ) {
        ctx.audio.playSfx('sfx_click');
        this.startReplay(ctx);
        return;
      }

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
    } // end !replayActive input handling

    // physics: park stationary bodies, step, write back
    for (const go of this.objects.list) {
      if (go.body && go.physicsStationary) {
        PhysicsWorld.setPosPx(go.body, go.xpos, go.ypos, go.dir);
        PhysicsWorld.setVelPx(go.body, 0, 0);
        PhysicsWorld.setAngularVelocity(go.body, 0);
      }
    }
    this.physics.step();
    for (const go of this.objects.list) {
      if (go.body && !go.physicsStationary && PhysicsWorld.isDynamic(go.body)) {
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

    // dev "watch walkthrough" button + replay banner
    if (ctx.settings.devMode && this.level.phase === 'play' && !this.replayActive && this.canWatch) {
      this.drawWatchButton(g, ctx);
    }
    if (this.replayActive) this.drawReplayBanner(g);

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

  private drawWatchButton(g: CanvasRenderingContext2D, ctx: SceneContext): void {
    const b = GameScene.WATCH_BTN;
    const hover = this.watchBtnHit(ctx.input.x, ctx.input.y);
    g.save();
    g.fillStyle = hover ? 'rgba(20,120,40,0.92)' : 'rgba(8,60,20,0.85)';
    g.strokeStyle = 'rgba(255,255,255,0.4)';
    g.lineWidth = 2;
    g.beginPath();
    g.roundRect(b.x, b.y, b.w, b.h, 8);
    g.fill();
    g.stroke();
    g.fillStyle = '#ffffff';
    g.font = '600 16px sans-serif';
    g.textAlign = 'center';
    g.textBaseline = 'middle';
    g.fillText('▶ WATCH SOLUTION', b.x + b.w / 2, b.y + b.h / 2);
    g.restore();
  }

  private drawReplayBanner(g: CanvasRenderingContext2D): void {
    g.save();
    g.fillStyle = 'rgba(0,0,0,0.55)';
    g.fillRect(0, 0, STAGE_W, 30);
    g.fillStyle = '#9fe870';
    g.font = '600 15px sans-serif';
    g.textAlign = 'center';
    g.textBaseline = 'middle';
    const shots = this.replay ? `  shot ${this.replay.kicksIssued}` : '';
    g.fillText(`▶ WATCHING WALKTHROUGH${shots}  —  click / Esc to stop`, STAGE_W / 2, 15);
    g.restore();
  }
}
