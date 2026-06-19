// CALLING AS3 — oracle harness for M3b (circle-polygon narrowphase).
// Two scenarios, each its own space: a circle on a box FACE (edge contact) and a
// circle near a box CORNER (vertex contact). After one step, trace the arbiter
// normal + contact penetration, plus body1/body2 handle order (normal sign).
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
        scenario("EDGE", 200, 175);   // circle centred over the box top face
        scenario("VERT", 175, 175);   // circle off the top-left corner
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

    private function scenario(tag:String, cx:Number, cy:Number):void {
      var space:Space = new Space(new Vec2(0, 0));
      var mat:Material = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
      var circ:Body = new Body(BodyType.DYNAMIC, new Vec2(cx, cy));
      circ.shapes.add(new Circle(15, new Vec2(0, 0), mat));
      circ.align();
      circ.space = space;
      circ.userData.h = 1;
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 200));
      box.shapes.add(new Polygon([new Vec2(-20, -12), new Vec2(20, -12), new Vec2(20, 12), new Vec2(-20, 12)], mat));
      box.align();
      box.space = space;
      box.userData.h = 2;
      space.step(1.0 / 60.0, 10, 10);
      for (var i:int = 0; i < circ.arbiters.length; i++) {
        var arb:Arbiter = circ.arbiters.at(i);
        var ca:CollisionArbiter = arb.collisionArbiter;
        if (ca == null) continue;
        var n:Vec2 = ca.normal;
        var pen:Number = ca.contacts.at(0).penetration;
        trace("[M3CP-" + tag + "] " + arb.body1.userData.h + " " + arb.body2.userData.h
          + " " + bits(n.x) + " " + bits(n.y) + " " + bits(pen));
      }
    }
  }
}
