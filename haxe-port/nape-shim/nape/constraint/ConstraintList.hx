package nape.constraint;

import nape.space.Space;

/**
 * nape.constraint.ConstraintList shim. When owned by a Space (`space.constraints`),
 * `add` FINALIZES the joint into the replica (jointRev/jointWeld/jointDist).
 */
class ConstraintList {
	var _a:Array<Constraint>;
	var _space:Space;

	public function new() {
		_a = [];
		_space = null;
	}

	@:allow(nape.space.Space)
	static function forSpace(sp:Space):ConstraintList {
		var l = new ConstraintList();
		l._space = sp;
		return l;
	}

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):Constraint
		return _a[i];

	public function add(c:Constraint):Bool {
		if (_space != null) c.finalize(_space);
		_a.push(c);
		return true;
	}

	public function push(c:Constraint):Bool
		return add(c);

	public function remove(c:Constraint):Bool {
		var i = _a.indexOf(c);
		if (i == -1) return false;
		_a.splice(i, 1);
		return true;
	}

	public function has(c:Constraint):Bool
		return _a.indexOf(c) != -1;

	public function iterator():Iterator<Constraint>
		return _a.iterator();
}
