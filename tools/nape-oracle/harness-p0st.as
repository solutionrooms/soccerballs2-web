// CALLING AS3 — oracle harness for a DYNAMIC POLYGON STACK (3 crates on a floor).
// THREE dynamic 24×24 boxes are stacked, perfectly axis-aligned (all at x=200),
// each penetrating the one below by 1px, the bottom one penetrating a STATIC
// floor by 1px. This is the level-9 "ball blocker" crate-pile geometry reduced
// to its physics essence, and it is the FIRST scenario to exercise two solver
// paths no existing golden covers:
//   (a) DYNAMIC-vs-DYNAMIC polygon face-face contacts (crate resting on crate) —
//       p0pp / p0ppr only ever rest a box on a STATIC floor; and
//   (b) a MULTI-ARBITER both-dynamic island, i.e. >=2 entries in c_arbiters_false,
//       which is the ONLY case where Nape's penetration-depth arbiter sort
//       (ZPP_Space.as:1644 `if(sortcontacts)` merge sort on oc1.dist) actually
//       reorders anything. With 3 boxes there are 2 both-dynamic arbiters
//       (box1-box2, box2-box3), so the sort runs for the first time.
// We trace all three boxes' full state every step, 90 steps, as raw IEEE-754 bits.
// Material is identical to the validated p0pp harness so any divergence is
// attributable purely to the new dynamic-stack path, not to materials.
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
      try { run(); trace("[P0ST] DONE"); }
      catch (e:Error) { trace("[P0ST] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function makeBox(space:Space, cy:Number, mat:Material):Body {
      var box:Body = new Body(BodyType.DYNAMIC, new Vec2(200, cy));
      box.shapes.add(new Polygon([new Vec2(-12, -12), new Vec2(12, -12), new Vec2(12, 12), new Vec2(-12, 12)], mat));
      box.align();
      box.space = space;
      return box;
    }

    private function emit(tag:String, i:int, b:Body):void {
      trace("[P0ST] " + i + " " + tag + " " + bits(b.position.x) + " " + bits(b.position.y)
        + " " + bits(b.rotation) + " " + bits(b.velocity.x) + " " + bits(b.velocity.y)
        + " " + bits(b.angularVel));
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      // STATIC floor: top face at y=380.
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat));
      floor.space = space;
      // Bottom-to-top, each penetrating the one below by 1px (matches p0pp's 1px).
      var box1:Body = makeBox(space, 367, mat); // bottom y=379 -> 1px into floor top 380
      var box2:Body = makeBox(space, 342, mat); // bottom y=354 -> 1px into box1 top 355
      var box3:Body = makeBox(space, 317, mat); // bottom y=329 -> 1px into box2 top 330
      for (var i:int = 1; i <= 90; i++) {
        space.step(1.0 / 60.0, 10, 10);
        emit("b1", i, box1);
        emit("b2", i, box2);
        emit("b3", i, box3);
      }
    }
  }
}
