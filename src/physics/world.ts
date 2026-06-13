// Barrel for the physics layer. Historically this file held the single planck
// PhysicsWorld class; the engine is now pluggable (planck or Nape) so the
// implementation lives in phys-world.ts (abstraction) + planck-world.ts /
// nape-world.ts (engines). Re-exported here so existing import paths still work.
export {
  PhysicsWorld,
  type PhysWorld,
  type PhysBody,
  type ShapeDef,
  type MaterialDef,
  type FixtureTag,
  type ContactEvent,
  type CreateBodyOpts,
  type JointSpec,
} from './phys-world';
export { PlanckWorld, triangulate, NAPE_LINEAR_DRAG } from './planck-world';
export { NapePhysWorld, ensureNapeLoaded, napeLoaded } from './nape-world';
