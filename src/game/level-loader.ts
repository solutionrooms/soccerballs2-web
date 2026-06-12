// Builds a level's GameObjects + physics from levels.json/objects.json,
// mirroring Levels.LoadLevel + PhysicsBase.AddPhysObjAt/InitLines.
import levelsJson from '../data/levels.json';
import objectsJson from '../data/objects.json';
import { GameObj, GameContext } from './gameobj';
import {
  initFootball,
  initPlayer,
  initRef,
  initGoal,
  initPickup,
  initPickupTrophy,
  initHelpText,
  onSwitchHelpText,
} from './behaviors/core';
import { registry as hazardsRegistry } from './behaviors/hazards';
import {
  registry as switchesRegistry,
  logicLinks,
  registerSwitchFunction,
} from './behaviors/switches';
import {
  registry as moversRegistry,
  switchFunctions as moverSwitchFunctions,
  clearPathLines,
  registerPathLine,
  createLevelJoint,
} from './behaviors/movers';
import { registry as charactersRegistry, setSpawnPhysObjFn } from './behaviors/characters';
import type { ShapeDef } from '../physics/world';

type InitFn = (go: GameObj, g: GameContext) => void;

const coreRegistry: Record<string, InitFn> = {
  InitFootball: (go) => initFootball(go),
  InitPlayer: (go) => initPlayer(go),
  InitRef: (go, g) => initRef(go, g),
  InitGoal: (go, g) => initGoal(go, g),
  InitPickup: (go, g) => initPickup(go, g),
  GameObj_InitHelpText: (go) => initHelpText(go),
  // GameObj.as:4288-4301 — walkthrough markers remove themselves outside
  // walkthrough mode (which the port doesn't ship)
  InitWalkthroughObject: (go) => {
    go.visible = false;
    go.dead = true;
  },
};
for (let i = 1; i <= 10; i++) {
  coreRegistry[`InitPickupTrophy${i}`] = (go, g) => initPickupTrophy(go, g, i);
}

export const REGISTRY: Record<string, InitFn> = {
  ...coreRegistry,
  ...hazardsRegistry,
  ...switchesRegistry,
  ...moversRegistry,
  ...charactersRegistry,
};

export interface LevelDef {
  id: string;
  name: string;
  bgFrame: number;
  goldKicks: number;
  failKicks: number;
  totalCoins: number;
  trophyIndex: number;
  instances: {
    id: string;
    type: string;
    x: number;
    y: number;
    rot: number;
    scale: number;
    params: Record<string, string>;
  }[];
  joints: {
    id: string;
    type: string;
    obj0: string;
    obj1: string;
    x: number;
    y: number;
    x0: number;
    y0: number;
    x1: number;
    y1: number;
    params: Record<string, string>;
  }[];
  lines: { id: string; type: number; points: number[]; params: Record<string, string> }[];
}

interface PhysObjDef {
  name: string;
  hasPhysics: boolean;
  snapToFloor: boolean;
  initFunction: string | null;
  params: Record<string, string>;
  bodies: {
    name: string;
    pos: [number, number];
    fixed: boolean;
    sensor: boolean;
    graphics: { clip: string; frame: number; pos: [number, number]; rot: number }[];
    shapes: ShapeDef[];
  }[];
}

const data = objectsJson as unknown as {
  physobjs: Record<string, PhysObjDef>;
  gamelayers: Record<string, number>;
  polymats: Record<
    string,
    {
      clip: string;
      frame: number;
      initType: string;
      colCat: number;
      colMask: number;
      senCat: number;
      senMask: number;
      initFunction: string;
      material: string;
      gameLayer: string;
    }
  >;
};

export const LEVELS = (levelsJson as unknown as { levels: LevelDef[] }).levels;
export const GAME_LAYERS = data.gamelayers;

export interface LoadedLine {
  go: GameObj;
  points: number[];
  polymat: string;
  initType: string;
}

export interface LoadedLevel {
  def: LevelDef;
  scrollBounds: { left: number; top: number; right: number; bottom: number };
  lines: LoadedLine[];
}

export function loadLevel(g: GameContext, index: number): LoadedLevel {
  const def = LEVELS[index];
  let scrollBounds = { left: 0, top: 0, right: 700, bottom: 525 };
  const lines: LoadedLine[] = [];
  clearPathLines();

  // ---- lines (terrain / scroll area / paths / switch sensors) ----
  for (const line of def.lines) {
    const matName = line.params['line_material'] ?? '';
    const polymat = data.polymats[matName];
    if (!polymat) continue;

    if (polymat.initFunction === 'InitGameObjLine_ScrollArea') {
      let minX = Infinity;
      let minY = Infinity;
      let maxX = -Infinity;
      let maxY = -Infinity;
      for (let i = 0; i < line.points.length; i += 2) {
        minX = Math.min(minX, line.points[i]);
        maxX = Math.max(maxX, line.points[i]);
        minY = Math.min(minY, line.points[i + 1]);
        maxY = Math.max(maxY, line.points[i + 1]);
      }
      scrollBounds = { left: minX, top: minY, right: maxX, bottom: maxY };
      continue;
    }

    if (polymat.initType === 'path') {
      registerPathLine(line.id, line.points, line.params['line_spline'] === 'true');
      continue;
    }

    const go = g.objects.add();
    go.id = line.id;
    go.name = 'border';
    go.zpos = GAME_LAYERS[polymat.gameLayer] ?? 0;
    go.dobjName = polymat.clip;
    go.frame = polymat.frame;

    if (polymat.initType === 'poly') {
      if (polymat.colCat !== 0 && polymat.colMask !== 0) {
        go.body = g.physics.createStaticLoop(go, line.points, polymat.material, polymat.colCat, polymat.colMask);
      } else if (polymat.senCat !== 0 && polymat.senMask !== 0) {
        // sensor-only line (poly_switch): senses without colliding
        go.body = g.physics.createStaticLoop(go, line.points, polymat.material, polymat.senCat, polymat.senMask, true);
      }
    }
    const lineInit = REGISTRY[polymat.initFunction];
    if (lineInit) lineInit(go, g);
    lines.push({ go, points: line.points, polymat: matName, initType: polymat.initType });
  }

  // ---- object instances ----
  for (const inst of def.instances) {
    createInstance(g, inst.type, inst.x, inst.y, inst.rot, inst.scale, inst.params, inst.id);
  }

  g.objects.flushAdds();

  // ---- joints (after all instances exist; resolved by editor id) ----
  for (const joint of def.joints) {
    const goA = joint.obj0 ? (g.objects.list.find((o) => o.id === joint.obj0) ?? null) : null;
    const goB = joint.obj1 ? (g.objects.list.find((o) => o.id === joint.obj1) ?? null) : null;
    if (joint.type === 'logic') {
      // obj0 = switch, obj1 = target (PhysicsBase.as:570-579)
      if (goA && goB) {
        const list = logicLinks.get(goA) ?? [];
        list.push(goB);
        logicLinks.set(goA, list);
      }
      continue;
    }
    createLevelJoint(g, joint.type, goA, goB, joint);
  }

  // bridge: movers register their toggles in their own map — expose them to
  // the switch system so logic links can flip paths/cogs
  for (const go of g.objects.list) {
    const fn = moverSwitchFunctions.get(go);
    if (fn) registerSwitchFunction(go, () => fn());
  }

  // logic-linked help texts wait for their switch (GameObj_UpdateHelpText
  // state 3 + OnSwitch_HelpText)
  for (const go of g.objects.list) {
    for (const target of logicLinks.get(go) ?? []) {
      if (target.name === 'text') {
        target.state = 3;
        registerSwitchFunction(target, () => onSwitchHelpText(target));
      }
    }
  }

  return { def, scrollBounds, lines };
}

/**
 * Create one physobj instance (level load + spawner runtime).
 * Mirrors Levels.CreateLevelObjInstanceAt + PhysicsBase.AddPhysObjAt.
 */
export function createInstance(
  g: GameContext,
  type: string,
  x: number,
  y: number,
  rot: number,
  scale: number,
  params: Record<string, string>,
  id = '',
): GameObj | null {
  const po = data.physobjs[type];
  if (!po) return null;
  const go = g.objects.add();
  go.id = id;
  go.type = type;
  go.name = type;
  go.xpos = x;
  go.ypos = y;
  go.dir = rot;
  go.scale = scale;
  go.params = { ...po.params, ...params };
  const layer = go.params['game_layer'] || 'Centre';
  go.zpos = GAME_LAYERS[layer] ?? 0;

  const body0 = po.bodies[0];
  if (body0) {
    const graphic = body0.graphics[0];
    if (graphic) {
      go.dobjName = graphic.clip;
      go.frame = graphic.frame;
    }
    // AS3 builds collision even for hasPhysics=false defs that carry shapes
    // (e.g. icecreamvan)
    if (body0.shapes.length) {
      const fixedParam = go.params['fixed'];
      const fixed = fixedParam !== undefined && fixedParam !== '' ? fixedParam === 'true' : body0.fixed;
      go.body = g.physics.createBody(go, x, y, rot, scale, body0.shapes, {
        fixed,
        bullet: type.startsWith('ball_'),
      });
      if (!fixed) go.physicsStationary = false;
    }
  }

  // default render: draw the def's clip+frame
  go.renderFn = (o, gg, ctx) => {
    if (!o.visible || !o.dobjName) return;
    gg.atlas.draw(ctx, o.dobjName, o.frame | 0, o.xpos, o.ypos, {
      rot: o.dir,
      scale: o.scale,
      xflip: o.xflip,
    });
  };

  const init = po.initFunction ? REGISTRY[po.initFunction] : undefined;
  if (init) init(go, g);
  return go;
}

// the spawner creates spikyballs etc. at runtime through the same factory
setSpawnPhysObjFn((g, typeName, x, y) => {
  createInstance(g, typeName, x, y, 0, 1, {});
});
