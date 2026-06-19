// CALLING AS3 — oracle harness for COLLISION FILTERING + SENSORS (F1/F2).
// One static floor and three dynamic balls dropped onto it:
//   bLand  — collisionMask includes the floor's group → collides, settles.
//   bPass  — collisionMask EXCLUDES the floor's group → no arbiter, falls through.
//   bSens  — a SENSOR (collisionGroup 0) → no arbiter, falls through.
// Filters replicate NapeWorld.mkFilter exactly: collider = InteractionFilter(cat,
// mask, 0, 0); sensor = InteractionFilter(0, 0, cat, mask) + sensorEnabled. We trace
// each ball's y every step; the filter decision (collide vs pass-through) is what
// this validates. 30 steps, raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.shape.Polygon;
  import nape.geom.Vec2;
  import nape.dynamics.InteractionFilter;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0FL] DONE"); }
      catch (e:Error) { trace("[P0FL] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400)); // top face y=380
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat,
        new InteractionFilter(1, 0xffff, 0, 0)));
      floor.space = space;

      var bLand:Body = new Body(BodyType.DYNAMIC, new Vec2(160, 360));
      bLand.shapes.add(new Circle(12, new Vec2(0, 0), mat, new InteractionFilter(4, 0xffff, 0, 0)));
      bLand.align(); bLand.space = space;

      var bPass:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 360));
      bPass.shapes.add(new Circle(12, new Vec2(0, 0), mat, new InteractionFilter(4, 2, 0, 0))); // floor group 1 ∉ mask 2
      bPass.align(); bPass.space = space;

      var bSens:Body = new Body(BodyType.DYNAMIC, new Vec2(240, 360));
      var sc:Circle = new Circle(12, new Vec2(0, 0), mat, new InteractionFilter(0, 0, 4, 0xffff));
      sc.sensorEnabled = true;
      bSens.shapes.add(sc);
      bSens.align(); bSens.space = space;

      for (var i:int = 1; i <= 30; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0FL] " + i + " L " + bits(bLand.position.y) + " " + bits(bLand.velocity.y)
          + " P " + bits(bPass.position.y) + " S " + bits(bSens.position.y));
      }
    }
  }
}
