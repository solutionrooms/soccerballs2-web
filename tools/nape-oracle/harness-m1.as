// CALLING AS3 — oracle harness for milestone M1a (rotation + central impulse).
// Replaces the Preloader document class; boots straight into pure Nape tests.
//
//   SPIN: a centred circle given angularVel, under gravity — exercises the
//         angular integrator (drag) + rotation accumulation, alongside linear
//         free-fall. Also traces mass + inertia (circle inertia coefficient).
//   KICK: a centred circle at rest given a central applyImpulse — exercises
//         dv = J·imass, then free integration.
//
// Each value traced as raw IEEE-754 bits (no decimal loss). Inject with FFDec
// (-replace Preloader), capture with capture-lines.mjs (filter "DONE").
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
  import nape.geom.Vec2List;

  public class Preloader extends MovieClip {
    public function Preloader() {
      super();
      stop();
      try {
        runSpin();
        runKick();
        runPoly();
        trace("[M1] DONE");
      } catch (e:Error) {
        trace("[M1] ERROR " + e.message);
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

    private function mkCircle(space:Space, x:Number, y:Number):Body {
      var mat:Material = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      b.shapes.add(new Circle(12, new Vec2(0, 0), mat));
      b.align();
      b.space = space;
      return b;
    }

    private function runSpin():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var b:Body = mkCircle(space, 100, 50);
      b.angularVel = 5.0;
      trace("[SPIN] props " + bits(b.mass) + " " + bits(b.inertia));
      for (var i:int = 1; i <= 180; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[SPIN] " + i + " " + bits(b.position.y) + " " + bits(b.velocity.y)
          + " " + bits(b.rotation) + " " + bits(b.angularVel));
      }
    }

    private function runPoly():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0.3, 0.5, 0.5, 1.0, 0.1);
      var verts:Array = [new Vec2(-20, -12), new Vec2(20, -12), new Vec2(20, 12), new Vec2(-20, 12)];
      var poly:Polygon = new Polygon(verts, mat);
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(100, 50));
      b.shapes.add(poly);
      // trace the vertices Nape actually stored (post-construction order) so the
      // replica computes mass/inertia on the identical verts in the identical order
      var lv:Vec2List = poly.localVerts;
      trace("[POLY] nverts " + lv.length);
      for (var j:int = 0; j < lv.length; j++) {
        var vv:Vec2 = lv.at(j);
        trace("[POLY] vert " + j + " " + bits(vv.x) + " " + bits(vv.y));
      }
      b.align();
      b.space = space;
      b.angularVel = 3.0;
      trace("[POLY] props " + bits(b.mass) + " " + bits(b.inertia));
      for (var i:int = 1; i <= 120; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[POLY] " + i + " " + bits(b.position.y) + " " + bits(b.velocity.y)
          + " " + bits(b.rotation) + " " + bits(b.angularVel));
      }
    }

    private function runKick():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var b:Body = mkCircle(space, 400, 50);
      b.applyImpulse(new Vec2(37, -53));
      trace("[KICK] 0 " + bits(b.position.x) + " " + bits(b.position.y)
        + " " + bits(b.velocity.x) + " " + bits(b.velocity.y));
      for (var i:int = 1; i <= 60; i++) {
        space.step(1.0 / 60.0, 10, 10);
        trace("[KICK] " + i + " " + bits(b.position.x) + " " + bits(b.position.y)
          + " " + bits(b.velocity.x) + " " + bits(b.velocity.y));
      }
    }
  }
}
