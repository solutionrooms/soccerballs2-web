package nape.dynamics;

import nape.geom.Vec3;
import nape.phys.Body;
import nape.shape.Shape;

/**
 * nape.dynamics.Arbiter shim — base for the synthesized per-pair arbiter.
 * Collision pairs are CollisionArbiter (a subclass, matching nape); sensor pairs
 * are a plain Arbiter with the sensor flag set.
 */
class Arbiter {
	public var body1(default, null):Body;
	public var body2(default, null):Body;
	public var shape1(default, null):Shape;
	public var shape2(default, null):Shape;

	var _sensor:Bool;

	public function new(body1:Body, body2:Body, shape1:Shape, shape2:Shape, sensor:Bool = false) {
		this.body1 = body1;
		this.body2 = body2;
		this.shape1 = shape1;
		this.shape2 = shape2;
		_sensor = sensor;
	}

	public function isCollisionArbiter():Bool
		return Std.isOfType(this, CollisionArbiter);

	public function isSensorArbiter():Bool
		return _sensor;

	public function isFluidArbiter():Bool
		return false;

	public var collisionArbiter(get, never):CollisionArbiter;
	inline function get_collisionArbiter():CollisionArbiter
		return Std.isOfType(this, CollisionArbiter) ? cast this : null;

	public function totalImpulse(?body:Body, freshOnly:Bool = false):Vec3 {
		var ca = get_collisionArbiter();
		return ca != null ? ca.normalImpulse(body, freshOnly) : new Vec3(0, 0, 0);
	}
}
