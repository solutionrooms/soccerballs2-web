package nape.dynamics;

/** nape.dynamics.ContactList shim — the synthesized arbiter carries one contact. */
class ContactList {
	var _a:Array<Contact>;

	public function new()
		_a = [];

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):Contact
		return _a[i];

	@:allow(nape.dynamics.CollisionArbiter)
	function push(c:Contact):Void
		_a.push(c);

	public function iterator():Iterator<Contact>
		return _a.iterator();
}
