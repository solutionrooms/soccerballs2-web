import { loadJson, saveJson } from './storage';

export type PhysicsEngine = 'planck' | 'nape';

export interface Settings {
  sfxOn: boolean;
  musicOn: boolean;
  /** which physics engine drives gameplay (dev/test switch, see SettingsScene) */
  physicsEngine: PhysicsEngine;
}

const KEY = 'soccerballs2.settings';

const DEFAULTS: Settings = {
  sfxOn: true,
  musicOn: true,
  physicsEngine: 'planck',
};

export function loadSettings(): Settings {
  return { ...DEFAULTS, ...(loadJson<Partial<Settings>>(KEY) ?? {}) };
}

export function saveSettings(s: Settings): void {
  saveJson(KEY, s);
}
