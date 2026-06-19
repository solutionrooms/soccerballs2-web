package nape.space;

import nape.geom.Vec2;
import nape.geom.Vec3;
import nape.phys.Body;
import nape.phys.BodyList;
import nape.constraint.ConstraintList;
import nape.callbacks.ListenerList;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionType;
import nape.callbacks.InteractionCallback;
import nape.dynamics.Arbiter;
import nape.dynamics.ArbiterList;
import nape.dynamics.CollisionArbiter;
import nape.dynamics.InteractionFilter;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.shape.Shape;
import rnape.NapeReplicaJS;

typedef ImpactRec = {j:Float, nx:Float, ny:Float};

/**
 * nape.space.Space shim. Wraps one replica engine instance. `bodies.add` /
 * `constraints.add` finalize bodies/joints into the engine; `step` advances the
 * engine then drains its per-step contact/sensor/impact events and dispatches them
 * to the registered InteractionListeners (the four the game adds: BEGIN/ONGOING ×
 * COLLISION/SENSOR). BEGIN comes from engine.takeContacts(); ONGOING from
 * engine.takeOngoing() (pairs persisting this step while awake — drives
 * onHitPersistFunction: wind, weight-switch).
 */
class Space {
	@:allow(nape.phys.Body)
	@:allow(nape.constraint.Constraint)
	@:allow(nape.constraint.PivotJoint)
	@:allow(nape.constraint.WeldJoint)
	@:allow(nape.constraint.DistanceJoint)
	@:allow(nape.constraint.MotorJoint)
	@:allow(nape.constraint.AngleJoint)
	var engine:NapeReplicaJS;

	var _gravityY:Float;
	var _bodies:BodyList;
	var _constraints:ConstraintList;
	var _listeners:ListenerList;
	var _world:Body;
	var _byHandle:Map<Int, Body>;
	var _impulse:Map<String, ImpactRec>;

	public var userData:Dynamic;

	public function new(?gravity:Vec2, ?broadphase:Dynamic) {
		_gravityY = gravity != null ? gravity.y : 0;
		engine = new NapeReplicaJS(_gravityY);
		_bodies = BodyList.forSpace(this);
		_constraints = ConstraintList.forSpace(this);
		_listeners = new ListenerList();
		_byHandle = new Map();
		_impulse = new Map();
		_world = Body.worldBody(this, engine);
		userData = {data: null};
	}

	public var gravity(get, set):Vec2;
	inline function get_gravity():Vec2
		return new Vec2(0, _gravityY);
	function set_gravity(v:Vec2):Vec2 {
		_gravityY = v.y;
		engine.setGravity(v.y);
		return v;
	}

	public var bodies(get, never):BodyList;
	inline function get_bodies():BodyList
		return _bodies;

	public var constraints(get, never):ConstraintList;
	inline function get_constraints():ConstraintList
		return _constraints;

	public var listeners(get, never):ListenerList;
	inline function get_listeners():ListenerList
		return _listeners;

	public var world(get, never):Body;
	inline function get_world():Body
		return _world;

	// Nape library default drag (never overridden by the game); read by the
	// ball-path preview. Stored so a set doesn't error, but does not drive the
	// engine (the replica applies the global 0.015 drag itself).
	var _worldLinearDrag:Float = 0.015;
	public var worldLinearDrag(get, set):Float;
	inline function get_worldLinearDrag():Float
		return _worldLinearDrag;
	inline function set_worldLinearDrag(v:Float):Float
		return _worldLinearDrag = v;

	var _worldAngularDrag:Float = 0.015;
	public var worldAngularDrag(get, set):Float;
	inline function get_worldAngularDrag():Float
		return _worldAngularDrag;
	inline function set_worldAngularDrag(v:Float):Float
		return _worldAngularDrag = v;

	/**
	 * Downward floor raycast → replica.raycastDown. The game casts axis-aligned
	 * rays: down (0,1) for character floor-snap (supported) and up (0,-1) for the
	 * cosmetic grass-occlusion test (unsupported by the replica → returns null,
	 * leaving the grass visible — a harmless visual nit, not gameplay).
	 */
	public function rayCast(ray:Ray, inner:Bool = false, ?filter:InteractionFilter):Null<RayResult> {
		if (ray.direction.y <= 0) return null; // up / horizontal rays unsupported
		var colCat = filter != null ? filter.collisionGroup : 1;
		var hitY = engine.raycastDown(ray.origin.x, ray.origin.y, ray.maxDistance, colCat);
		if (Math.isNaN(hitY)) return null;
		return new RayResult(hitY - ray.origin.y); // direction (0,1): distance == Δy
	}

	// handle -> shim Body, for contact dispatch (set at finalize / cleared at destroy)
	@:allow(nape.phys.Body)
	function register(h:Int, b:Body):Void
		_byHandle.set(h, b);

	@:allow(nape.phys.Body)
	function unregister(h:Int):Void
		_byHandle.remove(h);

	// total normal impulse between two bodies from the latest step (crate break)
	@:allow(nape.phys.Body)
	function impulseBetween(hA:Int, hB:Int):Vec3 {
		var imp = _impulse.get(pairKey(hA, hB));
		if (imp == null) return new Vec3(0, 0, 0);
		return new Vec3(imp.nx * imp.j, imp.ny * imp.j, 0);
	}

	public function step(deltaTime:Float, velocityIterations:Int = 10, positionIterations:Int = 10):Void {
		engine.step(deltaTime, velocityIterations, positionIterations);
		dispatchEvents();
	}

	public function clear():Void {
		_bodies.clear();
		_byHandle = new Map();
		_impulse = new Map();
	}

	inline function pairKey(a:Int, b:Int):String
		return a < b ? a + "_" + b : b + "_" + a;

	function dispatchEvents():Void {
		// impulses first, so normalImpulse() lookups inside handlers are valid
		_impulse = new Map();
		var im = engine.takeImpacts(); // [hA,hB,|j|,nx,ny, ...]
		var i = 0;
		while (i + 4 < im.length) {
			var ha = Std.int(im[i]);
			var hb = Std.int(im[i + 1]);
			_impulse.set(pairKey(ha, hb), {j: im[i + 2], nx: im[i + 3], ny: im[i + 4]});
			i += 5;
		}

		// Drain BOTH buffers every step (even with no listeners) so they don't accumulate.
		var cs = engine.takeContacts(); // BEGIN  [hA,hB,sensorFlag, ...]
		var og = engine.takeOngoing();  // ONGOING (pairs persisting this step while awake)
		if (_listeners.length == 0) return;
		var j = 0;
		while (j + 2 < cs.length) {
			dispatchPair(cs[j], cs[j + 1], cs[j + 2] == 1, CbEvent.BEGIN);
			j += 3;
		}
		j = 0;
		while (j + 2 < og.length) {
			dispatchPair(og[j], og[j + 1], og[j + 2] == 1, CbEvent.ONGOING); // drives onHitPersistFunction (weight-switch, wind)
			j += 3;
		}
	}

	function dispatchPair(ha:Int, hb:Int, sensor:Bool, event:CbEvent):Void {
		var ba = _byHandle.get(ha);
		var bb = _byHandle.get(hb);
		if (ba == null || bb == null) return;

		var s1:Shape = ba.shapes.length > 0 ? ba.shapes.at(0) : null;
		var s2:Shape = bb.shapes.length > 0 ? bb.shapes.at(0) : null;
		var arb:Arbiter;
		if (sensor) {
			arb = new Arbiter(ba, bb, s1, s2, true);
		} else {
			var imp = _impulse.get(pairKey(ha, hb));
			var jmag = imp != null ? imp.j : 0.0;
			var nx = imp != null ? imp.nx : 0.0;
			var ny = imp != null ? imp.ny : 0.0;
			arb = new CollisionArbiter(ba, bb, s1, s2, jmag, nx, ny, new Vec2(ba.position.x, ba.position.y));
		}
		var arbs = new ArbiterList();
		arbs.add(arb);
		var cb = new InteractionCallback(ba, bb, arbs);

		for (l in _listeners) {
			if (l.event != event) continue; // dispatch only listeners for this event (BEGIN / ONGOING)
			var wantSensor = (l.interactionType == InteractionType.SENSOR);
			if (wantSensor == sensor) l.handler(cb);
		}
	}
}
