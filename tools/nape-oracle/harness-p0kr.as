// CALLING AS3 — oracle: KINEMATIC-vs-RESTING-DYNAMIC restitution (the level-7 "ball sticks to
// the opponent" bug). A dynamic ball (e=1) rests on a static floor; a KINEMATIC wall (e=0.2)
// to its left translates RIGHT at +120 (velocity set every step, the game's SetBodyXForm
// pattern) and strikes the resting ball. Faithful Nape builds the contact relative velocity
// from vel+KINVEL (ZPP_Space.presteparb:4277-4282), so the wall's motion enters restitution:
// combine e=0.6 ⇒ the ball must REBOUND and pull AHEAD of the wall (vx > +120, ~+192), not lock
// to +120 and get carried. The replica stubbed kinvel=0, so the bug is the bounce sign/drop.
// Everything frictionless + axis-aligned ⇒ pure 1-D x, no rotation, no trig. Trace ball.x,
// ball.vx, wall.x for 90 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0KR] DONE"); } catch (e:Error) { trace("[P0KR] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var floorMat:Material = new Material(0, 0, 0, 1.0, 0);   // e=0, frictionless
      var ballMat:Material  = new Material(1, 0, 0, 1.0, 0);   // e=1
      var wallMat:Material  = new Material(0.2, 0, 0, 1.0, 0); // e=0.2 → combine 0.6
      var floor:Body = new Body(BodyType.STATIC, new Vec2(300, 440));
      floor.shapes.add(new Polygon(Polygon.box(600, 40), floorMat));
      floor.space = space;
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(300, 400)); // r=20 rests on floor top (420)
      ball.shapes.add(new Circle(20, new Vec2(0, 0), ballMat)); ball.space = space;
      var wall:Body = new Body(BodyType.KINEMATIC, new Vec2(200, 400)); // right face at 220, moving +120
      wall.shapes.add(new Polygon(Polygon.box(40, 200), wallMat)); wall.space = space;
      for (var i:int = 1; i <= 90; i++) {
        wall.velocity = new Vec2(120, 0); // game re-sets kinematic velocity each step
        space.step(1.0/60.0, 10, 10);
        trace("[P0KR] " + i + " " + bits(ball.position.x) + " " + bits(ball.velocity.x) + " " + bits(wall.position.x));
      }
    }
  }
}
