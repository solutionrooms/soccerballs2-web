package nape.geom;

/** nape.geom.Vec2List shim — thin wrapper over Array<Vec2>. */
class Vec2List {
	var _a:Array<Vec2>;

	public function new()
		_a = [];

	@:allow(nape)
	static function of(a:Array<Vec2>):Vec2List {
		var l = new Vec2List();
		l._a = a;
		return l;
	}

	public static function fromArray(a:Array<Vec2>):Vec2List
		return of(a.copy());

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):Vec2
		return _a[i];

	public function push(v:Vec2):Bool {
		_a.push(v);
		return true;
	}

	public function add(v:Vec2):Bool
		return push(v);

	public function pop():Vec2
		return _a.pop();

	public function clear():Void
		_a = [];

	public function copy(deep:Bool = false):Vec2List
		return of(_a.copy());

	public function iterator():Iterator<Vec2>
		return _a.iterator();
}
