import type { Renderer } from '../render/renderer';
import type { InputManager } from '../core/input';
import type { GameAudio } from '../audio/audio';
import type { Settings } from '../core/settings';
import type { SaveData } from '../game/save-data';
import type { Atlas } from '../render/atlas';
import type { BitmapFont } from '../render/bitmap-font';
import type { UiScreens } from '../render/ui-screen';

/** Shared services handed to every scene. */
export interface SceneContext {
  r: Renderer;
  input: InputManager;
  audio: GameAudio;
  settings: Settings;
  save: SaveData;
  saveSave(): void;
  atlas: Atlas;
  font: BitmapFont;
  ui: UiScreens;
  saveSettings(): void;
  setScene(s: Scene): void;
}

export interface Scene {
  onEnter?(ctx: SceneContext): void;
  onExit?(ctx: SceneContext): void;
  /** Called at a fixed 60Hz, matching the original frame-locked logic. */
  update(ctx: SceneContext): void;
  render(ctx: SceneContext): void;
}
