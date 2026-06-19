// CALLING AS3 — oracle harness for ROTATING POLYGON-POLYGON (tilted box settling).
// A DYNAMIC 24×24 box starts tilted 20° with its lower corner just inside a STATIC
// floor, then rotates down to lie flat. This exercises (a) the SAT/clip with a
// rotated incident edge, (b) the posOnly single-corner contact (one clipped point
// penetrating, the other separated) and its transition to the full 2-contact rest,
// and (c) body ROTATION through the solver — which stresses the incrementally
// maintained axisx/axisy (Nape only recomputes them from sin/cos when the axis is
// dirtied, NOT every step). 120 steps, box full state as raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0PPR] DONE"); }
      catch (e:Error) { trace("[P0PPR] ERROR " + e.message); }
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
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat));
      floor.space = space;
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 366));
      box.shapes.add(new Polygon([new Vec2(-12, -12), new Vec2(12, -12), new Vec2(12, 12), new Vec2(-12, 12)], mat));
      box.align();
      box.rotation = 20 * Math.PI / 180; // matches createBody(rotDeg=20)
      box.space = space;
      for (var i:int = 1; i <= 120; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0PPR] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
