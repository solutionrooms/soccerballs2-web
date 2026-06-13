// Haxe facade exposing Nape to the TypeScript web port. Compiled to JS via
// `haxe build.hxml`, the output exposes `NapeWorld` on the global scope.
// Bodies are referenced by integer handle so TS never touches Nape objects.
// All positions/velocities are in PIXELS (the game's unit); Nape itself runs
// in pixels too (no meters scaling, unlike Box2D), which is part of why it's
// a faithful match for the original AS3 game.
//
// Handle 0 is reserved for the static world body (space.world) so level joints
// can attach to "the world" exactly as Nape's space.world did in AS3.
import nape.space.Space;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.shape.Shape;
import nape.geom.Vec2;
import nape.geom.GeomPoly;
import nape.geom.Ray;
import nape.geom.RayResult;
import nape.dynamics.InteractionFilter;
import nape.dynamics.Arbiter;
import nape.dynamics.CollisionArbiter;
import nape.constraint.WeldJoint;
import nape.constraint.PivotJoint;
import nape.constraint.DistanceJoint;
import nape.constraint.AngleJoint;
import nape.constraint.MotorJoint;
import nape.callbacks.CbType;
import nape.callbacks.InteractionListener;
import nape.callbacks.InteractionCallback;
import nape.callbacks.CbEvent;
import nape.callbacks.InteractionType;

@:expose("NapeWorld")
@:keep // keep every field: only JS (not Haxe) calls these, so DCE must not strip them
class NapeWorld {
  var space:Space;
  var bodies:Map<Int, Body>;
  var nextHandle:Int;
  var defaultCb:CbType;
  // begin-contact events drained each frame: [handleA, handleB, sensorFlag]
  var contacts:Array<Int>;
  // begin-collision impulse reports drained each frame:
  // [handleA, handleB, impulse, normalX, normalY]
  var impacts:Array<Float>;

  public function new(gravityPxY:Float) {
    space = new Space(new Vec2(0, gravityPxY));
    bodies = new Map();
    nextHandle = 1;
    defaultCb = new CbType();
    contacts = [];
    impacts = [];

    // collect begin-interaction events: one listener per type so we know the
    // sensor flag without inspecting arbiters
    var anyCb = CbType.ANY_BODY;
    space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, anyCb, anyCb,
      function(cb:InteractionCallback) { onCollision(cb); }));
    space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.SENSOR, anyCb, anyCb,
      function(cb:InteractionCallback) { onSensor(cb); }));
  }

  inline function lookup(h:Int):Body {
    // handle 0 == the static world body (joints attach to "the world")
    return h == 0 ? space.world : bodies.get(h);
  }

  function onSensor(cb:InteractionCallback):Void {
    var a:Body = cb.int1.castBody;
    var b:Body = cb.int2.castBody;
    if (a == null || b == null) return;
    var ha = a.userData.handle;
    var hb = b.userData.handle;
    if (ha == null || hb == null) return;
    contacts.push(ha);
    contacts.push(hb);
    contacts.push(1);
  }

  function onCollision(cb:InteractionCallback):Void {
    var a:Body = cb.int1.castBody;
    var b:Body = cb.int2.castBody;
    if (a == null || b == null) return;
    var ha = a.userData.handle;
    var hb = b.userData.handle;
    if (ha == null || hb == null) return;
    contacts.push(ha);
    contacts.push(hb);
    contacts.push(0);

    // impulse report (breakable crates): the BEGIN listener fires post-solve,
    // so read Nape's real accumulated normalImpulse — this IS what the AS3 game
    // used (GameObj.as:3299 nape_bodies[0].normalImpulse), so the break feel is
    // exact rather than estimated.
    if (cb.arbiters.length > 0) {
      var arb:Arbiter = cb.arbiters.at(0);
      var ca:CollisionArbiter = arb.collisionArbiter;
      if (ca != null) {
        var n:Vec2 = ca.normal; // unit normal, body1 -> body2
        var imp = ca.normalImpulse(null, false); // Vec3 (linear x,y + angular z)
        var nimp:Float = Math.sqrt(imp.x * imp.x + imp.y * imp.y);
        impacts.push(ha);
        impacts.push(hb);
        impacts.push(nimp);
        impacts.push(n.x);
        impacts.push(n.y);
      }
    }
  }

  public function setGravity(gpxY:Float):Void {
    space.gravity.setxy(0, gpxY);
  }

  public function createBody(isStatic:Bool, xPx:Float, yPx:Float, rotDeg:Float, linDamp:Float, angDamp:Float):Int {
    var b = new Body(isStatic ? BodyType.STATIC : BodyType.DYNAMIC, new Vec2(xPx, yPx));
    b.rotation = rotDeg * Math.PI / 180;
    b.userData.handle = nextHandle;
    // Nape damping is per-Space worldLinearDrag/worldAngularDrag; we approximate
    // per-body damping by storing it (applied in step()).
    b.userData.linDamp = linDamp;
    b.userData.angDamp = angDamp;
    bodies.set(nextHandle, b);
    return nextHandle++;
  }

  function mkFilter(colCat:Int, colMask:Int, isSensor:Bool):InteractionFilter {
    var f = new InteractionFilter();
    if (isSensor) {
      f.sensorGroup = colCat;
      f.sensorMask = colMask;
      f.collisionGroup = 0;
      f.collisionMask = 0;
    } else {
      f.collisionGroup = colCat;
      f.collisionMask = colMask;
      f.sensorGroup = 0;
      f.sensorMask = 0;
    }
    return f;
  }

  // store original mask + sensor flag so collision toggles can restore exactly
  inline function tagShape(s:Shape, mask:Int, isSensor:Bool):Void {
    s.userData.origMask = mask;
    s.userData.isSensor = isSensor;
  }

  public function addCircle(h:Int, posX:Float, posY:Float, radius:Float, density:Float, friction:Float, rolling:Float, elasticity:Float, colCat:Int, colMask:Int, isSensor:Bool):Void {
    var b = bodies.get(h);
    if (b == null) return;
    // Nape already scales mass by density/1000 internally, so pass the raw AS3
    // density: mass = area * density / 1000 — numerically the game's massNape.
    var mat = new Material(elasticity, friction, friction, density, rolling);
    var s = new Circle(radius, new Vec2(posX, posY), mat, mkFilter(colCat, colMask, isSensor));
    s.sensorEnabled = isSensor;
    tagShape(s, colMask, isSensor);
    b.shapes.add(s);
  }

  public function addPolygon(h:Int, vertsFlat:Array<Float>, density:Float, friction:Float, rolling:Float, elasticity:Float, colCat:Int, colMask:Int, isSensor:Bool):Void {
    var b = bodies.get(h);
    if (b == null) return;
    var pts = new Array<Vec2>();
    var i = 0;
    while (i < vertsFlat.length) { pts.push(new Vec2(vertsFlat[i], vertsFlat[i + 1])); i += 2; }
    // raw AS3 density: Nape scales mass by density/1000 internally (see addCircle)
    var mat = new Material(elasticity, friction, friction, density, rolling);
    var filter = mkFilter(colCat, colMask, isSensor);
    // decompose into convex pieces (Nape's own algorithm, handles concave)
    var gp = new GeomPoly(pts);
    var list = gp.convexDecomposition(true);
    for (piece in list) {
      var poly = new Polygon(piece, mat, filter);
      poly.sensorEnabled = isSensor;
      tagShape(poly, colMask, isSensor);
      b.shapes.add(poly);
    }
  }

  public function finalizeBody(h:Int, bullet:Bool):Void {
    var b = bodies.get(h);
    if (b == null) return;
    var hasShapes = b.shapes.length > 0;
    if (b.type == BodyType.DYNAMIC) {
      if (!hasShapes) {
        // no physical shapes (all filters zero) — an inert placeholder like in
        // planck; Nape can't mass an empty dynamic body, so freeze it.
        b.allowMovement = false;
        b.allowRotation = false;
      } else {
        // A dynamic body with only sensor shapes has 0 mass / 0 inertia; Box2D
        // silently gives such bodies mass 1 and leaves them non-rotating, while
        // Nape refuses to simulate them — match Box2D's fallback for parity.
        b.align();
        if (b.mass == 0) b.mass = 1;
        if (b.inertia == 0) b.allowRotation = false;
      }
    } else if (b.type == BodyType.KINEMATIC && hasShapes) {
      b.align();
    }
    b.space = space;
  }

  public function setBodyType(h:Int, type:Int):Void {
    var b = bodies.get(h);
    if (b == null) return;
    b.type = type == 0 ? BodyType.STATIC : (type == 2 ? BodyType.KINEMATIC : BodyType.DYNAMIC);
  }

  public function destroyBody(h:Int):Void {
    var b = bodies.get(h);
    if (b == null) return;
    b.space = null;
    bodies.remove(h);
  }

  public function step(dt:Float, velIters:Int, posIters:Int):Void {
    // NO manual damping here: Nape's Space already applies worldLinearDrag /
    // worldAngularDrag natively (default 0.015 — exactly the drag the original
    // AS3 game relied on). Applying per-body damping on top double-damped the
    // ball (~2x energy loss), so it fell short of bank shots like level 9.
    contacts = [];
    impacts = [];
    space.step(dt, velIters, posIters);
  }

  public function takeContacts():Array<Int> {
    var c = contacts;
    contacts = [];
    return c;
  }

  public function takeImpacts():Array<Float> {
    var c = impacts;
    impacts = [];
    return c;
  }

  public function getX(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.position.x; }
  public function getY(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.position.y; }
  public function getRot(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.rotation * 180 / Math.PI; }
  public function getRotRad(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.rotation; }
  public function getVX(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.velocity.x; }
  public function getVY(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.velocity.y; }
  public function getAngVel(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.angularVel; }
  public function getMass(h:Int):Float { var b = bodies.get(h); return b == null ? 0 : b.mass; }
  public function isDynamic(h:Int):Bool { var b = bodies.get(h); return b == null ? false : b.type == BodyType.DYNAMIC; }

  // true if any shape of the body contains the world-space point (wind persist)
  public function bodyContains(h:Int, xPx:Float, yPx:Float):Bool {
    var b = bodies.get(h);
    if (b == null) return false;
    var p = new Vec2(xPx, yPx);
    for (s in b.shapes) {
      if (s.contains(p)) return true;
    }
    return false;
  }

  // summed shape area in px^2 (burstable-ball explosion force)
  public function bodyArea(h:Int):Float {
    var b = bodies.get(h);
    if (b == null) return 0;
    var a:Float = 0;
    for (s in b.shapes) a += s.area;
    return a;
  }

  public function setTransform(h:Int, xPx:Float, yPx:Float, rotDeg:Float):Void {
    var b = bodies.get(h);
    if (b == null) return;
    // Nape forbids moving/rotating a static body once it's in a Space (and a
    // static body never moves anyway), so parking one is a no-op.
    if (b.type == BodyType.STATIC) return;
    b.position.setxy(xPx, yPx);
    b.rotation = rotDeg * Math.PI / 180;
  }
  public function setVel(h:Int, vx:Float, vy:Float):Void {
    var b = bodies.get(h);
    if (b == null) return;
    b.velocity.setxy(vx, vy);
  }
  public function setAngVel(h:Int, w:Float):Void { var b = bodies.get(h); if (b != null) b.angularVel = w; }
  public function setAwake(h:Int, awake:Bool):Void {
    var b = bodies.get(h);
    if (b != null && awake) b.velocity.x = b.velocity.x; // touch to wake (Nape has no per-body allowSleep)
  }
  public function applyImpulse(h:Int, jx:Float, jy:Float):Void {
    var b = bodies.get(h);
    if (b == null) return;
    b.applyImpulse(new Vec2(jx, jy));
  }

  // restore (or zero) every shape's mask — ball MoveToPlayer collision toggle
  public function setBodyCollision(h:Int, enabled:Bool):Void {
    var b = bodies.get(h);
    if (b == null) return;
    for (s in b.shapes) {
      var om:Int = s.userData.origMask;
      var sen:Bool = s.userData.isSensor;
      var m = enabled ? om : 0;
      if (sen) s.filter.sensorMask = m; else s.filter.collisionMask = m;
    }
  }

  // toggle only shapes whose top reaches above topThresholdPx (keeper duck):
  // the tall idle shape (to -70px) toggles, the short crouch shape stays solid
  public function setBodyCollisionAboveTop(h:Int, topThresholdPx:Float, enabled:Bool):Void {
    var b = bodies.get(h);
    if (b == null) return;
    for (s in b.shapes) {
      var topPx:Float = b.position.y - s.bounds.y; // px above the body origin
      if (topPx <= topThresholdPx) continue;
      var om:Int = s.userData.origMask;
      var sen:Bool = s.userData.isSensor;
      var m = enabled ? om : 0;
      if (sen) s.filter.sensorMask = m; else s.filter.collisionMask = m;
    }
  }

  // dynamic bodies currently in collision contact with body h (switch persist)
  public function touchingBodies(h:Int):Array<Int> {
    var out = new Array<Int>();
    var b = bodies.get(h);
    if (b == null) return out;
    for (arb in b.arbiters) {
      if (arb.collisionArbiter == null) continue;
      var other:Body = (arb.body1 == b) ? arb.body2 : arb.body1;
      if (other != null && other.type == BodyType.DYNAMIC) {
        var oh = other.userData.handle;
        if (oh != null) out.push(oh);
      }
    }
    return out;
  }

  // ray straight down from (x, fromY), returns hit y (px) or NaN
  public function raycastDown(xPx:Float, fromYPx:Float, maxDist:Float, colCat:Int):Float {
    var ray = new Ray(new Vec2(xPx, fromYPx), new Vec2(0, 1));
    ray.maxDistance = maxDist;
    var filter = new InteractionFilter(colCat, colCat, 0, 0);
    var res:RayResult = space.rayCast(ray, false, filter);
    if (res == null) return Math.NaN;
    var p = ray.at(res.distance);
    return p.y;
  }

  // --- level joints (PhysicsBase.AddJoint_Nape). handle 0 == world body. ----

  public function jointRev(hA:Int, hB:Int, ax:Float, ay:Float, enableMotor:Bool, motorSpeed:Float,
      maxTorque:Float, enableLimit:Bool, lowerRad:Float, upperRad:Float):Void {
    var a = lookup(hA); var b = lookup(hB);
    if (a == null || b == null || a == b) return;
    var anchor = new Vec2(ax, ay);
    var piv = new PivotJoint(a, b, a.worldPointToLocal(anchor), b.worldPointToLocal(anchor));
    piv.space = space;
    if (enableMotor) {
      var mj = new MotorJoint(a, b, motorSpeed, 1);
      mj.maxForce = maxTorque;
      mj.space = space;
    }
    if (enableLimit) {
      var aj = new AngleJoint(a, b, lowerRad, upperRad, 1);
      aj.space = space;
    }
  }

  public function jointWeld(hA:Int, hB:Int, soft:Bool, freq:Float):Void {
    var a = lookup(hA); var b = lookup(hB);
    if (a == null || b == null || a == b) return;
    // a weld between two non-dynamic bodies is meaningless (matches planck)
    if (a.type != BodyType.DYNAMIC && b.type != BodyType.DYNAMIC) return;
    // weld is rigid regardless of anchor; use bodyB origin (the AS3 intent).
    var anchor = b.position.copy();
    var phase = b.rotation - a.rotation;
    var wj = new WeldJoint(a, b, a.worldPointToLocal(anchor), b.worldPointToLocal(anchor), phase);
    if (soft) { wj.stiff = false; wj.frequency = freq; wj.damping = 1; }
    wj.space = space;
  }

  public function jointDist(hA:Int, hB:Int, x0:Float, y0:Float, x1:Float, y1:Float, distLimit:Float, soft:Bool, freq:Float):Void {
    var a = lookup(hA); var b = lookup(hB);
    if (a == null || b == null || a == b) return;
    var dx = x1 - x0; var dy = y1 - y0;
    var dist = Math.sqrt(dx * dx + dy * dy);
    var minLen = dist - distLimit; if (minLen < 0) minLen = 0;
    var maxLen = dist + distLimit;
    var dj = new DistanceJoint(a, b, a.worldPointToLocal(new Vec2(x0, y0)), b.worldPointToLocal(new Vec2(x1, y1)), minLen, maxLen);
    if (soft) { dj.stiff = false; dj.frequency = freq; dj.damping = 1; }
    dj.space = space;
  }

  static function main() {}
}
