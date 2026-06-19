package nape.shape;

import nape.geom.Vec2;
import nape.geom.Vec2List;
import nape.geom.GeomPoly;
import nape.phys.Material;
import nape.dynamics.InteractionFilter;
import rnape.NapeReplicaJS;

/**
 * nape.shape.Polygon shim. Built from an Array<Vec2>, a Vec2List or a GeomPoly
 * (the terrain path passes a triangle GeomPoly; object paths pass Array<Vec2>).
 * The replica takes CONVEX pieces only, so callers must feed convex polygons
 * (terrain is pre-triangulated; object shapes are pre-triangulated by the game's
 * own Triangulate). Verts are body-local pixels.
 */
class Polygon extends Shape {
	var _verts:Array<Vec2>;

	public function new(localVerts:Dynamic, ?material:Material, ?filter:InteractionFilter) {
		super();
		_verts = extract(localVerts);
		if (material != null) this.material = material;
		if (filter != null) this.filter = filter;
	}

	static function extract(v:Dynamic):Array<Vec2> {
		var out:Array<Vec2> = [];
		if (v == null) return out;
		if (Std.isOfType(v, GeomPoly)) {
			var g:GeomPoly = cast v;
			for (i in 0...g.size()) {
				var p = g._verts[i];
				out.push(new Vec2(p.x, p.y));
			}
		} else if (Std.isOfType(v, Vec2List)) {
			var l:Vec2List = cast v;
			for (i in 0...l.length) out.push(new Vec2(l.at(i).x, l.at(i).y));
		} else {
			// Array<Vec2> (or array of {x,y}). `p` is Dynamic, so a raw `p.x` read bypasses the
			// shim Vec2's property getter (storage _vx/_vy) → undefined → defaulted to 0, which
			// would collapse every vertex to (0,0). Route Vec2 through its getter.
			var a:Array<Dynamic> = cast v;
			for (p in a) {
				if (Std.isOfType(p, Vec2)) {
					var vp:Vec2 = cast p;
					out.push(new Vec2(vp.x, vp.y));
				} else {
					out.push(new Vec2(p.x, p.y));
				}
			}
		}
		return out;
	}

	public var localVerts(get, never):Vec2List;
	function get_localVerts():Vec2List
		return Vec2List.fromArray(_verts);

	public var worldVerts(get, never):Vec2List;
	function get_worldVerts():Vec2List
		return Vec2List.fromArray(worldVertsArray());

	override function get_area():Float {
		var a = 0.0;
		var n = _verts.length;
		for (i in 0...n) {
			var p = _verts[i];
			var q = _verts[(i + 1) % n];
			a += p.x * q.y - q.x * p.y;
		}
		return Math.abs(a) * 0.5;
	}

	override function add(engine:NapeReplicaJS, handle:Int, density:Float, f:Float, roll:Float, e:Float, cat:Int, mask:Int, sensor:Bool):Void {
		var flat:Array<Float> = [];
		for (v in _verts) {
			flat.push(v.x);
			flat.push(v.y);
		}
		engine.addPolygon(handle, flat, density, f, roll, e, cat, mask, sensor);
	}

	override function worldVertsArray():Array<Vec2> {
		var out:Array<Vec2> = [];
		for (v in _verts) out.push(body != null ? body.localPointToWorld(v) : new Vec2(v.x, v.y));
		return out;
	}
}
