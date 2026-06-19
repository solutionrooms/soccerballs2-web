// CALLING AS3 — oracle harness for POLYGON-POLYGON (box on static floor).
// A DYNAMIC 24×24 box rests centred on a STATIC floor, its bottom edge
// penetrating the floor's top edge by 1px. This is the face-face two-contact
// case: the manifold has two contact points (the box's bottom corners, clipped),
// solved together by Nape's 2×2 "block" LCP in iterateVel and the matching
// two-contact position solver in iteratePos. The box is centred so it stays
// axis-aligned (rot ≡ 0) — this isolates the block solver from body rotation.
// We trace the box's full state every step, 60 steps, as raw IEEE-754 bits.
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
      try { run(); trace("[P0PP] DONE"); }
      catch (e:Error) { trace("[P0PP] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400)); // top face y=380
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat));
      floor.space = space;
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 367)); // bottom y=379, penetrates floor top by 1
      box.shapes.add(new Polygon([new Vec2(-12, -12), new Vec2(12, -12), new Vec2(12, 12), new Vec2(-12, 12)], mat));
      box.align();
      box.space = space;
      for (var i:int = 1; i <= 60; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0PP] " + i + " " + bits(box.position.x) + " " + bits(box.position.y)
          + " " + bits(box.rotation) + " " + bits(box.velocity.x) + " " + bits(box.velocity.y)
          + " " + bits(box.angularVel));
      }
    }
  }
}
