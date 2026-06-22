// CALLING AS3 — reproduce Jon's level-9 kick against the REAL original Nape.
// Kick: football (r12, `football` e=1) teleported to (110,446) with launch
// velocity (798,-381) — the exact sb2ReplayKick Jon uses. It flies into the
// crate tower (5 crates `average`, post at 89°, 2 big balls) and we trace, every
// frame, the ball's (x,y,vx,vy) AND each crate's BREAK-INPUT
// l = Vec2(crate.normalImpulse(ball).xy).length / ballMass  (break if l>=150).
// Jon's live port breaks only the bottom crate (l=365) and gives the one above
// l=0; the original destroys BOTH. This captures what the ORIGINAL does on the
// same shot so we can diff trajectory + per-crate impulse. (No terrain between
// kick and tower — Jon says the ball goes direct to the crates.)
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
  import nape.geom.Vec3;

  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[P0K9] DONE"); } catch (e:Error) { trace("[P0K9] ERROR " + e.message); } }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function bl(ref:Body, ball:Body):Number {
      var v:Vec3 = ref.normalImpulse(ball); return Math.sqrt(v.x*v.x + v.y*v.y); }

    private var crates:Array = [];
    private function crate(space:Space, cy:Number, m:Material):Body {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(472, cy));
      b.shapes.add(new Polygon([new Vec2(-24,-20),new Vec2(24,-20),new Vec2(24,20),new Vec2(-24,20)], m));
      b.align(); b.space = space; crates.push(b); return b; }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var avg:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1);
      var fb:Material  = new Material(1.0, 0.1, 0.1, 0.5, 0.1);
      // floor only under the tower (so crates rest; ball flies in from the left)
      var floor:Body = new Body(BodyType.STATIC, new Vec2(472, 439));
      floor.shapes.add(new Polygon([new Vec2(-120,-20),new Vec2(120,-20),new Vec2(120,20),new Vec2(-120,20)], avg));
      floor.space = space;
      crate(space, 399, avg); crate(space, 360, avg); crate(space, 321, avg); crate(space, 284, avg); crate(space, 247, avg);
      var post:Body = new Body(BodyType.DYNAMIC, new Vec2(472, 222));
      post.shapes.add(new Polygon([new Vec2(-6,-28),new Vec2(6,-28),new Vec2(6,28),new Vec2(-6,28)], avg));
      post.align(); post.rotation = 89*Math.PI/180; post.space = space;
      var bA:Body = new Body(BodyType.DYNAMIC, new Vec2(473,180)); bA.shapes.add(new Circle(35,new Vec2(0,0),fb)); bA.align(); bA.space=space;
      var bB:Body = new Body(BodyType.DYNAMIC, new Vec2(479,108)); bB.shapes.add(new Circle(35,new Vec2(0,0),fb)); bB.align(); bB.space=space;
      // settle the tower a few frames, THEN launch the ball (matches load-then-kick)
      for (var s:int = 0; s < 10; s++) space.step(1.0/60.0, 10, 10);
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(110,446)); ball.shapes.add(new Circle(12,new Vec2(0,0),fb)); ball.align(); ball.space=space;
      ball.velocity = new Vec2(798,-381);
      for (var i:int = 1; i <= 70; i++) {
        space.step(1.0/60.0, 10, 10);
        trace("[P0K9] " + i + " " + bits(ball.position.x) + " " + bits(ball.position.y)
          + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y)
          + " " + bits(bl(crates[0],ball)) + " " + bits(bl(crates[1],ball)) + " " + bits(bl(crates[2],ball))
          + " " + bits(bl(crates[3],ball)) + " " + bits(bl(crates[4],ball)));
      }
    }
  }
}
