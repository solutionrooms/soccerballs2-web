// Team kits, ported verbatim from GameVars.as: the 16-color kit palette
// (GameVars.as:828-847), the 9 default teams (InitTeamsOnce, :755-825), and
// the part->color mapping AddHierarchy_Player applies (GameObj.as:6063-6110).
import type { RigPartOverride } from './rig';

export type RGB = [number, number, number];

export const KIT_COLORS: RGB[] = [
  [255, 255, 255], [10, 10, 10], [100, 100, 100], [247, 245, 70],
  [0, 173, 245], [72, 117, 246], [30, 76, 208], [19, 21, 97],
  [237, 28, 36], [157, 10, 14], [112, 36, 54], [77, 3, 3],
  [255, 78, 0], [237, 20, 90], [28, 185, 104], [29, 124, 51],
];

export interface TeamDef {
  teamName: string;
  kitColorShirt: number;
  kitColorShorts: number;
  kitColorSocks: number;
  kitColorPattern: number;
  /** 0 = plain, 1 = hoops, 2 = stripes */
  kitStyle: number;
}

export const DEFAULT_TEAMS: TeamDef[] = [
  { teamName: 'ENGLAND', kitColorPattern: 9, kitColorShirt: 0, kitColorShorts: 0, kitColorSocks: 0, kitStyle: 0 },
  { teamName: 'FRANCE', kitColorPattern: 6, kitColorShirt: 7, kitColorShorts: 7, kitColorSocks: 7, kitStyle: 0 },
  { teamName: 'BRAZIL', kitColorPattern: 0, kitColorShirt: 3, kitColorShorts: 6, kitColorSocks: 0, kitStyle: 0 },
  { teamName: 'NETHERLANDS', kitColorPattern: 0, kitColorShirt: 12, kitColorShorts: 12, kitColorSocks: 12, kitStyle: 0 },
  { teamName: 'GERMANY', kitColorPattern: 10, kitColorShirt: 0, kitColorShorts: 1, kitColorSocks: 0, kitStyle: 0 },
  { teamName: 'SPAIN', kitColorPattern: 0, kitColorShirt: 9, kitColorShorts: 7, kitColorSocks: 9, kitStyle: 0 },
  { teamName: 'USA', kitColorPattern: 8, kitColorShirt: 0, kitColorShorts: 0, kitColorSocks: 0, kitStyle: 1 },
  { teamName: 'GLASGOW', kitColorPattern: 0, kitColorShirt: 15, kitColorShorts: 0, kitColorSocks: 15, kitStyle: 1 },
  { teamName: 'DESIGN YOUR OWN', kitColorPattern: 6, kitColorShirt: 13, kitColorShorts: 10, kitColorSocks: 15, kitStyle: 1 },
];

/**
 * Rig override for a team's kit: per-clip ColorTransform tints + pattern part
 * visibility by style (AddHierarchy_Player).
 */
export function kitOverride(team: TeamDef): RigPartOverride {
  const shirt = KIT_COLORS[team.kitColorShirt];
  const shorts = KIT_COLORS[team.kitColorShorts];
  const socks = KIT_COLORS[team.kitColorSocks];
  const pattern = KIT_COLORS[team.kitColorPattern];

  const tints = new Map<string, RGB>([
    ['tint_shirtbase', shirt],
    ['tint_topArm', shirt],
    ['tint_topLeg', shorts],
    ['tint_socks', socks],
    ['tint_hoopsEXP', pattern],
    ['tint_shirtStripes', pattern],
  ]);
  const hidden = new Set<string>();
  if (team.kitStyle !== 1) hidden.add('body.tint_hoops');
  if (team.kitStyle !== 2) hidden.add('body.tint_stripes');
  return { tints, hidden };
}

export function resolveTeam(index: number, customTeam: TeamDef): TeamDef {
  return index === 8 ? customTeam : DEFAULT_TEAMS[index] ?? DEFAULT_TEAMS[0];
}

// AddHierarchy_Player skin pick (GameObj.as:6070-6118): player_Race 0/1 chooses
// a head (light heads 0-7 / dark heads 8-15) AND, for race 1, sets every limb
// skin part to frame 1 (the dark-skin art) so the whole player is one tone.
// Limbs left at frame 0 (light) with a dark head was the "grey head, white body"
// mismatch.
const SKIN_LIMB_PARTS = [
  'upperArmRight',
  'lowerArmRight',
  'upperArmLeft',
  'lowerArmLeft',
  'upperLegRight',
  'upperLegLeft',
  'footRight',
  'footLeft',
];

export function pickPlayerSkin(): Map<string, number> {
  const rand = (a: number, b: number): number => a + Math.floor(Math.random() * (b - a + 1));
  const frames = new Map<string, number>();
  const race = rand(0, 1);
  frames.set('head', race === 1 ? rand(8, 15) : rand(0, 7));
  if (race === 1) for (const p of SKIN_LIMB_PARTS) frames.set(p, 1);
  return frames;
}
