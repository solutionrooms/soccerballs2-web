import { loadJson, saveJson } from './storage';

export interface Settings {
  sfxOn: boolean;
  musicOn: boolean;
  /** dev/debug: show the "Watch walkthrough" button in-level (recorded routes). */
  devMode: boolean;
  /**
   * Physics engine: false = compiled nape.js (default), true = the bit-exact
   * hand-port of the ORIGINAL game's Nape (src/physics/replica). The replica
   * intentionally differs from nape.js — it matches the original engine.
   */
  replicaPhysics: boolean;
}

const KEY = 'soccerballs2.settings';

const DEFAULTS: Settings = {
  sfxOn: true,
  musicOn: true,
  devMode: false,
  replicaPhysics: false,
};

export function loadSettings(): Settings {
  return { ...DEFAULTS, ...(loadJson<Partial<Settings>>(KEY) ?? {}) };
}

export function saveSettings(s: Settings): void {
  saveJson(KEY, s);
}
