package nape.constraint;

import nape.phys.Body;
import nape.space.Space;

/**
 * nape.constraint.AngleJoint shim. Only ever constructed inside the rev-joint
 * `if (enableLimit)` branch, which is dead in every shipped level (all 19 rev
 * joints have limits disabled). The replica folds limits into jointRev and
 * exposes no standalone-limit handle, so finalize is a no-op.
 */
class AngleJoint extends Constraint {
	public var body1:Body;
	public var body2:Body;
	public var jointMin:Float;
	public var jointMax:Float;
	public var ratio:Float;

	public function new(body1:Body, body2:Body, jointMin:Float, jointMax:Float, ratio:Float = 1.0) {
		super();
		this.body1 = body1;
		this.body2 = body2;
		this.jointMin = jointMin;
		this.jointMax = jointMax;
		this.ratio = ratio;
	}

	override function finalize(sp:Space):Void {
		super.finalize(sp);
		attach(body1, body2);
		// dead branch in shipped levels.
	}
}
