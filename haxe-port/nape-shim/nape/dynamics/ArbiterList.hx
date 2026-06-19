package nape.dynamics;

/** nape.dynamics.ArbiterList shim — the arbiters of one InteractionCallback. */
class ArbiterList {
	var _a:Array<Arbiter>;

	public function new()
		_a = [];

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):Arbiter
		return _a[i];

	public function add(a:Arbiter):Bool {
		_a.push(a);
		return true;
	}

	public function push(a:Arbiter):Bool
		return add(a);

	public function iterator():Iterator<Arbiter>
		return _a.iterator();
}
