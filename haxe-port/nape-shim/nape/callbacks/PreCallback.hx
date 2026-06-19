package nape.callbacks;

import nape.phys.Body;
import nape.dynamics.Arbiter;

/** nape.callbacks.PreCallback shim — unused (PreListener was reverted). */
class PreCallback {
	public var arbiter(default, null):Arbiter;
	public var int1(default, null):Body;
	public var int2(default, null):Body;
	public var swapped(default, null):Bool;

	public function new() {}
}
