package nape.shape;

/** nape.shape.ShapeList shim — buffer of shapes for a Body (Array<Shape> wrapper). */
class ShapeList {
	var _a:Array<Shape>;

	public function new()
		_a = [];

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):Shape
		return _a[i];

	// PREPEND, matching nape's ZPP_Body shape list: body.shapes.add() inserts at the HEAD, so shapes.at(0)
	// is the LAST-added shape. The game relies on this for per-shape ops by index (SetBodyShapeCollisionMask
	// — keeper duck disables at(2)/at(3); SetBodyShapeRadius/Material). The replica's b.shapes[] is add-order
	// (append), so Shape.emit records each shape's engine index and per-shape ops use that, not this index.
	public function add(s:Shape):Bool {
		_a.unshift(s);
		return true;
	}

	public function push(s:Shape):Bool {
		_a.unshift(s);
		return true;
	}

	public function pop():Shape
		return _a.pop();

	public function has(s:Shape):Bool
		return _a.indexOf(s) != -1;

	public function clear():Void
		_a = [];

	public function iterator():Iterator<Shape>
		return _a.iterator();
}
