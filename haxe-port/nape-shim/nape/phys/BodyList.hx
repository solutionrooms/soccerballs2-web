package nape.phys;

import nape.space.Space;

/**
 * nape.phys.BodyList shim. When owned by a Space (`space.bodies`), `add` FINALIZES
 * the body into the replica and `remove` destroys it — this is how the game adds
 * bodies (`GetNapeSpace().bodies.add(b)`) and removes them.
 */
class BodyList {
	var _a:Array<Body>;
	var _space:Space;

	public function new() {
		_a = [];
		_space = null;
	}

	@:allow(nape.space.Space)
	static function forSpace(sp:Space):BodyList {
		var l = new BodyList();
		l._space = sp;
		return l;
	}

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):Body
		return _a[i];

	public function add(b:Body):Bool {
		if (_space != null) b.finalize(_space);
		_a.push(b);
		return true;
	}

	public function push(b:Body):Bool
		return add(b);

	public function remove(b:Body):Bool {
		var i = _a.indexOf(b);
		if (i == -1) return false;
		if (_space != null) b.destroy();
		_a.splice(i, 1);
		return true;
	}

	public function has(b:Body):Bool
		return _a.indexOf(b) != -1;

	public function pop():Body
		return _a.pop();

	public function clear():Void {
		if (_space != null) for (b in _a) b.destroy();
		_a = [];
	}

	public function iterator():Iterator<Body>
		return _a.iterator();
}
