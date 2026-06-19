// CALLING AS3 — the oracle harness for milestone M0.
//
// This replaces the game's document class (Preloader) so the SWF boots straight
// into a pure Nape physics test: no game, no levels, no rendering. It drives the
// ORIGINAL Nape AS3 (already compiled in this SWF) through the exact M0 scenario
// the ported TS replica runs, and trace()s each value as raw IEEE-754 bits so
// there is zero decimal-rounding loss in the captured golden.
//
// Injected with:
//   ffdec -replace SoccerBalls2.swf m0-oracle.swf Preloader harness-m0.as
// Captured with tools/nape-oracle/capture.mjs (Ruffle headless, filter [ORACLE]).
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        runM0();
      } catch (e:Error) {
        trace("[ORACLE] ERROR " + e.message);
      }
    }

    // raw 64-bit pattern of a Number as "hi:lo" (big-endian halves)
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n);
      ba.position = 0;
      var hi:uint = ba.readUnsignedInt();
      var lo:uint = ba.readUnsignedInt();
      return hi.toString(16) + ":" + lo.toString(16);
    }

    private function runM0():void {
      // M0 scenario: one dynamic circle, gravity 1000, default world drag 0.015,
      // released at (100, 50). Material density 1.0 (Nape stores /1000).
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(100, 50));
      var c:Circle = new Circle(12, new Vec2(0, 0), mat);
      b.shapes.add(c);
      b.align();
      b.space = space;

      trace("[ORACLE] mass " + bits(b.mass) + " (" + b.mass + ")");
      for (var i:int = 1; i <= 600; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[ORACLE] " + i
          + " " + bits(b.position.x)
          + " " + bits(b.position.y)
          + " " + bits(b.velocity.x)
          + " " + bits(b.velocity.y)
          + " " + bits(b.rotation)
          + " " + bits(b.angularVel));
      }
      trace("[ORACLE] DONE");
    }
  }
}
