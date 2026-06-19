package nape.constraint;

import nape.geom.Vec2;
import nape.phys.Body;
import nape.space.Space;

/**
 * nape.constraint.PivotJoint shim. The game builds rev joints as a PivotJoint
 * with LOCAL anchors (worldPointToLocal of a shared world point). The replica's
 * jointRev wants the WORLD anchor and re-derives locals, so finalize recovers it
 * via body1.localPointToWorld(anchor1). Rev joints ship as pure pivots (motor +
 * limit disabled across all levels), so no motor/limit is forwarded here.
 */
class PivotJoint extends Constraint {
	public var body1:Body;
	public var body2:Body;
	public var anchor1:Vec2;
	public var anchor2:Vec2;

	public function new(body1:Body, body2:Body, anchor1:Vec2, anchor2:Vec2) {
		super();
		this.body1 = body1;
		this.body2 = body2;
		this.anchor1 = anchor1;
		this.anchor2 = anchor2;
	}

	override function finalize(sp:Space):Void {
		super.finalize(sp);
		var w = body1.localPointToWorld(anchor1);
		_engine.jointRev(body1.handle, body2.handle, w.x, w.y, false, 0, 0, false, 0, 0);
		attach(body1, body2);
	}
}
