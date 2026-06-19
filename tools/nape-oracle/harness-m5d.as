// CALLING AS3 — oracle harness for M5d (DistanceJoint, swinging / no rotation).
// A dynamic box hangs from a static anchor by a RIGID distance rod (jointMin ==
// jointMax == 80), anchored at the box's CENTRE of mass. Released from the side it
// swings as a pendulum, but because the rod force passes through the COM the box
// never rotates (axis stays (0,1) → no sin/cos). This makes the 1-DOF distance
// solver (preStep / warmStart / applyImpulseVel / applyImpulsePos, incl. the
// fast-inv-sqrt distance) gradeable BIT-FOR-BIT, fully dynamic but trig-free.
// 90 steps, raw IEEE-754 bits of the box state.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.geom.Vec2;
  import nape.constraint.DistanceJoint;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M5D] DONE");
      } catch (e:Error) {
        trace("[M5D] ERROR " + e.message);
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
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var anchor:Body = new Body(BodyType.STATIC, new Vec2(200, 100));
      anchor.space = space;
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(280, 100)); // 80px to the side
      box.shapes.add(new Polygon(Polygon.box(20, 20), mat));
      box.align();
      box.space = space;
      // rigid rod, length 80, anchored at the box COM (0,0) → no torque → no spin.
      var dj:DistanceJoint = new DistanceJoint(anchor, box, new Vec2(0, 0), new Vec2(0, 0), 80, 80);
      dj.space = space;
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M5D] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
