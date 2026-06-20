// CALLING AS3 — TOLERANCE SWEEP: football into a 2-crate seam at varying aim Y.
// Jon: the original breaks BOTH crates across a WIDE range of aims; ours only at
// the exact seam. To break a crate, Vec2(crate.normalImpulse(ball).xy).length/mass
// must reach 150. At the seam (y=340) the ball hits both LEFT FACES; off-centre it
// hits one face and the other crate's CORNER (vertex). This sweeps the ball's aim
// Y and reports each crate's PEAK break-input l, so we can read off the original's
// "both break" Y-window and compare it to the replica's.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.shape.Circle;
  import nape.geom.Vec2;
  import nape.geom.Vec3;

  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[P0TO] DONE"); } catch (e:Error) { trace("[P0TO] ERROR " + e.message); } }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function breakLen(ref:Body, ball:Body):Number {
      var v:Vec3 = ref.normalImpulse(ball); return Math.sqrt(v.x*v.x + v.y*v.y); }

    private function shot(ballY:Number):void {
      var space:Space = new Space(new Vec2(0, 1000));
      var cm:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1);
      var bm:Material = new Material(1.0, 0.1, 0.1, 0.5, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon([new Vec2(-100,-20), new Vec2(100,-20), new Vec2(100,20), new Vec2(-100,20)], cm));
      floor.space = space;
      var cB:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 360)); // spans 340..380
      cB.shapes.add(new Polygon([new Vec2(-24,-20),new Vec2(24,-20),new Vec2(24,20),new Vec2(-24,20)], cm)); cB.align(); cB.space = space;
      var cT:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 320)); // spans 300..340 (seam y=340)
      cT.shapes.add(new Polygon([new Vec2(-24,-20),new Vec2(24,-20),new Vec2(24,20),new Vec2(-24,20)], cm)); cT.align(); cT.space = space;
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(120, ballY));
      ball.shapes.add(new Circle(12, new Vec2(0,0), bm)); ball.align(); ball.space = space;
      ball.velocity = new Vec2(700, 0);
      var maxT:Number = 0;
      var maxB:Number = 0;
      for (var i:int = 1; i <= 12; i++) {
        space.step(1.0/60.0, 10, 10);
        var lt:Number = breakLen(cT, ball); if (lt > maxT) maxT = lt;
        var lb:Number = breakLen(cB, ball); if (lb > maxB) maxB = lb;
      }
      trace("[P0TO] " + ballY + " " + bits(maxT) + " " + bits(maxB));
    }

    private function run():void {
      // seam at y=340; ball radius 12 spans the seam for Y in ~328..352
      for (var y:Number = 326; y <= 354; y += 2) shot(y);
    }
  }
}
