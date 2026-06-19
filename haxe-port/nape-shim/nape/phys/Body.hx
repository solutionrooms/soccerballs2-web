package nape.phys;

import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.shape.Shape;
import nape.shape.ShapeList;
import nape.space.Space;
import nape.dynamics.ArbiterList;
import nape.callbacks.CbTypeList;
import nape.constraint.Constraint;
import nape.constraint.ConstraintList;
import rnape.NapeReplicaJS;

/**
 * nape.phys.Body shim over a replica handle.
 *
 * Lifecycle mirrors nape: `new Body(type, pos)` → set position/rotation/velocity,
 * `shapes.add(shape)` (all buffered locally) → `space.bodies.add(body)` FINALIZES
 * (createBody + per-shape addCircle/addPolygon + finalizeBody). `space.bodies.remove`
 * destroys. Before finalize, position/rotation/velocity live in buffered fields;
 * after, they read/write through the replica handle.
 *
 * `position` and `velocity` return live PROXY Vec2s (see Vec2) so
 * `body.position.x`, `body.velocity.setxy(0,0)`, `body.velocity.y -= e` all act on
 * the real body.
 */
class Body {
	public var handle:Int = -1;
	public var debugDraw:Bool = true;
	public var userData:Dynamic;

	var _space:Space = null;
	var engine:NapeReplicaJS = null;

	// buffered pre-finalize state (radians for _rot)
	var _px:Float = 0;
	var _py:Float = 0;
	var _rot:Float = 0;
	var _vx:Float = 0;
	var _vy:Float = 0;
	var _angVel:Float = 0;
	var _type:BodyType;
	var _shapes:ShapeList;
	var _constraintList:ConstraintList;
	var _surfaceVel:Vec2;

	public function new(?type:BodyType, ?position:Vec2) {
		_type = type != null ? type : BodyType.DYNAMIC;
		_shapes = new ShapeList();
		_constraintList = new ConstraintList();
		_surfaceVel = new Vec2(0, 0);
		userData = {data: null};
		if (position != null) {
			_px = position.x;
			_py = position.y;
		}
	}

	// World-body constructor (replica handle 0 is the static world body).
	@:allow(nape.space.Space)
	static function worldBody(sp:Space, eng:NapeReplicaJS):Body {
		var b = new Body(BodyType.STATIC);
		b._space = sp;
		b.engine = eng;
		b.handle = 0;
		return b;
	}

	// ---- finalize / destroy (called by BodyList add/remove) ----
	@:allow(nape.phys.BodyList)
	function finalize(sp:Space):Void {
		if (handle >= 0) return; // already finalized
		_space = sp;
		engine = sp.engine;
		var isStatic = (_type == BodyType.STATIC);
		handle = engine.createBody(isStatic, _px, _py, _rot * 180 / Math.PI, 0, 0);
		var engShapeIdx = 0; // running engine add-order index, so each shape records its own
		for (sh in _shapes) {
			sh.body = this;
			engShapeIdx += sh.emit(engine, handle, engShapeIdx);
		}
		engine.finalizeBody(handle, false); // game never sets isBullet → no CCD flag
		if (_type == BodyType.KINEMATIC) engine.setBodyType(handle, 2);
		if (_vx != 0 || _vy != 0) engine.setVel(handle, _vx, _vy);
		if (_angVel != 0) engine.setAngVel(handle, _angVel);
		sp.register(handle, this);
	}

	@:allow(nape.phys.BodyList)
	function destroy():Void {
		if (handle < 0 || engine == null) return;
		_space.unregister(handle);
		engine.destroyBody(handle);
		handle = -1;
	}

	// ---- proxy bridge for position/velocity Vec2 (kind: 0=pos, 1=vel) ----
	@:allow(nape.geom.Vec2)
	function prxGet(kind:Int, axis:Int):Float {
		if (kind == 0)
			return axis == 0 ? (handle < 0 ? _px : engine.getX(handle)) : (handle < 0 ? _py : engine.getY(handle));
		else
			return axis == 0 ? (handle < 0 ? _vx : engine.getVX(handle)) : (handle < 0 ? _vy : engine.getVY(handle));
	}

	@:allow(nape.geom.Vec2)
	function prxSetXY(kind:Int, x:Float, y:Float):Void {
		if (kind == 0) {
			_px = x;
			_py = y;
			if (handle >= 0) engine.setTransform(handle, x, y, rotationDeg());
		} else {
			_vx = x;
			_vy = y;
			if (handle >= 0) engine.setVel(handle, x, y);
		}
	}

	inline function rotationDeg():Float
		return (handle < 0 ? _rot : engine.getRotRad(handle)) * 180 / Math.PI;

	// ---- properties ----
	public var position(get, set):Vec2;
	inline function get_position():Vec2
		return Vec2.bound(this, 0);
	function set_position(v:Vec2):Vec2 {
		prxSetXY(0, v.x, v.y);
		return v;
	}

	public var velocity(get, set):Vec2;
	inline function get_velocity():Vec2
		return Vec2.bound(this, 1);
	function set_velocity(v:Vec2):Vec2 {
		prxSetXY(1, v.x, v.y);
		return v;
	}

	public var rotation(get, set):Float;
	inline function get_rotation():Float
		return handle < 0 ? _rot : engine.getRotRad(handle);
	function set_rotation(r:Float):Float {
		_rot = r;
		if (handle >= 0) engine.setTransform(handle, engine.getX(handle), engine.getY(handle), r * 180 / Math.PI);
		return r;
	}

	public var angularVel(get, set):Float;
	inline function get_angularVel():Float
		return handle < 0 ? _angVel : engine.getAngVel(handle);
	function set_angularVel(w:Float):Float {
		_angVel = w;
		if (handle >= 0) engine.setAngVel(handle, w);
		return w;
	}

	public var type(get, set):BodyType;
	inline function get_type():BodyType
		return _type;
	function set_type(t:BodyType):BodyType {
		_type = t;
		if (handle >= 0) engine.setBodyType(handle, t.code);
		return t;
	}

	// Live collision-mask change from a shape's filter (e.g. SetBodyCollisionMask → switchable block
	// disappears). Pushes to the replica; guarded so an older bundle without the method is a safe no-op.
	@:allow(nape.dynamics.InteractionFilter)
	function runtimeSetCollisionMask(mask:Int):Void {
		if (handle >= 0 && engine != null && (untyped engine.setBodyCollisionMask) != null)
			engine.setBodyCollisionMask(handle, mask);
	}

	// Live sensor-mask change from a shape's filter (e.g. SetBodySensorMask(-1,0) so the returning
	// ball stops tripping the goal sensor). Events-only on the replica side; guarded for older bundles.
	@:allow(nape.dynamics.InteractionFilter)
	function runtimeSetSensorMask(mask:Int):Void {
		if (handle >= 0 && engine != null && (untyped engine.setBodySensorMask) != null)
			engine.setBodySensorMask(handle, mask);
	}

	// Live PER-SHAPE collision-mask change (SetBodyShapeCollisionMask — keeper duck disables only its upper
	// shapes). `shapeIdx` is the engine add-order index recorded in Shape.emit. Falls back to the body-wide
	// setter on older bundles (so an all-shapes SetBodyCollisionMask still propagates); when every shape is
	// set to the same mask that fallback is equivalent.
	@:allow(nape.dynamics.InteractionFilter)
	function runtimeSetShapeCollisionMask(shapeIdx:Int, mask:Int):Void {
		if (handle < 0 || engine == null) return;
		if ((untyped engine.setShapeCollisionMask) != null)
			engine.setShapeCollisionMask(handle, shapeIdx, mask);
		else if ((untyped engine.setBodyCollisionMask) != null)
			engine.setBodyCollisionMask(handle, mask);
	}

	public var mass(get, never):Float;
	inline function get_mass():Float
		return handle < 0 ? 0 : engine.getMass(handle);

	public var inertia(get, never):Float;
	inline function get_inertia():Float
		return handle < 0 ? 0 : engine.getInertia(handle);

	public var shapes(get, never):ShapeList;
	inline function get_shapes():ShapeList
		return _shapes;

	public var space(get, set):Space;
	inline function get_space():Space
		return _space;
	function set_space(s:Space):Space {
		if (s == null) {
			if (handle >= 0) destroy();
		} else if (handle < 0) {
			s.bodies.add(this); // nape's `body.space = space` finalizes
		}
		return s;
	}

	public var arbiters(get, never):ArbiterList;
	inline function get_arbiters():ArbiterList
		return new ArbiterList();

	public var constraints(get, never):ConstraintList;
	inline function get_constraints():ConstraintList
		return _constraintList;

	@:allow(nape.constraint.Constraint)
	function addConstraint(c:Constraint):Void
		_constraintList.push(c);

	// Conveyor surface velocity. NOTE: the replica has no surface-velocity support,
	// so this is stored but does not drive the engine — conveyors won't convey.
	public var surfaceVel(get, set):Vec2;
	inline function get_surfaceVel():Vec2
		return _surfaceVel;
	function set_surfaceVel(v:Vec2):Vec2 {
		_surfaceVel = v;
		return v;
	}

	public var cbTypes(get, never):CbTypeList;
	inline function get_cbTypes():CbTypeList
		return CbTypeList.shared();

	public var worldCOM(get, never):Vec2;
	function get_worldCOM():Vec2
		return new Vec2(handle < 0 ? _px : engine.getX(handle), handle < 0 ? _py : engine.getY(handle));

	public function isStatic():Bool
		return _type == BodyType.STATIC;

	public function isDynamic():Bool
		return _type == BodyType.DYNAMIC;

	public function isKinematic():Bool
		return _type == BodyType.KINEMATIC;

	public function applyImpulse(impulse:Vec2, ?pos:Vec2, sleepable:Bool = false):Void {
		if (handle >= 0) engine.applyImpulse(handle, impulse.x, impulse.y);
	}

	public function contains(point:Vec2):Bool
		return handle < 0 ? false : engine.bodyContains(handle, point.x, point.y);

	public function worldPointToLocal(p:Vec2, weak:Bool = false):Vec2 {
		var px = handle < 0 ? _px : engine.getX(handle);
		var py = handle < 0 ? _py : engine.getY(handle);
		var rot = get_rotation();
		var c = Math.cos(rot), s = Math.sin(rot);
		var dx = p.x - px, dy = p.y - py;
		return new Vec2(c * dx + s * dy, -s * dx + c * dy);
	}

	public function localPointToWorld(p:Vec2, weak:Bool = false):Vec2 {
		var px = handle < 0 ? _px : engine.getX(handle);
		var py = handle < 0 ? _py : engine.getY(handle);
		var rot = get_rotation();
		var c = Math.cos(rot), s = Math.sin(rot);
		return new Vec2(px + c * p.x - s * p.y, py + s * p.x + c * p.y);
	}

	// kinematic movers (switch-driven platforms): set velocity to reach a target
	// pose over dt — drives the replica kinematic body.
	public function setVelocityFromTarget(targetPosition:Vec2, targetRotation:Float, deltaTime:Float):Void {
		if (handle < 0 || deltaTime == 0) return;
		var px = engine.getX(handle), py = engine.getY(handle);
		engine.setVel(handle, (targetPosition.x - px) / deltaTime, (targetPosition.y - py) / deltaTime);
		var dRot = targetRotation - engine.getRotRad(handle);
		engine.setAngVel(handle, dRot / deltaTime);
	}

	// total normal impulse between this body and `other` from the latest step
	// (crate-break threshold). Direction = contact normal, magnitude = |Σ jnAcc|.
	public function normalImpulse(?other:Body, freshOnly:Bool = false):Vec3 {
		if (_space == null || other == null) return new Vec3(0, 0, 0);
		return _space.impulseBetween(handle, other.handle);
	}
}
