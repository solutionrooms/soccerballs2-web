// CALLING AS3 — oracle harness for M4-CCD-a (ZPP_SweepDistance.distance).
// Calls the ORIGINAL internal closest-distance query directly for several
// circle-vs-polygon and circle-vs-circle configurations (face region, vertex
// region, penetrating, separated), tracing the returned signed distance and the
// witness points/normal (param3 = point on shape1, param4 = on shape2, param5 =
// normal). This isolates the distance primitive that staticSweep/CCD builds on.
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
  import zpp_nape.geom.ZPP_SweepDistance;
  import zpp_nape.geom.ZPP_Vec2;
  import zpp_nape.shape.ZPP_Shape;

  public class Preloader extends MovieClip {
    private var space:Space;
    private var mat:Material;

    public function Preloader() {
      super();
      stop();
      try {
        run();
        trace("[M4CD] DONE");
      } catch (e:Error) {
        trace("[M4CD] ERROR " + e.message);
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

    private function circ(x:Number, y:Number, r:Number):ZPP_Shape {
      var b:Body = new Body(BodyType.STATIC, new Vec2(x, y));
      b.shapes.add(new Circle(r, new Vec2(0, 0), mat));
      b.space = space;
      return b.shapes.at(0).zpp_inner;
    }
    private function poly(x:Number, y:Number, verts:Array):ZPP_Shape {
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
      trace("[M4CD] " + tag + " d " + bits(d) + " p3 " + bits(p3.x) + " " + bits(p3.y)
        + " p4 " + bits(p4.x) + " " + bits(p4.y) + " p5 " + bits(p5.x) + " " + bits(p5.y));
    }

    private function run():void {
      space = new Space(new Vec2(0, 0)); // no gravity → nothing moves
      mat = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var box:Array = [new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)];
      // floor centred at (200,300): top face y=280, spans x in [100,300]
      var floor:ZPP_Shape = poly(200, 300, box);
      var cFace:ZPP_Shape = circ(200, 250, 12); // above the face → separated, face region
      var cVert:ZPP_Shape = circ(320, 250, 12); // off the right corner → vertex region
      var cPen:ZPP_Shape = circ(200, 275, 12);  // overlapping → negative distance, face region
      var cc1:ZPP_Shape = circ(100, 100, 12);
      var cc2:ZPP_Shape = circ(150, 100, 15);
      space.step(1.0 / 60.0, 1, 1); // validate ALL shapes' world geometry (gravity 0)
      q("FACE", cFace, floor);
      q("VERT", cVert, floor);
      q("PEN", cPen, floor);
      q("CC", cc1, cc2);
    }
  }
}
