package nape.shape;

import nape.geom.AABB;
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.Material;
import nape.dynamics.InteractionFilter;
import rnape.NapeReplicaJS;

/**
 * nape.shape.Shape shim base. Holds material + filter + sensorEnabled + userData,
 * buffered until the owning Body is added to a Space (finalized). At finalize
 * `emit()` splits the shape into up to two replica shapes — a solid one (when the
 * collision filter is non-zero) and a sensor one (when the sensor filter is
 * non-zero) — exactly as the verified nape-world.ts bridge does.
 */
class Shape {
	public var material:Material;
	public var filter:InteractionFilter;
	public var sensorEnabled:Bool;
	public var userData:Dynamic;
	public var body:Body;

	function new() {
		material = new Material();
		filter = new InteractionFilter();
		sensorEnabled = false;
		userData = {data: null};
		body = null;
	}

	// Called by Body.finalize once a handle exists. `startIdx` is the engine add-order index this shape's
	// primitives start at; we record the solid primitive's index on the filter so a per-shape collisionMask
	// change (SetBodyShapeCollisionMask) targets the right engine shape. Returns the number of engine shapes
	// emitted (1 solid, +1 if it also splits into a sensor), so Body.finalize can advance the running index.
	@:allow(nape.phys.Body)
	function emit(engine:NapeReplicaJS, handle:Int, startIdx:Int):Int {
		var m = material;
		filter._body = body; // bind the filter to this body so a later collisionMask change reaches the replica
		filter._shapeIndex = startIdx; // engine index of the solid primitive (the collisionMask target)
		var count = 0;
		var hasSolid = (filter.collisionGroup != 0 && filter.collisionMask != 0);
		var hasSensor = (filter.sensorGroup != 0 && filter.sensorMask != 0);
		if (hasSolid) {
			add(engine, handle, m.density, m.dynamicFriction, m.rollingFriction, m.elasticity, filter.collisionGroup, filter.collisionMask, false);
			count++;
		}
		if (hasSensor) {
			// In real Nape a shape contributes mass (density × area) ONCE, regardless of sensorEnabled.
			// We split one nape shape into up to two replica primitives for filtering, so the mass must be
			// carried exactly once: by the solid primitive when there is one, otherwise by the sensor
			// primitive. A SENSOR-ONLY shape (col=0,0 sensor=N,N — e.g. the level-12 cannon welded into a
			// contraption) MUST still give its body mass; emitting it density-0 left the body massless →
			// fallback inertia=0 → welding it produced a NaN in the solver (caves levels rendered empty).
			add(engine, handle, hasSolid ? 0 : m.density, m.dynamicFriction, m.rollingFriction, m.elasticity, filter.sensorGroup, filter.sensorMask, true);
			count++;
		}
		return count;
	}

	// overridden by Circle / Polygon
	function add(engine:NapeReplicaJS, handle:Int, density:Float, f:Float, roll:Float, e:Float, cat:Int, mask:Int, sensor:Bool):Void {}

	// world-space verts of this shape (for bounds / debug); overridden
	function worldVertsArray():Array<Vec2>
		return [];

	public var bounds(get, never):AABB;
	function get_bounds():AABB {
		var vs = worldVertsArray();
		if (vs.length == 0) return new AABB();
		var minx = vs[0].x, maxx = vs[0].x, miny = vs[0].y, maxy = vs[0].y;
		for (v in vs) {
			if (v.x < minx) minx = v.x;
			if (v.x > maxx) maxx = v.x;
			if (v.y < miny) miny = v.y;
			if (v.y > maxy) maxy = v.y;
		}
		return new AABB(minx, miny, maxx - minx, maxy - miny);
	}

	public var worldCOM(get, never):Vec2;
	function get_worldCOM():Vec2 {
		var vs = worldVertsArray();
		if (vs.length == 0) return body != null ? body.localPointToWorld(new Vec2(0, 0)) : new Vec2();
		var cx = 0.0, cy = 0.0;
		for (v in vs) {
			cx += v.x;
			cy += v.y;
		}
		return new Vec2(cx / vs.length, cy / vs.length);
	}

	public var castCircle(get, never):Circle;
	inline function get_castCircle():Circle
		return Std.isOfType(this, Circle) ? cast this : null;

	public var castPolygon(get, never):Polygon;
	inline function get_castPolygon():Polygon
		return Std.isOfType(this, Polygon) ? cast this : null;

	public function isCircle():Bool
		return Std.isOfType(this, Circle);

	public function isPolygon():Bool
		return Std.isOfType(this, Polygon);

	// local-space area (overridden by Circle/Polygon)
	public var area(get, never):Float;
	function get_area():Float
		return 0;
}
