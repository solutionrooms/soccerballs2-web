// CALLING AS3 — oracle harness for M5a (AngleJoint, pure-angular / bit-exact).
// A dynamic centred box is given an initial spin and constrained by an AngleJoint
// to a static body so its rotation stays within [-0.5, 0.5] rad; it also falls
// under gravity (linear). AngleJoint is a PURELY ANGULAR constraint — it reads
// rot/angvel, never the sin/cos axis — and the box's COM is centred, so no force
// reads the axis either. Thus the whole state is bit-exact despite the rotation.
// The box spins into the angle limit and is held: exercises slack→limit + solve.
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
  import nape.constraint.AngleJoint;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M5A] DONE");
      } catch (e:Error) {
        trace("[M5A] ERROR " + e.message);
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
      box.angularVel = 5; // initial spin → will hit the +0.5 rad limit
      box.space = space;
      var aj:AngleJoint = new AngleJoint(anchor, box, -0.5, 0.5);
      aj.space = space;
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M5A] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
