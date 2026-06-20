// CALLING AS3 — oracle: football into the SEAM of two stacked crates.
// Level-9 "break 2 crates with one shot": the player aims at the boundary between
// two stacked crates, expecting BOTH to break. A crate breaks iff
//   Vec2(crate.normalImpulse(ball).x, .y).length / ballMass >= 150.
// Jon's live [BREAK] probe showed a slightly-low hit puts l=365 on the LOWER crate
// (breaks) and l=0 on the upper (grazed). This harness fires the ball DEAD-CENTRE
// at the seam and reports BOTH crates' break-input each step, so we can see whether
// the original splits the impulse across both (=> both break) and whether the
// replica reproduces that split. 2 crates (48x40, `average`) stacked on a STATIC
// floor; football (r12, elasticity 1) fired horizontally at the seam y. Raw bits.
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
      super(); stop();
      try { run(); trace("[P0S2] DONE"); } catch (e:Error) { trace("[P0S2] ERROR " + e.message); }
    }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }
    private function crate(space:Space, cy:Number, m:Material):Body {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(200, cy));
      b.shapes.add(new Polygon([new Vec2(-24,-20), new Vec2(24,-20), new Vec2(24,20), new Vec2(-24,20)], m));
      b.align(); b.space = space; return b;
    }
    // the GAME's break input for `ref`: Vec2(normalImpulse(ref,ball).x,.y).length
    private function breakLen(ref:Body, ball:Body):Number {
      var v:Vec3 = ref.normalImpulse(ball);
      return Math.sqrt(v.x*v.x + v.y*v.y);
    }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var crateMat:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1);
      var ballMat:Material  = new Material(1.0, 0.1, 0.1, 0.5, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon([new Vec2(-100,-20), new Vec2(100,-20), new Vec2(100,20), new Vec2(-100,20)], crateMat));
      floor.space = space;
      var cB:Body = crate(space, 360, crateMat); // bottom: spans 340..380 (on floor)
      var cT:Body = crate(space, 320, crateMat); // top:    spans 300..340 (seam y=340)
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(120, 340)); // centred on the seam
      ball.shapes.add(new Circle(12, new Vec2(0,0), ballMat));
      ball.align(); ball.space = space;
      ball.velocity = new Vec2(700, 0);
      for (var i:int = 1; i <= 20; i++) {
        space.step(1.0/60.0, 10, 10);
        trace("[P0S2] " + i
          + " " + bits(breakLen(cT, ball))   // top crate break-input
          + " " + bits(breakLen(cB, ball))   // bottom crate break-input
          + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y));
      }
    }
  }
}
