package nape.dynamics;

import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.phys.Body;
import nape.shape.Shape;

/**
 * nape.dynamics.CollisionArbiter shim (extends Arbiter, as in nape). Synthesized
 * per BEGIN collision pair from the replica's impact event ([hA,hB,|j|,nx,ny]).
 * Carries the contact, the contact normal and total normal impulse.
 * dynamicFriction etc. are diagnostic (ProbeLog, disabled) so left at defaults.
 */
class CollisionArbiter extends Arbiter {
	public var contacts(default, null):ContactList;
	public var normal(default, null):Vec2;
	public var radius(default, null):Float;
	public var elasticity:Float;
	public var dynamicFriction:Float;
	public var staticFriction:Float;
	public var rollingFriction:Float;

	var _j:Float;
	var _nx:Float;
	var _ny:Float;

	public function new(body1:Body, body2:Body, shape1:Shape, shape2:Shape, j:Float, nx:Float, ny:Float, contactPos:Vec2) {
		super(body1, body2, shape1, shape2, false);
		_j = j;
		_nx = nx;
		_ny = ny;
		normal = new Vec2(nx, ny);
		contacts = new ContactList();
		var ct = new Contact(contactPos, j, nx, ny);
		ct.setArbiter(this);
		contacts.push(ct);
		radius = 0;
		elasticity = 0;
		dynamicFriction = 0;
		staticFriction = 0;
		rollingFriction = 0;
	}

	public function normalImpulse(?body:Body, freshOnly:Bool = false):Vec3
		return new Vec3(_nx * _j, _ny * _j, 0);

	public function tangentImpulse(?body:Body, freshOnly:Bool = false):Vec3
		return new Vec3(0, 0, 0);

	public function rollingImpulse(?body:Body, freshOnly:Bool = false):Float
		return 0;
}
