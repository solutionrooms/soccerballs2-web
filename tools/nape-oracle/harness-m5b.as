// CALLING AS3 — oracle harness for M5b (PivotJoint, PURE TRANSLATION / no trig).
// The pivot anchors at the box's CENTRE of mass (a2 = (0,0)), so the constraint
// force and gravity both act through the COM → zero torque → the box never
// rotates (axis stays (0,1), no sin/cos error). This isolates the constraint
// solver's translational math as a bit-exact gate, separate from the rotating
// pendulum (harness-m5.as) whose only divergence is the cross-runtime trig gap.
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
  import nape.constraint.PivotJoint;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M5B] DONE");
      } catch (e:Error) {
        trace("[M5B] ERROR " + e.message);
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
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(240, 100));
      box.shapes.add(new Polygon(Polygon.box(80, 20), mat));
      box.align();
      box.space = space;
      // pivot at box COM (0,0) → no torque → no rotation → no trig.
      var pj:PivotJoint = new PivotJoint(anchor, box, new Vec2(0, 0), new Vec2(0, 0));
      pj.space = space;
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M5B] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
