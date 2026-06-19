// CALLING AS3 — oracle harness for SLEEPING (E3 verification).
// Two dynamic balls stacked on a static floor, run for 240 steps — well past the
// 60-stamp sleep gate (atRest accumulator). In the ORIGINAL, once both balls are at
// rest for 60 consecutive stamps the island sleeps and they FREEZE. This golden
// lets us check whether our (no-sleep) replica diverges when the original sleeps —
// i.e. whether the awake resting equilibrium is the same fixed point as the frozen
// state. We trace the top ball's full state + the bottom ball y/vy, raw IEEE-754.
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
      try { run(); trace("[P0SL] DONE"); }
      catch (e:Error) { trace("[P0SL] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat));
      floor.space = space;
      var bot:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 369));
      bot.shapes.add(new Circle(12, new Vec2(0, 0), mat)); bot.align(); bot.space = space;
      var top:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 346));
      top.shapes.add(new Circle(12, new Vec2(0, 0), mat)); top.align(); top.space = space;
      for (var i:int = 1; i <= 240; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0SL] " + i + " " + bits(top.position.x) + " " + bits(top.position.y)
          + " " + bits(top.rotation) + " " + bits(top.velocity.x) + " " + bits(top.velocity.y)
          + " " + bits(top.angularVel)
          + " B " + bits(bot.position.y) + " " + bits(bot.velocity.y));
      }
    }
  }
}
