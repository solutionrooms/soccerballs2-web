// CALLING AS3 — oracle: does a free WHEEL on a gentle slope ROLL from rest, or stick/settle?
// (level-36 "ref on wheels": the vehicle settles instead of rolling down a ~4.7° grass slope.)
// Modeled as a flat floor with TILTED GRAVITY = 1000 @ 4.7° → (81.935, 996.638), so the
// horizontal component drives the wheel +x exactly like a 4.7° slope (no tilted-floor trig).
// Wheel = ball_large football material (el=1, fric=0.1, roll=0.1, r35), placed at rest on the
// floor, released. If it rolls: x climbs, vx grows, angVel spins up toward vx/35. If it sticks
// (rolling resistance ≥ the slope's drive): x≈const, angVel≈0. Trace x, vx, angVel, 150 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0RS] DONE"); } catch (e:Error) { trace("[P0RS] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(81.935, 996.638)); // 1000 @ 4.7° down-right
      var mat:Material = new Material(1, 0.1, 0.1, 1.0, 0.1); // football: el=1, fric=0.1, roll=0.1
      var floor:Body = new Body(BodyType.STATIC, new Vec2(300, 400));
      floor.shapes.add(new Polygon(Polygon.box(2000, 40), mat)); // long flat floor, top at 380
      floor.space = space;
      var wheel:Body = new Body(BodyType.DYNAMIC, new Vec2(150, 345)); // r35 rests on floor top (380)
      wheel.shapes.add(new Circle(35, new Vec2(0,0), mat)); wheel.align(); wheel.space = space;
      for (var i:int = 1; i <= 150; i++) {
        space.step(1.0/60.0, 10, 10);
        trace("[P0RS] " + i + " " + bits(wheel.position.x) + " " + bits(wheel.velocity.x) + " " + bits(wheel.angularVel));
      }
    }
  }
}
