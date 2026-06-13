import { loadJson, saveJson } from './storage';

export interface Settings {
  sfxOn: boolean;
  musicOn: boolean;
}

const KEY = 'soccerballs2.settings';

const DEFAULTS: Settings = {
  sfxOn: true,
  musicOn: true,
};

export function loadSettings(): Settings {
  return { ...DEFAULTS, ...(loadJson<Partial<Settings>>(KEY) ?? {}) };
}

export function saveSettings(s: Settings): void {
  saveJson(KEY, s);
}
