// CALLING AS3 — oracle harness for M5m (MotorJoint, pure-angular / bit-exact).
// A dynamic centred box is driven by a MotorJoint (rate 10 rad/s) to spin at a
// constant angular velocity while falling under gravity (linear). MotorJoint is a
// purely-angular VELOCITY constraint (no position correction) and the COM is
// centred, so nothing reads the sin/cos axis → bit-exact despite the spin.
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
  import nape.constraint.MotorJoint;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M5M] DONE");
      } catch (e:Error) {
        trace("[M5M] ERROR " + e.message);
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
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(300, 100));
      box.shapes.add(new Polygon(Polygon.box(20, 20), mat));
      box.align();
      box.space = space;
      var mj:MotorJoint = new MotorJoint(anchor, box, 10, 1); // rate 10, ratio 1
      mj.space = space;
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M5M] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
