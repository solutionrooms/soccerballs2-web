// CALLING AS3 — FULL level-9 "ball blocker" tower settling vs the replica.
// The real structure (bottom->top): 5 crates (48x40, `average`) stacked, a metal
// post (12x56 bar, `average`) lying at ~89deg across the top, and TWO big balls
// (r35, `football`) above it — an 8-body island balanced on a static floor. My
// isolated 3-crate test settles bit-exact, but Jon reports the LIVE level is
// "nowhere near" the original. A tall, near-unstable loaded tower is where tiny
// solver-order accumulation (harmless in a short stable stack) would diverge over
// time, leaving the whole structure positioned differently => the ball then hits a
// different thing. This settles the tower 150 frames and traces every body's
// (x,y,rot) so we can compare the replica to the original frame-for-frame.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.shape.Circle;
  import nape.geom.Vec2;

  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[P0FS] DONE"); } catch (e:Error) { trace("[P0FS] ERROR " + e.message); } }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }

    private var bodies:Array = [];
    private var names:Array = [];
    private function add(b:Body, nm:String):void { bodies.push(b); names.push(nm); }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var avg:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1);  // `average`
      var fb:Material  = new Material(1.0, 0.1, 0.1, 0.5, 0.1);  // `football`

      var floor:Body = new Body(BodyType.STATIC, new Vec2(472, 439)); // top y=419
      floor.shapes.add(new Polygon([new Vec2(-300,-20),new Vec2(300,-20),new Vec2(300,20),new Vec2(-300,20)], avg));
      floor.space = space;

      // 5 crates at the real level-9 Y positions (x=472)
      var cys:Array = new Array(); cys.push(399); cys.push(360); cys.push(321); cys.push(284); cys.push(247);
      for (var k:int = 0; k < 5; k++) {
        var c:Body = new Body(BodyType.DYNAMIC, new Vec2(472, cys[k]));
        c.shapes.add(new Polygon([new Vec2(-24,-20),new Vec2(24,-20),new Vec2(24,20),new Vec2(-24,20)], avg));
        c.align(); c.space = space; add(c, "c" + k);
      }
      // metal post (12x56), real pos (472,222) rot 89deg
      var post:Body = new Body(BodyType.DYNAMIC, new Vec2(472, 222));
      post.shapes.add(new Polygon([new Vec2(-6,-28),new Vec2(6,-28),new Vec2(6,28),new Vec2(-6,28)], avg));
      post.align(); post.rotation = 89 * Math.PI / 180; post.space = space; add(post, "post");
      // two big balls (r35) above
      var b1:Body = new Body(BodyType.DYNAMIC, new Vec2(473, 180));
      b1.shapes.add(new Circle(35, new Vec2(0,0), fb)); b1.align(); b1.space = space; add(b1, "ballA");
      var b2:Body = new Body(BodyType.DYNAMIC, new Vec2(479, 108));
      b2.shapes.add(new Circle(35, new Vec2(0,0), fb)); b2.align(); b2.space = space; add(b2, "ballB");

      for (var i:int = 1; i <= 150; i++) {
        space.step(1.0/60.0, 10, 10);
        if (i == 1 || i == 30 || i == 60 || i == 90 || i == 120 || i == 150) {
          for (var j:int = 0; j < bodies.length; j++) {
            var b:Body = bodies[j];
            trace("[P0FS] " + i + " " + names[j] + " " + bits(b.position.x) + " " + bits(b.position.y) + " " + bits(b.rotation));
          }
        }
      }
    }
  }
}
