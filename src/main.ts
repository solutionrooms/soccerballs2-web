import { Renderer } from './render/renderer';
import { InputManager } from './core/input';
import { GameAudio } from './audio/audio';
import { loadSettings, saveSettings } from './core/settings';
import { loadSave, saveSave } from './game/save-data';
import { Atlas } from './render/atlas';
import { BitmapFont } from './render/bitmap-font';
import { UiScreens } from './render/ui-screen';
import type { Scene, SceneContext } from './scenes/scene';
import { DebugViewerScene } from './scenes/debug-viewer-scene';
import { GameScene } from './scenes/game-scene';
import { TitleScene } from './scenes/title-scene';
import { drawEngineBadge } from './render/engine-badge';
import { FRAME_TIME } from './game/defs';

const canvas = document.getElementById('game') as HTMLCanvasElement;
const renderer = new Renderer(canvas);
const input = new InputManager(canvas, renderer);
const base = import.meta.env.BASE_URL;
const audio = new GameAudio(`${base}assets/audio/`);
const settings = loadSettings();
const save = loadSave();
audio.sfxOn = settings.sfxOn;
audio.musicOn = settings.musicOn;
const atlas = new Atlas();
const font = new BitmapFont(atlas);
const ui = new UiScreens(`${base}assets/ui/`);

let current: Scene;
let pending: Scene | null = null;

const ctx: SceneContext = {
  r: renderer,
  input,
  audio,
  settings,
  save,
  saveSave: () => saveSave(save),
  atlas,
  font,
  ui,
  saveSettings: () => saveSettings(settings),
  setScene: (s: Scene) => {
    // First request wins — avoids async-import races queuing two transitions.
    if (pending) return;
    pending = s;
  },
};

function activate(scene: Scene): void {
  current?.onExit?.(ctx);
  current = scene;
  input.resetTransient();
  current.onEnter?.(ctx);
}

window.addEventListener('resize', () => renderer.resize());
// Resume audio on every gesture (mobile contexts re-suspend), not just once.
const unlock = (): void => audio.unlock();
window.addEventListener('pointerdown', unlock);
window.addEventListener('touchend', unlock);
window.addEventListener('keydown', unlock);
document.addEventListener('visibilitychange', () => {
  if (document.visibilityState === 'visible') audio.unlock();
});
// the debug viewer uses Tab; don't let it move focus
window.addEventListener('keydown', (e) => {
  if (e.code === 'Tab') e.preventDefault();
});

// Fixed 60Hz logic (original game is frame-locked), rendered per rAF.
let last = performance.now();
let acc = 0;
function frame(now: number): void {
  let dt = (now - last) / 1000;
  last = now;
  if (dt > 0.1) dt = 0.1; // clamp big stalls (tab switches)
  acc += dt;

  renderer.resize();
  try {
    let steps = 0;
    while (acc >= FRAME_TIME && steps < 4) {
      current.update(ctx);
      input.endFrame();
      acc -= FRAME_TIME;
      steps++;
    }
    if (steps === 4) acc = 0;
    current.render(ctx);
  } catch (e) {
    console.error('[soccerballs2] frame error:', e);
  }

  // debug overlay: active physics engine on every screen + level number in-game
  const level = current instanceof GameScene ? current.levelNumber : null;
  renderer.withStageTransform((g) => drawEngineBadge(g, settings.physicsEngine, level));

  if (pending) {
    const next = pending;
    pending = null;
    activate(next);
  }
  requestAnimationFrame(frame);
}

async function boot(): Promise<void> {
  // if Nape is the saved engine, load it now so it's ready at first level start
  if (settings.physicsEngine === 'nape') {
    const { ensureNapeLoaded } = await import('./physics/world');
    await ensureNapeLoaded().catch(() => {
      // couldn't load Nape — stay on Box2D so the game still boots
      settings.physicsEngine = 'planck';
      saveSettings(settings);
    });
  }
  await atlas.load(`${base}assets/pages/`);
  // ?debug=1 opens the asset viewer; default boots straight into gameplay
  const params = new URLSearchParams(location.search);
  if (params.get('debug')) {
    activate(new DebugViewerScene());
  } else if (params.get('level')) {
    activate(new GameScene(Math.max(0, Number(params.get('level')) - 1)));
  } else {
    activate(new TitleScene());
  }
  requestAnimationFrame(frame);
}

void boot();
