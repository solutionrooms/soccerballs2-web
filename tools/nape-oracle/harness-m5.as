// CALLING AS3 — oracle harness for M5 (the constraint solver: PivotJoint).
// A dynamic box is pinned by a PivotJoint to a STATIC anchor at one end and
// swings under gravity like a pendulum. No contacts — this isolates the joint
// solver (preStep kMass / warmStart / applyImpulseVel / applyImpulsePos). The
// box's left-end anchor coincides with the static anchor initially. 90 steps,
// raw IEEE-754 bits of the box's full state.
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
        trace("[M5] DONE");
      } catch (e:Error) {
        trace("[M5] ERROR " + e.message);
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
      // dynamic box 80x20, centre at (240,100); left-end local (-40,0) starts at
      // world (200,100) == the static anchor → joint initially satisfied.
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(240, 100));
      box.shapes.add(new Polygon(Polygon.box(80, 20), mat));
      box.align();
      box.space = space;
      var pj:PivotJoint = new PivotJoint(anchor, box, new Vec2(0, 0), new Vec2(-40, 0));
      pj.space = space;
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[M5] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
