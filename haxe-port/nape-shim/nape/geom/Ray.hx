package nape.geom;

/** nape.geom.Ray shim — origin + direction + maxDistance, with point-at-distance. */
class Ray {
	public var origin:Vec2;
	public var direction:Vec2;
	public var maxDistance(get, set):Float;

	var _maxDist:Float;

	public function new(origin:Vec2, direction:Vec2) {
		this.origin = origin;
		this.direction = direction;
		_maxDist = 1e9;
	}

	inline function get_maxDistance():Float
		return _maxDist;
	inline function set_maxDistance(v:Float):Float
		return _maxDist = v;

	public function at(distance:Float, weak:Bool = false):Vec2 {
		// nape normalises direction; the game only uses axis-aligned (0,±1) rays,
		// where |direction| == 1, so origin + direction*distance is exact.
		return new Vec2(origin.x + direction.x * distance, origin.y + direction.y * distance);
	}

	public static function fromSegment(start:Vec2, end:Vec2):Ray {
		var dx = end.x - start.x;
		var dy = end.y - start.y;
		var len = Math.sqrt(dx * dx + dy * dy);
		var r = new Ray(new Vec2(start.x, start.y), new Vec2(len > 0 ? dx / len : 0, len > 0 ? dy / len : 0));
		r.maxDistance = len;
		return r;
	}
}
