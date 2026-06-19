// CALLING AS3 — oracle harness for runtime collision-mask change (game
// SetBodyCollisionMask → shape.filter.collisionMask). A ball rests on a static block;
// at step 30 (while still AWAKE — before any sleep, to isolate the filter mechanics from
// the sleep/wake lifecycle) the block's collision mask is set to 0, so it stops colliding
// and the ball free-falls. We trace the ball's y + vy, 50 steps, raw IEEE-754 bits.
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
      try { run(); trace("[P0SW] DONE"); }
      catch (e:Error) { trace("[P0SW] ERROR " + e.message); }
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
        if (i == 30) bshape.filter.collisionMask = 0; // switch fires: block disappears
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0SW] " + i + " " + bits(ball.position.y) + " " + bits(ball.velocity.y));
      }
    }
  }
}
