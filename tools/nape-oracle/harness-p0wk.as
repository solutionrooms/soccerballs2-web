// CALLING AS3 — oracle harness for WAKE-ON-CONTACT (E3). A bottom ball rests on a
// static floor and SLEEPS (~step 61, once at rest for 60 stamps). A top ball starts
// far above and free-falls, striking the sleeping bottom ball well after it slept —
// the impact must WAKE it (its island links to the moving ball, so it re-enters the
// solver and responds). Both balls share x=200 → vertical, no rotation, no trig.
// We trace both balls' y + vy, 120 steps, raw IEEE-754 bits.
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
      try { run(); trace("[P0WK] DONE"); }
      catch (e:Error) { trace("[P0WK] ERROR " + e.message); }
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
      var bot:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 369)); // settles to 368.2, sleeps ~step 61
      bot.shapes.add(new Circle(12, new Vec2(0, 0), mat)); bot.align(); bot.space = space;
      var top:Body = new Body(BodyType.DYNAMIC, new Vec2(200, -440)); // falls, hits the sleeping bot ~step 75
      top.shapes.add(new Circle(12, new Vec2(0, 0), mat)); top.align(); top.space = space;
      for (var i:int = 1; i <= 120; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0WK] " + i + " bot " + bits(bot.position.y) + " " + bits(bot.velocity.y)
          + " top " + bits(top.position.y) + " " + bits(top.velocity.y));
      }
    }
  }
}
