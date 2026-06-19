// CALLING AS3 — oracle harness for DYNAMIC-DYNAMIC circle-circle (ball ↔ ball).
// Two DYNAMIC balls stacked vertically, resting on a static floor, slightly
// penetrating, at rest. The top↔bottom contact is dynamic-vs-dynamic circle-circle
// (both bodies move; impulse + position correction apply to BOTH with nonzero
// imass) — the case the single-dynamic-body test did NOT cover. We trace the TOP
// ball; it depends entirely on the dynamic-dynamic contact, so a bit-exact match
// proves the two-body response. No CCD (slow). 60 steps.
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
      try { run(); trace("[P0CC2] DONE"); }
      catch (e:Error) { trace("[P0CC2] ERROR " + e.message); }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400)); // top face y=380
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat));
      floor.space = space;
      var bot:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 369)); // penetrates floor by 1
      bot.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      bot.align();
      bot.space = space;
      var top:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 346)); // penetrates bot by 1
      top.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      top.align();
      top.space = space;
      for (var i:int = 1; i <= 60; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0CC2] " + i + " " + bits(top.position.x) + " " + bits(top.position.y)
          + " " + bits(top.rotation) + " " + bits(top.velocity.x) + " " + bits(top.velocity.y)
          + " " + bits(top.angularVel)
          + " B " + bits(bot.position.y) + " " + bits(bot.velocity.y));
      }
    }
  }
}
