package nape.constraint;

import nape.space.Space;
import nape.geom.Vec3;
import nape.phys.Body;
import rnape.NapeReplicaJS;

/**
 * nape.constraint.Constraint shim base.
 *
 * Joints are created once (when added to `space.constraints`) and routed to the
 * replica's jointRev/jointWeld/jointDist. NOTE: the replica has no post-creation
 * joint mutation and no joint-pair collision-ignore; runtime setters here store
 * values but don't re-push to the engine, and `ignore` (collide_joined) is not
 * forwarded. The shipped levels' rev joints are passive pure pivots, so this is
 * sufficient for them; revisit if a level animates a joint.
 */
class Constraint {
	public var ignore:Bool = false;
	public var stiff:Bool = true;
	public var frequency:Float = 0;
	public var damping:Float = 1;
	public var maxForce:Float = Math.POSITIVE_INFINITY;
	public var maxError:Float = Math.POSITIVE_INFINITY;
	public var active:Bool = true;
	public var breakUnderForce:Bool = false;
	public var breakUnderError:Bool = false;
	public var removeOnBreak:Bool = true;
	public var debugDraw:Bool = true;
	public var userData:Dynamic;

	var _space:Space = null;
	var _engine:NapeReplicaJS = null;

	function new()
		userData = {data: null};

	public var space(get, set):Space;
	inline function get_space():Space
		return _space;
	function set_space(s:Space):Space {
		if (s != null && _space == null) s.constraints.add(this);
		return s;
	}

	public var isSleeping(get, never):Bool;
	inline function get_isSleeping():Bool
		return false;

	public function bodyImpulse(body:Body):Vec3
		return new Vec3(0, 0, 0);

	public function visitBodies(lambda:Body->Void):Void {}

	// overridden by each joint type: push the joint to the replica.
	@:allow(nape.constraint.ConstraintList)
	function finalize(sp:Space):Void {
		_space = sp;
		_engine = sp.engine;
	}

	// register this constraint on its bodies so body.constraints reflects it
	// (WakeWeldedBodies iterates body.constraints to wake welded riders).
	function attach(b1:Body, b2:Body):Void {
		if (b1 != null) b1.addConstraint(this);
		if (b2 != null) b2.addConstraint(this);
	}
}
