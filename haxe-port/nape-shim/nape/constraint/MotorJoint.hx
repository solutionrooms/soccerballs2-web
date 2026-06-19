package nape.constraint;

import nape.phys.Body;
import nape.space.Space;

/**
 * nape.constraint.MotorJoint shim. Only ever constructed inside the rev-joint
 * `if (enableMotor)` branch, which is dead in every shipped level (all 19 rev
 * joints have the motor disabled). The replica folds motors into jointRev and
 * exposes no standalone-motor handle, so finalize is a no-op. Revisit if a level
 * ever enables a rev motor.
 */
class MotorJoint extends Constraint {
	public var body1:Body;
	public var body2:Body;
	public var rate:Float;
	public var ratio:Float;

	public function new(body1:Body, body2:Body, rate:Float = 0.0, ratio:Float = 1.0) {
		super();
		this.body1 = body1;
		this.body2 = body2;
		this.rate = rate;
		this.ratio = ratio;
	}

	override function finalize(sp:Space):Void {
		super.finalize(sp);
		attach(body1, body2);
		// dead branch in shipped levels; replica has no standalone-motor handle.
	}
}
