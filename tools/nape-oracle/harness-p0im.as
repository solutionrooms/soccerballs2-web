// CALLING AS3 — oracle: a dynamic ball settles ASLEEP on a static floor; at step 120 it
// is KICKED via the velocity setter (ball.velocity.setxy — the game's Football_Launch
// path). Decisive test of whether 2012 Nape WAKES a sleeping body on a velocity mutation
// (else the kick is silently ignored). Trace ball x, y, vx, vy, 180 steps.
package {
  import flash.display.MovieClip; import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0IM] DONE"); } catch (e:Error) { trace("[P0IM] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon([new Vec2(-100,-20), new Vec2(100,-20), new Vec2(100,20), new Vec2(-100,20)], mat));
      floor.space = space;
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 369));
      ball.shapes.add(new Circle(12, new Vec2(0,0), mat)); ball.align(); ball.space = space;
      for (var i:int = 1; i <= 180; i++) {
        if (i == 120) ball.velocity.setxy(200, -300); // kick a (by now) sleeping ball
        space.step(1.0/60.0, 10, 10);
        trace("[P0IM] " + i + " " + bits(ball.position.x) + " " + bits(ball.position.y) + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y));
      }
    }
  }
}
