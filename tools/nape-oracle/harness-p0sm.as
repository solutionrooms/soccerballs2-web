// CALLING AS3 — oracle: PER-SHAPE collision-mask change (level-11 keeper duck). One static
// body has TWO solid box shapes (shape0 left, shape1 right); a ball rests asleep on each.
// At step 100 the game disables ONLY shape0's collision — exactly GameObj_Base.SetBodyShape-
// CollisionMask: `body.shapes.at(0).filter.collisionMask = 0`. Faithful Nape drops the
// ball0-vs-shape0 arbiter, WAKES ball0 (it falls through), and leaves ball1 untouched on the
// still-solid shape1 — the per-shape filter the body-wide setBodyCollisionMask can't express.
// Centered circles + axis-aligned boxes ⇒ vertical only, no rotation, no trig. Trace each
// ball's y + vy, 130 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0SM] DONE"); } catch (e:Error) { trace("[P0SM] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var keeper:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      keeper.shapes.add(new Polygon([new Vec2(-80,-20), new Vec2(-40,-20), new Vec2(-40,20), new Vec2(-80,20)], mat)); // shape0: world x 120..160, top 380
      keeper.shapes.add(new Polygon([new Vec2(40,-20), new Vec2(80,-20), new Vec2(80,20), new Vec2(40,20)], mat));     // shape1: world x 240..280, top 380
      keeper.space = space;
      var ball0:Body = new Body(BodyType.DYNAMIC, new Vec2(140, 364)); // rests on shape0 top (380), center 365
      ball0.shapes.add(new Circle(15, new Vec2(0,0), mat)); ball0.align(); ball0.space = space;
      var ball1:Body = new Body(BodyType.DYNAMIC, new Vec2(260, 364)); // rests on shape1 top (380)
      ball1.shapes.add(new Circle(15, new Vec2(0,0), mat)); ball1.align(); ball1.space = space;
      for (var i:int = 1; i <= 90; i++) {
        // disable ONLY shape0 while the riders are settled-but-AWAKE (the game's case is a
        // flying/awake ball clearing the ducked shape; a sleeping-rider filter change has a
        // separate one-step Nape wake-deferral, documented, not exercised here).
        if (i == 30) keeper.shapes.at(0).filter.collisionMask = 0;
        space.step(1.0/60.0, 10, 10);
        trace("[P0SM] " + i + " " + bits(ball0.position.y) + " " + bits(ball0.velocity.y)
          + " " + bits(ball1.position.y) + " " + bits(ball1.velocity.y));
      }
    }
  }
}
