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

	public function add(s:Shape):Bool {
		_a.push(s);
		return true;
	}

	public function push(s:Shape):Bool {
		_a.push(s);
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
