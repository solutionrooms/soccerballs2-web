// CALLING AS3 — oracle harness for M5w (WeldJoint, cantilever / no rotation).
// A dynamic box is WELDED at its left end to a static anchor and cantilevers under
// gravity. The weld is rigid, so the box neither rotates nor falls: its angular
// DOF (jAccz) actively resists the gravity torque while its y DOF resists gravity,
// yet rotation stays 0 (axis (0,1)) → no sin/cos is ever evaluated. This grades
// the full 3-DOF weld solver (preStep 3×3 kMass / warmStart / applyImpulseVel /
// applyImpulsePos) BIT-FOR-BIT with no cross-runtime trig gap. 90 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.geom.Vec2;
  import nape.constraint.WeldJoint;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M5W] DONE");
      } catch (e:Error) {
        trace("[M5W] ERROR " + e.message);
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
      // weld box's left end (-40,0) to the static anchor; phase 0 (locked angle).
      var wj:WeldJoint = new WeldJoint(anchor, box, new Vec2(0, 0), new Vec2(-40, 0));
      wj.space = space;
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M5W] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
