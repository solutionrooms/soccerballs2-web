package nape.callbacks;

import nape.phys.Body;
import nape.dynamics.ArbiterList;

/**
 * nape.callbacks.InteractionCallback shim — passed to a listener handler.
 * The game reads `cb.int1.userData.data`, `cb.int2.userData.data` and
 * `cb.arbiters`. int1/int2 are the two interacting bodies (this game's userData
 * lives on the body), arbiters the (single) synthesized arbiter for the pair.
 */
class InteractionCallback {
	public var int1(default, null):Body;
	public var int2(default, null):Body;
	public var arbiters(default, null):ArbiterList;

	public function new(int1:Body, int2:Body, arbiters:ArbiterList) {
		this.int1 = int1;
		this.int2 = int2;
		this.arbiters = arbiters;
	}
}
