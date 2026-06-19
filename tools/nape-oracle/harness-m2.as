// CALLING AS3 — oracle harness for milestone M2 (broadphase AABB / shape bounds).
// Replaces Preloader; builds unrotated shapes at various positions and traces
// each shape's world-space AABB (Shape.bounds.min/max) as raw IEEE-754 bits.
// Unrotated => sin/cos are exact (0,1) => bit-exact across AVM2/V8.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Circle;
  import nape.shape.Polygon;
  import nape.shape.Shape;
  import nape.geom.Vec2;
  import nape.geom.AABB;

  public class Preloader extends MovieClip {
    private var space:Space;
    private var mat:Material;

    public function Preloader() {
      super();
      stop();
      try {
        space = new Space(new Vec2(0, 1000));
        mat = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
        circleCase("c0", 100, 50, 12);
        circleCase("c1", -30, 200, 7.5);
        boxCase("b0", 300, 80);
        triCase("t0", 50, 400);
        trace("[M2] DONE");
      } catch (e:Error) {
        trace("[M2] ERROR " + e.message);
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

    private function emit(tag:String, s:Shape):void {
      var bb:AABB = s.bounds;
      trace("[M2] " + tag + " " + bits(bb.min.x) + " " + bits(bb.min.y)
        + " " + bits(bb.max.x) + " " + bits(bb.max.y));
    }

    private function circleCase(tag:String, x:Number, y:Number, r:Number):void {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      var c:Circle = new Circle(r, new Vec2(0, 0), mat);
      b.shapes.add(c);
      b.align();
      b.space = space;
      emit(tag, c);
    }

    private function boxCase(tag:String, x:Number, y:Number):void {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      var p:Polygon = new Polygon([new Vec2(-20, -12), new Vec2(20, -12), new Vec2(20, 12), new Vec2(-20, 12)], mat);
      b.shapes.add(p);
      b.align();
      b.space = space;
      emit(tag, p);
    }

    private function triCase(tag:String, x:Number, y:Number):void {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      var p:Polygon = new Polygon([new Vec2(0, -15), new Vec2(13, 10), new Vec2(-13, 10)], mat);
      b.shapes.add(p);
      b.align();
      b.space = space;
      emit(tag, p);
    }
  }
}
