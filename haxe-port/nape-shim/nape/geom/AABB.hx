package nape.geom;

/** nape.geom.AABB shim — axis-aligned box (used by Shape.bounds in a debug path). */
class AABB {
	public var x:Float;
	public var y:Float;
	public var width:Float;
	public var height:Float;

	public function new(x:Float = 0, y:Float = 0, width:Float = 0, height:Float = 0) {
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	public var min(get, never):Vec2;
	inline function get_min():Vec2
		return new Vec2(x, y);

	public var max(get, never):Vec2;
	inline function get_max():Vec2
		return new Vec2(x + width, y + height);
}
