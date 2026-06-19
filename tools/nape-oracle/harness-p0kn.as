// CALLING AS3 — oracle harness for KINEMATIC body semantics (E-kin). Two contact-free
// kinematic bodies so the trace is cleanly bit-exact (the rider-carry contact transient
// is governed by Nape's component sleep/wake lifecycle and is verified behaviourally,
// not here):
//   plat — a KINEMATIC platform driven right at 120 px/s (velocity re-set each frame,
//          as the game does via SetBodyXForm): must integrate position from velocity and
//          take NO gravity (y stays 400).
//   ref  — a stationary KINEMATIC body whose collision box is offset from the origin
//          (origin at the feet, COM 40px up). The referee bug: it must keep its
//          REGISTRATION origin (388,128), NOT recenter onto the COM (388,88).
// We trace both bodies' position, 30 steps, raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0KN] DONE"); }
      catch (e:Error) { trace("[P0KN] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);

      // Moving kinematic platform — created STATIC then flipped (as the game does); NOT aligned.
      var plat:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      plat.shapes.add(new Polygon([new Vec2(-100, -10), new Vec2(100, -10), new Vec2(100, 10), new Vec2(-100, 10)], mat));
      plat.space = space;
      plat.type = BodyType.KINEMATIC;

      // Stationary kinematic referee with an OFFSET collision box (origin at the feet,
      // COM 40px up). Must keep its registration origin (388,128), not recenter.
      var ref:Body = new Body(BodyType.STATIC, new Vec2(388, 128));
      ref.shapes.add(new Polygon([new Vec2(-10, -80), new Vec2(10, -80), new Vec2(10, 0), new Vec2(-10, 0)], mat));
      ref.space = space;
      ref.type = BodyType.KINEMATIC;

      for (var i:int = 1; i <= 30; i++) {
        plat.velocity.setxy(120, 0); // game re-drives velocity each frame
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0KN] " + i
          + " " + bits(plat.position.x) + " " + bits(plat.position.y)
          + " " + bits(ref.position.x) + " " + bits(ref.position.y));
      }
    }
  }
}
