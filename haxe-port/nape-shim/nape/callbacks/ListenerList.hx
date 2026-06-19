package nape.callbacks;

/** nape.callbacks.ListenerList shim — holds the InteractionListeners added via
 * `space.listeners.add(...)`; the Space iterates them to dispatch events. */
class ListenerList {
	var _a:Array<InteractionListener>;

	public function new()
		_a = [];

	public var length(get, never):Int;
	inline function get_length():Int
		return _a.length;

	public function at(i:Int):InteractionListener
		return _a[i];

	public function add(l:InteractionListener):Bool {
		_a.push(l);
		return true;
	}

	public function push(l:InteractionListener):Bool
		return add(l);

	public function remove(l:InteractionListener):Bool {
		var i = _a.indexOf(l);
		if (i == -1) return false;
		_a.splice(i, 1);
		return true;
	}

	public function iterator():Iterator<InteractionListener>
		return _a.iterator();
}
