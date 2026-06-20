// CALLING AS3 — oracle harness for BALL-INTO-CRATE IMPACT IMPULSE (break input).
// A DYNAMIC football (circle r12, REAL football material: elasticity 1) is fired
// horizontally at 700px/s into a resting DYNAMIC crate (48×40 poly, REAL crate
// material `average`: elasticity 0.2) sitting on a STATIC floor. Each step we
// trace the EXACT value the game's crate-break logic consumes —
// `crate.normalImpulse(ball).length` (GameObj.OnHit_Breakable_Pieces:
// l = that / ballMass; break if l >= 150) — plus both bodies' velocity and x so
// we can see the impact frame and detect any tunneling/penetration difference.
// This is the one break-threshold input path no existing golden covers
// (circle-vs-DYNAMIC-poly impact). 40 steps, raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.shape.Circle;
  import nape.geom.Vec2;
  import nape.geom.Vec3;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0BR] DONE"); }
      catch (e:Error) { trace("[P0BR] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var crateMat:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1); // `average`
      var ballMat:Material = new Material(1.0, 0.1, 0.1, 0.5, 0.1);  // `football`

      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400)); // top y=380
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], crateMat));
      floor.space = space;

      var crate:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 361)); // 48×40, bottom y=381 (1px into floor)
      crate.shapes.add(new Polygon([new Vec2(-24, -20), new Vec2(24, -20), new Vec2(24, 20), new Vec2(-24, 20)], crateMat));
      crate.align();
      crate.space = space;

      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(120, 361)); // crate-centre height
      ball.shapes.add(new Circle(12, new Vec2(0, 0), ballMat));
      ball.align();
      ball.space = space;
      ball.velocity = new Vec2(700, 0); // fired into the crate

      for (var i:int = 1; i <= 40; i++) {
        space.step(1.0 / 60.0, 10, 10);
        var v0:Vec3 = crate.normalImpulse(ball);
        // The GAME's actual break input is Vec2(v0.x, v0.y).length (z dropped);
        // also emit the full Vec3.length and the raw components to settle which.
        var lVec2:Number = Math.sqrt(v0.x * v0.x + v0.y * v0.y);
        trace("[P0BR] " + i
          + " " + bits(v0.length)   // full Vec3 length (incl. angular z)
          + " " + bits(crate.velocity.x) + " " + bits(crate.velocity.y)
          + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y)
          + " " + bits(crate.position.x) + " " + bits(ball.position.x)
          + " " + bits(lVec2) + " " + bits(v0.x) + " " + bits(v0.y) + " " + bits(v0.z));
      }
    }
  }
}
