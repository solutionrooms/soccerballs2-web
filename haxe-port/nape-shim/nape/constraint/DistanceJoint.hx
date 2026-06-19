package nape.constraint;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.space.Space;

/**
 * nape.constraint.DistanceJoint shim. The game passes LOCAL anchors + jointMin/
 * jointMax (= dist ∓ dist_limit). The replica's jointDist wants WORLD anchor
 * points + a single distLimit and recomputes min/max, so finalize recovers world
 * anchors via localPointToWorld and distLimit = (jointMax - jointMin)/2.
 */
class DistanceJoint extends Constraint {
	public var body1:Body;
	public var body2:Body;
	public var anchor1:Vec2;
	public var anchor2:Vec2;
	public var jointMin:Float;
	public var jointMax:Float;

	public function new(body1:Body, body2:Body, anchor1:Vec2, anchor2:Vec2, jointMin:Float, jointMax:Float) {
		super();
		this.body1 = body1;
		this.body2 = body2;
		this.anchor1 = anchor1;
		this.anchor2 = anchor2;
		this.jointMin = jointMin;
		this.jointMax = jointMax;
	}

	override function finalize(sp:Space):Void {
		super.finalize(sp);
		var w0 = body1.localPointToWorld(anchor1);
		var w1 = body2.localPointToWorld(anchor2);
		var distLimit = (jointMax - jointMin) / 2;
		_engine.jointDist(body1.handle, body2.handle, w0.x, w0.y, w1.x, w1.y, distLimit, !stiff, frequency);
		attach(body1, body2);
	}
}
