// CALLING AS3 — oracle harness for P0b-1 (circle-CIRCLE contact, ptype 2).
// A dynamic ball balances on top of a STATIC circle (centre directly above →
// vertical normal), settling via the circle-circle (ptype-2) position correction.
// No CCD (slow). 60 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0CC] DONE"); }
      catch (e:Error) { trace("[P0CC] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var post:Body = new Body(BodyType.STATIC, new Vec2(200, 300));
      post.shapes.add(new Circle(30, new Vec2(0, 0), mat));
      post.space = space;
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 257)); // centre 43 above → pen 1
      ball.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      ball.align();
      ball.space = space;
      for (var i:int = 1; i <= 60; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0CC] " + i + " " + bits(ball.position.x) + " " + bits(ball.position.y)
          + " " + bits(ball.rotation) + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y)
          + " " + bits(ball.angularVel));
      }
    }
  }
}
