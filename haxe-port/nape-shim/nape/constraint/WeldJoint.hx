package nape.constraint;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.space.Space;

/**
 * nape.constraint.WeldJoint shim. The replica's jointWeld derives the anchor
 * (bodyB origin) and phase (rotB - rotA) itself, so the game-supplied anchors/
 * phase are not forwarded — only body handles + soft/freq.
 */
class WeldJoint extends Constraint {
	public var body1:Body;
	public var body2:Body;
	public var anchor1:Vec2;
	public var anchor2:Vec2;
	public var phase:Float;

	public function new(body1:Body, body2:Body, anchor1:Vec2, anchor2:Vec2, phase:Float = 0.0) {
		super();
		this.body1 = body1;
		this.body2 = body2;
		this.anchor1 = anchor1;
		this.anchor2 = anchor2;
		this.phase = phase;
		this.stiff = true;
	}

	override function finalize(sp:Space):Void {
		super.finalize(sp);
		_engine.jointWeld(body1.handle, body2.handle, !stiff, frequency);
		attach(body1, body2);
	}
}
