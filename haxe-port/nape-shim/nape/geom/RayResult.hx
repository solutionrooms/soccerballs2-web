package nape.geom;

import nape.shape.Shape;

/** nape.geom.RayResult shim — the game reads `.distance` (and r.at(distance)). */
class RayResult {
	public var distance(default, null):Float;
	public var normal(default, null):Vec2;
	public var inner(default, null):Bool;
	public var shape(default, null):Shape;

	public function new(distance:Float, ?normal:Vec2, inner:Bool = false, ?shape:Shape) {
		this.distance = distance;
		this.normal = normal != null ? normal : new Vec2(0, -1);
		this.inner = inner;
		this.shape = shape;
	}
}
