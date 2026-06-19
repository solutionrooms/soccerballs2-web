// CALLING AS3 — oracle: WAKE-ON-VELOCITY-MUTATION. Two DYNAMIC balls settle ASLEEP on a
// static floor (~step 61, once at rest 60 stamps). At step 90 — long after both sleep —
// ballI gets Body.applyImpulse(Vec2(0,-100)) and ballV gets velocity = Vec2(0,-300), as
// the game does when it kicks/launches a ball. Decisive test of whether 2012 Nape WAKES a
// sleeping body on velocity mutation (so the new velocity integrates) or ignores it. Balls
// are x-separated (150 vs 250) so they never interact → vertical only, no rotation, no trig.
// Trace each ball's y + vy, 140 steps, raw IEEE-754 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0WV] DONE"); } catch (e:Error) { trace("[P0WV] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon([new Vec2(-150,-20), new Vec2(150,-20), new Vec2(150,20), new Vec2(-150,20)], mat));
      floor.space = space;
      var ballI:Body = new Body(BodyType.DYNAMIC, new Vec2(150, 369)); // impulse ball
      ballI.shapes.add(new Circle(12, new Vec2(0,0), mat)); ballI.align(); ballI.space = space;
      var ballV:Body = new Body(BodyType.DYNAMIC, new Vec2(250, 369)); // set-velocity ball
      ballV.shapes.add(new Circle(12, new Vec2(0,0), mat)); ballV.align(); ballV.space = space;
      for (var i:int = 1; i <= 140; i++) {
        if (i == 90) {
          ballI.applyImpulse(new Vec2(0, -100));
          ballV.velocity = new Vec2(0, -300);
        }
        space.step(1.0/60.0, 10, 10);
        trace("[P0WV] " + i + " I " + bits(ballI.position.y) + " " + bits(ballI.velocity.y)
          + " V " + bits(ballV.position.y) + " " + bits(ballV.velocity.y));
      }
    }
  }
}
