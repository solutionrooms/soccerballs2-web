package nape.shape;

import nape.geom.Vec2;
import nape.phys.Material;
import nape.dynamics.InteractionFilter;
import rnape.NapeReplicaJS;

/** nape.shape.Circle shim. */
class Circle extends Shape {
	var _radius:Float;
	var _localCOM:Vec2;

	public function new(radius:Float, ?localCOM:Vec2, ?material:Material, ?filter:InteractionFilter) {
		super();
		_radius = radius;
		_localCOM = localCOM != null ? new Vec2(localCOM.x, localCOM.y) : new Vec2(0, 0);
		if (material != null) this.material = material;
		if (filter != null) this.filter = filter;
	}

	public var radius(get, set):Float;
	inline function get_radius():Float
		return _radius;
	inline function set_radius(v:Float):Float
		return _radius = v;

	override function get_area():Float
		return Math.PI * _radius * _radius;

	override function add(engine:NapeReplicaJS, handle:Int, density:Float, f:Float, roll:Float, e:Float, cat:Int, mask:Int, sensor:Bool):Void {
		engine.addCircle(handle, _localCOM.x, _localCOM.y, _radius, density, f, roll, e, cat, mask, sensor);
	}

	override function worldVertsArray():Array<Vec2> {
		// approximate the circle's world bounds with its COM ± radius box corners
		var c = body != null ? body.localPointToWorld(_localCOM) : new Vec2(_localCOM.x, _localCOM.y);
		return [
			new Vec2(c.x - _radius, c.y - _radius),
			new Vec2(c.x + _radius, c.y - _radius),
			new Vec2(c.x + _radius, c.y + _radius),
			new Vec2(c.x - _radius, c.y + _radius)
		];
	}
}
