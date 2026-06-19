package nape.geom;

/**
 * nape.geom.GeomPoly shim.
 *
 * The game uses this ONLY for static terrain: build a GeomPoly from the (centred)
 * outline points, then `triangularDecomposition()` to split the possibly-concave
 * loop into triangles, one Polygon per triangle (the replica takes convex pieces
 * only — it does not decompose internally). `isConvex()` is queried but unused.
 *
 * Triangulation is the classic ear-clipping algorithm (same result-shape as the
 * game's own `Triangulate` used for object shapes); any valid non-overlapping
 * cover is physically equivalent.
 */
class GeomPoly {
	@:allow(nape) var _verts:Array<Vec2>;

	public function new(vertices:Dynamic = null) {
		_verts = [];
		if (vertices == null) return;
		if (Std.isOfType(vertices, GeomPoly)) {
			for (v in (cast vertices : GeomPoly)._verts) _verts.push(new Vec2(v.x, v.y));
		} else if (Std.isOfType(vertices, Vec2List)) {
			var l:Vec2List = cast vertices;
			for (i in 0...l.length) _verts.push(new Vec2(l.at(i).x, l.at(i).y));
		} else {
			// Array<Vec2> (or array of {x,y}). NB: `p` is Dynamic here, so a raw `p.x` read
			// BYPASSES the shim Vec2's x/y property getter (storage is _vx/_vy) → undefined →
			// Haxe defaults it to 0, collapsing every vertex to (0,0). Route Vec2 through its
			// getter; plain {x,y} objects keep the direct field read.
			var a:Array<Dynamic> = cast vertices;
			for (p in a) {
				if (Std.isOfType(p, Vec2)) {
					var v:Vec2 = cast p;
					_verts.push(new Vec2(v.x, v.y));
				} else {
					_verts.push(new Vec2(p.x, p.y));
				}
			}
		}
	}

	public function size():Int
		return _verts.length;

	public function push(v:Vec2):GeomPoly {
		_verts.push(new Vec2(v.x, v.y));
		return this;
	}

	public function copy():GeomPoly {
		var g = new GeomPoly();
		for (v in _verts) g._verts.push(new Vec2(v.x, v.y));
		return g;
	}

	public function area():Float
		return Math.abs(signedArea(_verts));

	public function winding():Int
		return signedArea(_verts) >= 0 ? 1 : -1;

	public function isConvex():Bool {
		var n = _verts.length;
		if (n < 3) return false;
		var sign = 0;
		for (i in 0...n) {
			var a = _verts[i];
			var b = _verts[(i + 1) % n];
			var c = _verts[(i + 2) % n];
			var cross = (b.x - a.x) * (c.y - b.y) - (b.y - a.y) * (c.x - b.x);
			if (cross != 0) {
				var s = cross > 0 ? 1 : -1;
				if (sign == 0) sign = s;
				else if (s != sign) return false;
			}
		}
		return true;
	}

	public function triangularDecomposition(?output:GeomPolyList):GeomPolyList {
		if (output == null) output = new GeomPolyList();
		var verts = _verts.copy();
		var n = verts.length;
		if (n < 3) return output;

		// index ring, forced CCW so ear-clip convexity tests have a fixed sign
		var V = [for (i in 0...n) i];
		if (signedArea(verts) < 0) V.reverse();

		var nv = n;
		var guard = 3 * nv; // bail on degenerate/self-touching input
		var v = nv - 1;
		while (nv > 2) {
			if (guard-- <= 0) break;
			var u = v;
			if (nv <= u) u = 0;
			v = u + 1;
			if (nv <= v) v = 0;
			var w = v + 1;
			if (nv <= w) w = 0;
			if (snip(verts, u, v, w, nv, V)) {
				var a = V[u];
				var b = V[v];
				var c = V[w];
				var tri = new GeomPoly();
				tri._verts.push(new Vec2(verts[a].x, verts[a].y));
				tri._verts.push(new Vec2(verts[b].x, verts[b].y));
				tri._verts.push(new Vec2(verts[c].x, verts[c].y));
				output.push(tri);
				// remove vertex v from the working ring
				var s = v;
				var t = v + 1;
				while (t < nv) {
					V[s] = V[t];
					s++;
					t++;
				}
				nv--;
				guard = 3 * nv;
			}
		}
		return output;
	}

	static function signedArea(p:Array<Vec2>):Float {
		var a = 0.0;
		var n = p.length;
		for (i in 0...n) {
			var q = p[(i + 1) % n];
			a += p[i].x * q.y - q.x * p[i].y;
		}
		return a * 0.5;
	}

	// Is triangle (V[u],V[v],V[w]) a valid ear: CCW and contains no other vertex.
	static function snip(verts:Array<Vec2>, u:Int, v:Int, w:Int, n:Int, V:Array<Int>):Bool {
		var EPS = 1e-10;
		var A = verts[V[u]];
		var B = verts[V[v]];
		var C = verts[V[w]];
		if (EPS > ((B.x - A.x) * (C.y - A.y) - (B.y - A.y) * (C.x - A.x))) return false; // reflex
		for (p in 0...n) {
			if (p == u || p == v || p == w) continue;
			if (pointInTri(A, B, C, verts[V[p]])) return false;
		}
		return true;
	}

	static function pointInTri(A:Vec2, B:Vec2, C:Vec2, P:Vec2):Bool {
		var ax = C.x - B.x;
		var ay = C.y - B.y;
		var bx = A.x - C.x;
		var by = A.y - C.y;
		var cx = B.x - A.x;
		var cy = B.y - A.y;
		var apx = P.x - A.x;
		var apy = P.y - A.y;
		var bpx = P.x - B.x;
		var bpy = P.y - B.y;
		var cpx = P.x - C.x;
		var cpy = P.y - C.y;
		var aCROSSbp = ax * bpy - ay * bpx;
		var cCROSSap = cx * apy - cy * apx;
		var bCROSScp = bx * cpy - by * cpx;
		return (aCROSSbp >= 0.0) && (bCROSScp >= 0.0) && (cCROSSap >= 0.0);
	}
}
