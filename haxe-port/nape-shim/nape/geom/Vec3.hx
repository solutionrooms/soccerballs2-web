package nape.geom;

/** nape.geom.Vec3 shim — plain value triple (used by Body.normalImpulse etc). */
class Vec3 {
	public var x:Float;
	public var y:Float;
	public var z:Float;

	public function new(x:Float = 0, y:Float = 0, z:Float = 0) {
		this.x = x;
		this.y = y;
		this.z = z;
	}

	public function setxyz(x:Float, y:Float, z:Float):Vec3 {
		this.x = x;
		this.y = y;
		this.z = z;
		return this;
	}

	public function lsq():Float
		return x * x + y * y + z * z;

	public var length(get, set):Float;
	function get_length():Float
		return Math.sqrt(lsq());
	function set_length(l:Float):Float {
		var cur = get_length();
		if (cur > 0) {
			x *= l / cur;
			y *= l / cur;
			z *= l / cur;
		}
		return l;
	}

	public function copy():Vec3
		return new Vec3(x, y, z);

	public function xy(weak:Bool = false):Vec2
		return new Vec2(x, y);

	public function dispose():Void {}
}
