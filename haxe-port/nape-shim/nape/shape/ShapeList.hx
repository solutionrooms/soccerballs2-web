package nape.shape;

/** nape.shape.ShapeList shim — buffer of shapes for a Body (Array<Shape> wrapper). */
class ShapeList {
	var _a:Array<Shape>;

	public function new()
		_a = [];

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	// Nape's ZPP_Body shape list PREPENDS on add, so shapes.at(0) is the LAST-added shape. We get that
	// semantics by reverse-indexing HERE rather than by reordering the underlying list — the game relies on
	// at(i) for per-shape ops by index (SetBodyShapeCollisionMask — keeper duck disables at(2)/at(3);
	// SetBodyShapeRadius/Material). Shape.emit records each shape's engine add-order index, so a per-shape op
	// on at(i) still targets the correct engine shape.
	public function at(i:Int):Shape
		return _a[_a.length - 1 - i];

	// APPEND (add-order). CRITICAL: do NOT unshift here. The list order is the order shapes are emitted to the
	// replica (Body.finalize iterates this list), which is the order the engine creates+solves their contact
	// arbiters. Reordering it reverses the sequential-impulse solve order and subtly perturbs physics — e.g.
	// a ball rolling a long way over multi-triangle terrain drifts a touch too far (lvl-10 close-call goal
	// regression). Keeping add-order matches the original/faithful solve; Nape's reverse at() is in at() above.
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
