// CALLING AS3 — oracle harness for MULTI-SHAPE bodies (E2).
// A single STATIC body carries TWO polygon shapes (a left pad and a right pad with
// a gap between them). Three balls are dropped: over the LEFT pad (shapes[0]), over
// the RIGHT pad (shapes[1] — the case shapes[0]-only narrowphase would miss), and
// over the GAP (falls through). Validates that collisions are tested against EVERY
// shape on a body. We trace each ball's y every step, 30 steps, raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.shape.Polygon;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0MS] DONE"); }
      catch (e:Error) { trace("[P0MS] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var pad:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      // shape[0]: left pad, world x[120,180], top y=380 ; shape[1]: right pad, world x[220,280]
      pad.shapes.add(new Polygon([new Vec2(-80, -20), new Vec2(-20, -20), new Vec2(-20, 20), new Vec2(-80, 20)], mat));
      pad.shapes.add(new Polygon([new Vec2(20, -20), new Vec2(80, -20), new Vec2(80, 20), new Vec2(20, 20)], mat));
      pad.space = space;

      var bL:Body = new Body(BodyType.DYNAMIC, new Vec2(150, 360)); // over left pad (shapes[0])
      bL.shapes.add(new Circle(12, new Vec2(0, 0), mat)); bL.align(); bL.space = space;
      var bR:Body = new Body(BodyType.DYNAMIC, new Vec2(250, 360)); // over right pad (shapes[1])
      bR.shapes.add(new Circle(12, new Vec2(0, 0), mat)); bR.align(); bR.space = space;
      var bG:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 360)); // over the gap → falls through
      bG.shapes.add(new Circle(12, new Vec2(0, 0), mat)); bG.align(); bG.space = space;

      for (var i:int = 1; i <= 30; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0MS] " + i + " L " + bits(bL.position.y) + " R " + bits(bR.position.y) + " G " + bits(bG.position.y));
      }
    }
  }
}
