// CALLING AS3 — oracle harness for M3c (polygon-polygon narrowphase).
// Two overlapping axis-aligned boxes (face-face → two contacts). After one step,
// trace the arbiter normal, the contact count, and each contact's penetration +
// position, plus body1/body2 order. Raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.geom.Vec2;
  import nape.dynamics.Arbiter;
  import nape.dynamics.CollisionArbiter;
  import nape.dynamics.Contact;

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

    private function mkBox(space:Space, mat:Material, x:Number, y:Number, hh:int):Body {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      b.shapes.add(new Polygon([new Vec2(-20, -12), new Vec2(20, -12), new Vec2(20, 12), new Vec2(-20, 12)], mat));
      b.align();
      b.space = space;
      b.userData.h = hh;
      return b;
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 0));
      var mat:Material = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
      var a:Body = mkBox(space, mat, 200, 200, 1);
      var b:Body = mkBox(space, mat, 200, 184, 2); // overlaps A from above by 8
      space.step(1.0 / 60.0, 10, 10);
      for (var i:int = 0; i < a.arbiters.length; i++) {
        var arb:Arbiter = a.arbiters.at(i);
        var ca:CollisionArbiter = arb.collisionArbiter;
        if (ca == null) continue;
        var nrm:Vec2 = ca.normal;
        trace("[M3PP] " + arb.body1.userData.h + " " + arb.body2.userData.h
          + " n " + bits(nrm.x) + " " + bits(nrm.y) + " cnt " + ca.contacts.length);
        for (var j:int = 0; j < ca.contacts.length; j++) {
          var ct:Contact = ca.contacts.at(j);
          trace("[M3PP-C] " + j + " pen " + bits(ct.penetration)
            + " pos " + bits(ct.position.x) + " " + bits(ct.position.y));
        }
      }
    }
  }
}
