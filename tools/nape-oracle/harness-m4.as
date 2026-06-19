// CALLING AS3 — oracle harness for M4 (the contact solver).
// A dynamic circle dropped onto a STATIC polygon floor (elasticity 0 → resting
// contact). After each step trace the ball's full state: this is an INTEGRATION
// test of the whole pipeline (gravity + narrowphase + warm-started impulse solve
// + position correction). 180 steps. Raw IEEE-754 bits.
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
  import nape.dynamics.Arbiter;
  import nape.dynamics.CollisionArbiter;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M4] DONE");
      } catch (e:Error) {
        trace("[M4] ERROR " + e.message);
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
      floor.userData.h = 9;
      // dynamic ball
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 100));
      ball.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      ball.align();
      ball.space = space;
      ball.userData.h = 1;
      for (var i:int = 1; i <= 180; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M4] " + i + " " + bits(ball.position.x) + " " + bits(ball.position.y)
          + " " + bits(ball.rotation) + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y)
          + " " + bits(ball.angularVel));
        if (i == 50) {
          for (var k:int = 0; k < ball.arbiters.length; k++) {
            var arb:Arbiter = ball.arbiters.at(k);
            var ca:CollisionArbiter = arb.collisionArbiter;
            if (ca == null) continue;
            var nrm:Vec2 = ca.normal;
            trace("[M4ARB] body1 " + arb.body1.userData.h + " body2 " + arb.body2.userData.h
              + " n " + bits(nrm.x) + " " + bits(nrm.y) + " cnt " + ca.contacts.length
              + " pen " + bits(ca.contacts.at(0).penetration));
          }
        }
      }
    }
  }
}
