// CALLING AS3 — oracle harness for milestone M3a (circle-circle narrowphase).
// Two overlapping circles; after one step, read the collision arbiter's normal
// and the contact penetration (the narrowphase manifold) as raw IEEE-754 bits.
// Also traces body1/body2 handle order so the replica can match the normal sign.
// No gravity: this isolates the contact geometry.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.geom.Vec2;
  import nape.dynamics.Arbiter;
  import nape.dynamics.CollisionArbiter;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M3] DONE");
      } catch (e:Error) {
        trace("[M3] ERROR " + e.message);
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

    private function mkCircle(space:Space, mat:Material, x:Number, y:Number, r:Number, hh:int):Body {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      b.shapes.add(new Circle(r, new Vec2(0, 0), mat));
      b.align();
      b.space = space;
      b.userData.h = hh;
      return b;
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 0));
      var mat:Material = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
      var a:Body = mkCircle(space, mat, 100, 100, 20, 1);
      var b:Body = mkCircle(space, mat, 130, 100, 20, 2);
      space.step(1.0 / 60.0, 10, 10);
      for (var i:int = 0; i < a.arbiters.length; i++) {
        var arb:Arbiter = a.arbiters.at(i);
        var ca:CollisionArbiter = arb.collisionArbiter;
        if (ca == null) continue;
        var n:Vec2 = ca.normal;
        var pen:Number = ca.contacts.at(0).penetration;
        trace("[M3CC] " + arb.body1.userData.h + " " + arb.body2.userData.h
          + " " + bits(n.x) + " " + bits(n.y) + " " + bits(pen));
      }
    }
  }
}
