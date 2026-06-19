package nape.dynamics;

/**
 * nape.dynamics.InteractionFilter shim — category/mask bits for collision and
 * sensor interactions. The game builds these as
 * `new InteractionFilter(collisionCategory, collisionMask, sensorCategory, sensorMask)`
 * and the shim's shapes read collisionGroup/collisionMask (solid) and
 * sensorGroup/sensorMask (sensor) at finalize to feed the replica.
 *
 * `collisionMask` is a live property: when the game mutates it after the owning shape has been
 * finalized into a replica body (e.g. SetBodyCollisionMask making a switchable block "disappear"),
 * the change is pushed through to the replica via the body's handle — nape keeps the broadphase
 * filter live, the replica gets its copy at addPolygon time, so without this the change is silent.
 */
class InteractionFilter {
	public var collisionGroup:Int;

	// backing storage + the body this filter was emitted onto (null until the shape is finalized).
	var _collisionMask:Int;
	@:allow(nape.shape.Shape) var _body:nape.phys.Body;

	public var collisionMask(get, set):Int;
	inline function get_collisionMask():Int
		return _collisionMask;
	function set_collisionMask(v:Int):Int {
		_collisionMask = v;
		if (_body != null) _body.runtimeSetCollisionMask(v); // propagate live filter change to the replica
		return v;
	}

	public var sensorGroup:Int;
	public var sensorMask:Int;
	public var fluidGroup:Int;
	public var fluidMask:Int;

	public function new(collisionGroup:Int = 1, collisionMask:Int = -1, sensorGroup:Int = 1, sensorMask:Int = -1, fluidGroup:Int = 1, fluidMask:Int = -1) {
		this.collisionGroup = collisionGroup;
		this._collisionMask = collisionMask; // bypass the setter at construction (no body yet)
		this.sensorGroup = sensorGroup;
		this.sensorMask = sensorMask;
		this.fluidGroup = fluidGroup;
		this.fluidMask = fluidMask;
	}

	public function copy():InteractionFilter
		return new InteractionFilter(collisionGroup, _collisionMask, sensorGroup, sensorMask, fluidGroup, fluidMask);
}
