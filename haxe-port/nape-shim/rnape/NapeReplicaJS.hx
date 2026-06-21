package rnape;

/**
 * Haxe extern binding to the bundled, UNCHANGED TypeScript replica
 * (src/physics/replica/nape-core.ts → nape-replica.js, global `NapeReplica`).
 *
 * This is the bit-exact hand-port of the ORIGINAL game's Nape. The Haxe game
 * never calls this directly — the `nape.*` shim classes (Body/Space/Vec2/…)
 * wrap it to present the same nape-haxe4 API the game already uses, so under
 * `-D replica` the engine is swapped with no game-code changes.
 *
 * All units are PIXELS (the replica runs in pixels, like the original).
 * Handle 0 is the static world body (joints attach to "the world").
 */
@:native("NapeReplica")
extern class NapeReplicaJS {
	public function new(gravityPxY:Float);

	public function setGravity(gpxY:Float):Void;

	// --- construction (handle-based) ---
	public function createBody(isStatic:Bool, x:Float, y:Float, rotDeg:Float, linDamp:Float, angDamp:Float):Int;
	public function addCircle(h:Int, posX:Float, posY:Float, radius:Float, density:Float, friction:Float, rolling:Float, elasticity:Float, colCat:Int, colMask:Int, isSensor:Bool):Void;
	public function addPolygon(h:Int, vertsFlat:Array<Float>, density:Float, friction:Float, rolling:Float, elasticity:Float, colCat:Int, colMask:Int, isSensor:Bool):Void;
	public function finalizeBody(h:Int, bullet:Bool):Void;
	public function destroyBody(h:Int):Void;

	// Runtime filter update: set the collision mask on every non-sensor shape of body h. Used by the
	// game's SetBodyCollisionMask (e.g. switchable blocks "disappearing"). Must drop already-touching
	// pairs that no longer collide and wake the affected bodies. (May be absent on older bundles — the
	// shim guards the call.)
	public function setBodyCollisionMask(h:Int, mask:Int):Void;
	public function setShapeCollisionMask(h:Int, shapeIdx:Int, mask:Int):Void; // per-shape (keeper duck)
	public function setBodySensorMask(h:Int, mask:Int):Void;

	// --- step ---
	public function step(dt:Float, velIters:Int, posIters:Int):Void;

	// --- readouts ---
	public function getX(h:Int):Float;
	public function getY(h:Int):Float;
	public function getRot(h:Int):Float; // degrees
	public function getRotRad(h:Int):Float;
	public function getVX(h:Int):Float;
	public function getVY(h:Int):Float;
	public function getAngVel(h:Int):Float;
	public function getMass(h:Int):Float;
	public function getInertia(h:Int):Float;
	public function isDynamic(h:Int):Bool;

	// --- body ops ---
	public function setVel(h:Int, vx:Float, vy:Float):Void;
	public function setAngVel(h:Int, w:Float):Void;
	public function setTransform(h:Int, x:Float, y:Float, rotDeg:Float):Void;
	public function setBodyType(h:Int, type:Int):Void; // 0=static,1=dynamic,2=kinematic
	public function setAwake(h:Int, awake:Bool):Void;
	public function applyImpulse(h:Int, jx:Float, jy:Float):Void;
	public function wakeJointPartners(h:Int):Void;
	public function setBodyCollision(h:Int, enabled:Bool):Void;
	public function setBodyCollisionAboveTop(h:Int, topThresholdPx:Float, enabled:Bool):Void;

	// --- queries ---
	public function bodyContains(h:Int, x:Float, y:Float):Bool;
	public function bodyArea(h:Int):Float;
	public function touchingBodies(h:Int):Array<Int>;
	public function raycastDown(x:Float, fromY:Float, maxDist:Float, colCat:Int):Float; // NaN if no hit

	// --- joints (world anchors; handle 0 == world) ---
	public function jointRev(hA:Int, hB:Int, ax:Float, ay:Float, enableMotor:Bool, motorSpeed:Float, maxTorque:Float, enableLimit:Bool, lowerRad:Float, upperRad:Float):Void;
	public function jointWeld(hA:Int, hB:Int, soft:Bool, freq:Float):Void;
	public function jointDist(hA:Int, hB:Int, x0:Float, y0:Float, x1:Float, y1:Float, distLimit:Float, soft:Bool, freq:Float):Void;

	// --- events (drained per step) ---
	public function takeContacts():Array<Int>; // [hA,hB,sensorFlag, ...] — BEGIN (newly-touching) pairs
	public function takeOngoing():Array<Int>;  // [hA,hB,sensorFlag, ...] — pairs persisting this step while AWAKE (ONGOING)
	public function takeImpacts():Array<Float>; // [hA,hB,|normalImpulse|,nx,ny, ...]
	// Faithful Nape Body.normalImpulse(other) about `ref`: [x,y,z], SUMMED over every arbiter/contact of
	// the ref↔other body-pair (multi-shape bodies make >1 arbiter). The crate-break query MUST use this,
	// not the per-pair _impulse map (which overwrites and drops all but one arbiter — lvl-9 break bug).
	public function normalImpulse(ref:Int, other:Int):Array<Float>;
}
