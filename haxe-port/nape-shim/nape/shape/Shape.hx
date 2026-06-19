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

	// Called by Body.finalize once a handle exists.
	@:allow(nape.phys.Body)
	function emit(engine:NapeReplicaJS, handle:Int):Void {
		var m = material;
		filter._body = body; // bind the filter to this body so a later collisionMask change reaches the replica
		if (filter.collisionGroup != 0 && filter.collisionMask != 0)
			add(engine, handle, m.density, m.dynamicFriction, m.rollingFriction, m.elasticity, filter.collisionGroup, filter.collisionMask, false);
		if (filter.sensorGroup != 0 && filter.sensorMask != 0)
			add(engine, handle, 0, m.dynamicFriction, m.rollingFriction, m.elasticity, filter.sensorGroup, filter.sensorMask, true);
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
