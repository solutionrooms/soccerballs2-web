// Core constants mirrored from Defs.as / GameVars.as.
import varsJson from '../data/vars.json';

export const STAGE_W = 700;
export const STAGE_H = 525;
export const FPS = 60;
export const FRAME_TIME = 1 / FPS;

export const MAX_GAME_OBJECTS = 450;
export const MAX_PARTICLES = 30;

// Balance constants from VarsData.xml (kick_dist0/1, kick_power0/1, gravity, ...)
export const VARS = varsJson as Record<string, number>;

// Nape worked in pixels; planck wants meters.
export const PX_PER_METER = 30;

// Collision categories (Objects_Data.xml comment block)
export const COL_FLOOR = 1;
export const COL_PLAYERS = 2;
export const COL_BALL = 4;
export const COL_OBJECTS = 8;
