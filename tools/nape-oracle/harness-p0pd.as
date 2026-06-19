// CALLING AS3 — oracle harness for POLY-POLY closest distance
// (ZPP_SweepDistance.distance, the primitive poly continuous-collision builds on).
// Calls the ORIGINAL internal distance() directly for axis-aligned box pairs:
// face-region separated, corner-region separated (segment endpoints closest), and
// overlapping (clip → negative gap). Traces the signed distance + witness points
// p3 (on shape1), p4 (on shape2), p5 (normal). Isolates the poly-poly distance.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.geom.Vec2;
  import zpp_nape.geom.ZPP_SweepDistance;
  import zpp_nape.geom.ZPP_Vec2;
  import zpp_nape.shape.ZPP_Shape;

  public class Preloader extends MovieClip {
    private var space:Space;
    private var mat:Material;

    public function Preloader() {
      super();
      stop();
      try { run(); trace("[P0PD] DONE"); }
      catch (e:Error) { trace("[P0PD] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function box(x:Number, y:Number, verts:Array):ZPP_Shape {
      var b:Body = new Body(BodyType.STATIC, new Vec2(x, y));
      b.shapes.add(new Polygon(verts, mat));
      b.space = space;
      return b.shapes.at(0).zpp_inner;
    }

    private function q(tag:String, s1:ZPP_Shape, s2:ZPP_Shape):void {
      var p3:ZPP_Vec2 = new ZPP_Vec2();
      var p4:ZPP_Vec2 = new ZPP_Vec2();
      var p5:ZPP_Vec2 = new ZPP_Vec2();
      var d:Number = ZPP_SweepDistance.distance(s1, s2, p3, p4, p5, 1e100);
      trace("[P0PD] " + tag + " d " + bits(d) + " p3 " + bits(p3.x) + " " + bits(p3.y)
        + " p4 " + bits(p4.x) + " " + bits(p4.y) + " p5 " + bits(p5.x) + " " + bits(p5.y));
    }

    private function run():void {
      space = new Space(new Vec2(0, 0)); // no gravity → nothing moves
      mat = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var big:Array = [new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)];
      var small:Array = [new Vec2(-12, -12), new Vec2(12, -12), new Vec2(12, 12), new Vec2(-12, 12)];
      var floor:ZPP_Shape = box(200, 300, big); // spans x[100,300] y[280,320]
      var bFace:ZPP_Shape = box(200, 250, small); // above face → separated, face region
      var bCorner:ZPP_Shape = box(320, 250, small); // up-right of corner → endpoint-endpoint
      var bPen:ZPP_Shape = box(200, 272, small); // bottom y=284 > floor top 280 → overlap
      space.step(1.0 / 60.0, 1, 1); // validate world geometry (gravity 0)
      // both argument orders, to exercise the loc24/swap path
      q("FACE", bFace, floor);
      q("FACEr", floor, bFace);
      q("CORNER", bCorner, floor);
      q("CORNERr", floor, bCorner);
      q("PEN", bPen, floor);
      q("PENr", floor, bPen);
    }
  }
}
