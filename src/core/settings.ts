import { loadJson, saveJson } from './storage';

export interface Settings {
  sfxOn: boolean;
  musicOn: boolean;
  /** dev/debug: show the "Watch walkthrough" button in-level (recorded routes). */
  devMode: boolean;
}

const KEY = 'soccerballs2.settings';

const DEFAULTS: Settings = {
  sfxOn: true,
  musicOn: true,
  devMode: false,
};

export function loadSettings(): Settings {
  return { ...DEFAULTS, ...(loadJson<Partial<Settings>>(KEY) ?? {}) };
}

export function saveSettings(s: Settings): void {
  saveJson(KEY, s);
}
