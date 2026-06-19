// CALLING AS3 — oracle: a dynamic ball settles ASLEEP on a static block; at step 120 the
// block is REMOVED from the space (as the game does, GameObj_Base.RemovePhysObj →
// space.bodies.remove). Decisive test of whether 2012 Nape WAKES the resting ball on
// removal (sand-block mechanic) — or leaves it frozen. Trace ball y + vy, 180 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0RM] DONE"); } catch (e:Error) { trace("[P0RM] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var block:Body = new Body(BodyType.STATIC, new Vec2(300, 300));
      block.shapes.add(new Polygon([new Vec2(-50,-15), new Vec2(50,-15), new Vec2(50,15), new Vec2(-50,15)], mat));
      block.space = space;
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(300, 235));
      ball.shapes.add(new Circle(35, new Vec2(0,0), mat)); ball.align(); ball.space = space;
      for (var i:int = 1; i <= 180; i++) {
        if (i == 120) space.bodies.remove(block);
        space.step(1.0/60.0, 10, 10);
        trace("[P0RM] " + i + " " + bits(ball.position.y) + " " + bits(ball.velocity.y));
      }
    }
  }
}
