// CALLING AS3 — oracle harness for P0a (circle-vertex contact, ptype 2).
// A dynamic circle is placed directly above a polygon CORNER, slightly penetrating,
// at rest. Its centre is directly over the corner so the contact normal is vertical
// → it balances on the corner (a stable vertex contact) and settles via the discrete
// solver's ptype-2 (circle-vertex) position correction. No CCD (slow). 60 steps.
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
      try {
        run();
        trace("[P0A] DONE");
      } catch (e:Error) {
        trace("[P0A] ERROR " + e.message);
      }
    }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray();
      ba.writeDouble(n);
      ba.position = 0;
      var hi:uint = ba.readUnsignedInt();
      var lo:uint = ba.readUnsignedInt();
      return hi.toString(16) + ":" + lo.toString(16);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      // static box centred at (200,300): top edge y=280, spans x in [100,300];
      // top-right corner at (300,280).
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 300));
      floor.shapes.add(new Polygon([new Vec2(-100, -20), new Vec2(100, -20), new Vec2(100, 20), new Vec2(-100, 20)], mat));
      floor.space = space;
      // ball centre directly above the corner (300, ~270): closest feature is the
      // corner vertex; centre over it → vertical normal → balances.
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(300, 270));
      ball.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      ball.align();
      ball.space = space;
      for (var i:int = 1; i <= 60; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[P0A] " + i + " " + bits(ball.position.x) + " " + bits(ball.position.y)
          + " " + bits(ball.rotation) + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y)
          + " " + bits(ball.angularVel));
      }
    }
  }
}
