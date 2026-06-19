// CALLING AS3 — oracle harness for M4d (the DISCRETE contact solver, isolated).
// A dynamic circle is placed already slightly PENETRATING a static polygon floor,
// at rest. Under gravity it settles to the resting separation purely via the
// discrete pipeline (narrowphase → prestep → warmStart → iterateVel → iteratePos):
// per-step velocity-driven motion stays far below the continuous-collision
// threshold, so the swept/TOI pass cannot interfere. This isolates the discrete
// solver from CCD (which the fast drop in harness-m4.as triggers at impact).
// 60 steps, raw IEEE-754 bits.
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
      try {
        run();
        trace("[M4D] DONE");
      } catch (e:Error) {
        trace("[M4D] ERROR " + e.message);
      }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n);
      ba.position = 0;
      var hi:uint = ba.readUnsignedInt();
      var lo:uint = ba.readUnsignedInt();
      return hi.toString(16) + ":" + lo.toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1); // elasticity 0
      // static floor: wide box, top face at y = 280
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 300));
      floor.shapes.add(new Polygon([new Vec2(-200, -20), new Vec2(200, -20), new Vec2(200, 20), new Vec2(-200, 20)], mat));
      floor.align();
      floor.space = space;
      // dynamic ball, START penetrating 2px (bottom at 282 vs floor top 280),
      // at rest → settles to the resting separation with no fast impact.
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 270));
      ball.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      ball.align();
      ball.space = space;
      for (var i:int = 1; i <= 60; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M4D] " + i + " " + bits(ball.position.x) + " " + bits(ball.position.y)
          + " " + bits(ball.rotation) + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y)
          + " " + bits(ball.angularVel));
      }
    }
  }
}
