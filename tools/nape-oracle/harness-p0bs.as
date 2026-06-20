// CALLING AS3 — oracle: FOOTBALL into a SETTLED (sleeping) crate STACK.
// Level-9 "ball blocker": the player kicks a football (circle r12, elasticity 1)
// into a vertical stack of crates that has settled and gone to SLEEP. The ball
// must bounce hard enough off a crate (combined restitution 0.6) to register an
// impulse >= 150 and break it. Jon reports the ball does NOT bounce off the
// stacked/loaded crates (vy 113->3) even though a FREE crate bounces it fine
// (gate p0br). This isolates the suspect: ball-vs-SLEEPING/constrained crate.
//
// Setup: 3 dynamic crates (48x40, material `average`) stacked on a STATIC floor,
// stepped 70 frames so the island goes to sleep, THEN a football is added and
// fired horizontally (700px/s) at the MIDDLE crate's face. We trace the ball and
// all 3 crates for 40 more frames as raw IEEE-754 bits; the key signal is whether
// the ball's vx REVERSES (bounces) the way real Nape's does.
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

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0BS] DONE"); }
      catch (e:Error) { trace("[P0BS] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function crate(space:Space, cy:Number, m:Material):Body {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(200, cy));
      b.shapes.add(new Polygon([new Vec2(-24, -20), new Vec2(24, -20), new Vec2(24, 20), new Vec2(-24, 20)], m));
      b.align();
      b.space = space;
      return b;
    }

    private function emit(tag:String, i:int, b:Body):void {
      trace("[P0BS] " + i + " " + tag + " " + bits(b.position.x) + " " + bits(b.position.y)
        + " " + bits(b.rotation) + " " + bits(b.velocity.x) + " " + bits(b.velocity.y) + " " + bits(b.angularVel));
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var crateMat:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1); // `average`
      var ballMat:Material  = new Material(1.0, 0.1, 0.1, 0.5, 0.1); // `football`

      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400)); // top y=380
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], crateMat));
      floor.space = space;

      var c1:Body = crate(space, 361, crateMat); // bottom y=381 (1px into floor)
      var c2:Body = crate(space, 322, crateMat); // middle
      var c3:Body = crate(space, 283, crateMat); // top

      var ball:Body = null;
      for (var i:int = 1; i <= 110; i++) {
        if (i == 71) {
          // stack is now asleep — fire the football at the MIDDLE crate's left face
          ball = new Body(BodyType.DYNAMIC, new Vec2(120, 322));
          ball.shapes.add(new Circle(12, new Vec2(0, 0), ballMat));
          ball.align();
          ball.space = space;
          ball.velocity = new Vec2(700, 0);
        }
        space.step(1.0 / 60.0, 10, 10);
        if (i >= 70) {
          emit("c1", i, c1);
          emit("c2", i, c2);
          emit("c3", i, c3);
          if (ball != null) emit("bl", i, ball);
        }
      }
    }
  }
}
