package nape.dynamics;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.geom.Vec3;

/**
 * nape.dynamics.Contact shim — one contact point of a collision arbiter. The game
 * stores it (hitContactPoint_Nape) but mostly reads nothing back; position/normal
 * are approximated from the replica's per-pair impact (point not available).
 */
class Contact {
	public var position(default, null):Vec2;
	public var penetration(default, null):Float;
	public var fresh(default, null):Bool;
	public var friction(default, null):Float;
	public var arbiter(default, null):CollisionArbiter;

	var _j:Float;
	var _nx:Float;
	var _ny:Float;

	public function new(position:Vec2, j:Float = 0, nx:Float = 0, ny:Float = 0, fresh:Bool = true) {
		this.position = position;
		this.penetration = 0;
		this.fresh = fresh;
		this.friction = 0;
		_j = j;
		_nx = nx;
		_ny = ny;
	}

	@:allow(nape.dynamics.CollisionArbiter)
	function setArbiter(a:CollisionArbiter):Void
		arbiter = a;

	public function normalImpulse(?body:Body):Vec3
		return new Vec3(_nx * _j, _ny * _j, 0);
}
