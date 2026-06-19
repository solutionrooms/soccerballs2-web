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

	// backing storage + the body this filter was emitted onto (null until the shape is finalized) + this
	// shape's engine add-order index (set in Shape.emit), so a live mask change targets only THIS shape.
	var _collisionMask:Int;
	@:allow(nape.shape.Shape) var _body:nape.phys.Body;
	@:allow(nape.shape.Shape) var _shapeIndex:Int = 0;

	public var collisionMask(get, set):Int;
	inline function get_collisionMask():Int
		return _collisionMask;
	function set_collisionMask(v:Int):Int {
		_collisionMask = v;
		// nape's filter is PER-SHAPE — propagate to just this shape (the keeper duck disables only its upper
		// shapes; SetBodyCollisionMask drives every shape, which is just this applied N times).
		if (_body != null) _body.runtimeSetShapeCollisionMask(_shapeIndex, v);
		return v;
	}

	public var sensorGroup:Int;

	// sensorMask is ALSO a live property: the game disables a body's sensor at runtime
	// (e.g. SetBodySensorMask(-1,0) so the returning ball doesn't trip the goal/ref sensors on its
	// way back to the player; the flying bird toggles its hit sensor). Without propagation the
	// replica keeps emitting sensor-overlap events → spurious goals (ball "times out" behind the goal).
	var _sensorMask:Int;
	public var sensorMask(get, set):Int;
	inline function get_sensorMask():Int
		return _sensorMask;
	function set_sensorMask(v:Int):Int {
		_sensorMask = v;
		if (_body != null) _body.runtimeSetSensorMask(v); // propagate live sensor-filter change to the replica
		return v;
	}

	public var fluidGroup:Int;
	public var fluidMask:Int;

	public function new(collisionGroup:Int = 1, collisionMask:Int = -1, sensorGroup:Int = 1, sensorMask:Int = -1, fluidGroup:Int = 1, fluidMask:Int = -1) {
		this.collisionGroup = collisionGroup;
		this._collisionMask = collisionMask; // bypass the setter at construction (no body yet)
		this.sensorGroup = sensorGroup;
		this._sensorMask = sensorMask; // bypass the setter at construction (no body yet)
		this.fluidGroup = fluidGroup;
		this.fluidMask = fluidMask;
	}

	public function copy():InteractionFilter
		return new InteractionFilter(collisionGroup, _collisionMask, sensorGroup, _sensorMask, fluidGroup, fluidMask);
}
