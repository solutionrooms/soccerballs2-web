// Barrel for the physics layer. The game holds a PhysWorld and calls body ops
// through the PhysicsWorld static facade (phys-world.ts); the engine is Nape
// (nape-world.ts). Re-exported here so existing import paths keep working.
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
export { triangulate } from './geometry';
export {
  NapePhysWorld,
  ensureNapeLoaded,
  napeLoaded,
  NAPE_LINEAR_DRAG,
  useReplicaEngine,
  setReplicaEngine,
} from './nape-world';
