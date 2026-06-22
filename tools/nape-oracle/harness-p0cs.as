// CALLING AS3 — a metal-crate-sized box (48x40, `average`) sliding FAST horizontally
// across a static floor, decelerating under friction (the "sandy rebound" essence:
// a crate knocked sideways travels a friction-bounded distance, then in vs past the
// hole is decided by how far it slides). This is the one poly-poly path no gate yet
// covers — a box with large TANGENTIAL velocity on static terrain — i.e. exactly
// where the head-insert (unshift) contact-order change could move the friction
// Gauss-Seidel order. Trace x/y/rot + vx each step so we can compare the slide
// distance replica-vs-original bit-for-bit.
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
    public function Preloader() { super(); stop();
      try { run(); trace("[P0CS] DONE"); } catch (e:Error) { trace("[P0CS] ERROR " + e.message); } }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var avg:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1); // `average` (crate + ground)

      var floor:Body = new Body(BodyType.STATIC, new Vec2(300, 440)); // top y=420
      floor.shapes.add(new Polygon([new Vec2(-300,-20), new Vec2(300,-20), new Vec2(300,20), new Vec2(-300,20)], avg));
      floor.space = space;

      // 48x40 metal-crate box resting on the floor (bottom y=420), kicked sideways.
      var crate:Body = new Body(BodyType.DYNAMIC, new Vec2(80, 400));
      crate.shapes.add(new Polygon([new Vec2(-24,-20), new Vec2(24,-20), new Vec2(24,20), new Vec2(-24,20)], avg));
      crate.align();
      crate.space = space;
      crate.velocity = new Vec2(420, 0); // slides right, friction decelerates it

      for (var i:int = 1; i <= 120; i++) {
        space.step(1.0/60.0, 10, 10);
        trace("[P0CS] " + i
          + " " + bits(crate.position.x) + " " + bits(crate.position.y) + " " + bits(crate.rotation)
          + " " + bits(crate.velocity.x));
      }
    }
  }
}
