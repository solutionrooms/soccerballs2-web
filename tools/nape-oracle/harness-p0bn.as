// CALLING AS3 — oracle harness for RESTITUTION on a terrain SEAM (the "lost bounce"
// bug). A bouncy ball (elasticity 1) is dropped straight down onto the shared vertex of
// two abutting terrain triangles (elasticity 0) — so it lands with TWO active contacts
// (one per triangle), the case the game reports loses its bounce. Combined restitution
// = (1+0)/2 = 0.5, so Nape should rebound at ~half the impact speed. We trace the ball's
// y + vy for 40 steps (covering impact + rebound), raw IEEE-754 bits, to compare the
// replica's 2-contact restitution against 2012 Nape.
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

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0BN] DONE"); }
      catch (e:Error) { trace("[P0BN] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var ballMat:Material = new Material(1.0, 0.5, 0.5, 1.0, 0.1); // elasticity 1 (bouncy)
      var terrMat:Material = new Material(0.0, 0.5, 0.5, 1.0, 0.1); // elasticity 0 (grass)

      // Two triangles abutting at the shared top vertex (200,400) — a flat-top seam.
      var terrain:Body = new Body(BodyType.STATIC, new Vec2(0, 0));
      terrain.shapes.add(new Polygon([new Vec2(100, 400), new Vec2(200, 400), new Vec2(150, 440)], terrMat));
      terrain.shapes.add(new Polygon([new Vec2(200, 400), new Vec2(300, 400), new Vec2(250, 440)], terrMat));
      terrain.space = space;

      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 300)); // straight down onto the seam
      ball.shapes.add(new Circle(12, new Vec2(0, 0), ballMat));
      ball.align(); ball.space = space;

      for (var i:int = 1; i <= 40; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0BN] " + i + " " + bits(ball.position.y) + " " + bits(ball.velocity.y));
      }
    }
  }
}
