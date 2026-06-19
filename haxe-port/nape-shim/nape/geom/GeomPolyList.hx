package nape.geom;

/** nape.geom.GeomPolyList shim — Array<GeomPoly> wrapper (triangularDecomposition output). */
class GeomPolyList {
	var _a:Array<GeomPoly>;

	public function new()
		_a = [];

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):GeomPoly
		return _a[i];

	public function push(g:GeomPoly):GeomPolyList {
		_a.push(g);
		return this;
	}

	public function add(g:GeomPoly):Bool {
		_a.push(g);
		return true;
	}

	public function pop():GeomPoly
		return _a.pop();

	public function clear():Void
		_a = [];

	public function iterator():Iterator<GeomPoly>
		return _a.iterator();
}
