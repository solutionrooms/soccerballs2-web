// CALLING AS3 — oracle harness for a runtime sensorEnabled toggle (game
// shape.sensorEnabled = true). A ball rests on a static block; at step 30 (still AWAKE) the
// block's shape becomes a SENSOR, so it leaves the solver and the ball free-falls through.
// Trace the ball's y + vy, 50 steps, raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.shape.Polygon;
  import nape.shape.Shape;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0SE] DONE"); }
      catch (e:Error) { trace("[P0SE] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);

      var block:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      var bshape:Shape = new Polygon([new Vec2(-50, -10), new Vec2(50, -10), new Vec2(50, 10), new Vec2(-50, 10)], mat);
      block.shapes.add(bshape);
      block.space = space;

      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 376));
      ball.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      ball.align(); ball.space = space;

      for (var i:int = 1; i <= 50; i++) {
        if (i == 30) bshape.sensorEnabled = true; // block becomes a sensor → stops colliding
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0SE] " + i + " " + bits(ball.position.y) + " " + bits(ball.velocity.y));
      }
    }
  }
}
