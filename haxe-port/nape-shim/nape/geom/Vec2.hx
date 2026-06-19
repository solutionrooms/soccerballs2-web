package nape.geom;

import nape.phys.Body;

/**
 * nape.geom.Vec2 shim.
 *
 * Two modes:
 *  - VALUE mode (default): a plain (x,y) pair. `new Vec2(x,y)` everywhere in the
 *    game, gravity vectors, joint anchors, impulses, etc.
 *  - PROXY mode: returned by `Body.position` / `Body.velocity`. Reads and writes
 *    go THROUGH to the owning body's replica handle, so `body.position.x`,
 *    `body.velocity.setxy(0,0)`, `body.velocity.y -= e` all act on the real body
 *    (matching nape, where position/velocity are live views).
 */
class Vec2 {
	// value-mode storage
	var _vx:Float;
	var _vy:Float;
	// proxy-mode binding (null => value mode)
	var _body:Body;
	var _kind:Int; // 0 = position, 1 = velocity

	public function new(x:Float = 0, y:Float = 0) {
		_vx = x;
		_vy = y;
		_body = null;
		_kind = 0;
	}

	// Construct a body-bound proxy (called by Body.position / Body.velocity).
	@:allow(nape.phys.Body)
	static function bound(body:Body, kind:Int):Vec2 {
		var v = new Vec2();
		v._body = body;
		v._kind = kind;
		return v;
	}

	public static function fromPoint(p:Dynamic):Vec2 {
		return new Vec2(p.x, p.y);
	}

	public var x(get, set):Float;
	inline function get_x():Float
		return _body == null ? _vx : _body.prxGet(_kind, 0);
	function set_x(v:Float):Float {
		if (_body == null) _vx = v;
		else _body.prxSetXY(_kind, v, _body.prxGet(_kind, 1));
		return v;
	}

	public var y(get, set):Float;
	inline function get_y():Float
		return _body == null ? _vy : _body.prxGet(_kind, 1);
	function set_y(v:Float):Float {
		if (_body == null) _vy = v;
		else _body.prxSetXY(_kind, _body.prxGet(_kind, 0), v);
		return v;
	}

	public function setxy(x:Float, y:Float):Vec2 {
		if (_body == null) {
			_vx = x;
			_vy = y;
		} else {
			_body.prxSetXY(_kind, x, y);
		}
		return this;
	}

	public function set(v:Vec2):Vec2
		return setxy(v.x, v.y);

	public function addeq(v:Vec2):Vec2
		return setxy(get_x() + v.x, get_y() + v.y);

	public function subeq(v:Vec2):Vec2
		return setxy(get_x() - v.x, get_y() - v.y);

	public function muleq(s:Float):Vec2
		return setxy(get_x() * s, get_y() * s);

	public function add(v:Vec2, weak:Bool = false):Vec2
		return new Vec2(get_x() + v.x, get_y() + v.y);

	public function sub(v:Vec2, weak:Bool = false):Vec2
		return new Vec2(get_x() - v.x, get_y() - v.y);

	public function mul(s:Float, weak:Bool = false):Vec2
		return new Vec2(get_x() * s, get_y() * s);

	public function dot(v:Vec2):Float
		return get_x() * v.x + get_y() * v.y;

	public function cross(v:Vec2):Float
		return get_x() * v.y - get_y() * v.x;

	public function lsq():Float {
		var px = get_x();
		var py = get_y();
		return px * px + py * py;
	}

	public var length(get, set):Float;
	function get_length():Float
		return Math.sqrt(lsq());
	function set_length(l:Float):Float {
		var cur = get_length();
		if (cur > 0) muleq(l / cur);
		return l;
	}

	public var angle(get, set):Float;
	function get_angle():Float
		return Math.atan2(get_y(), get_x());
	function set_angle(a:Float):Float {
		var len = get_length();
		setxy(len * Math.cos(a), len * Math.sin(a));
		return a;
	}

	public function copy():Vec2
		return new Vec2(get_x(), get_y());

	public function dispose():Void {}

	public function toString():String
		return "{ x: " + get_x() + " y: " + get_y() + " }";
}
