// CALLING AS3 — oracle: OFFSET-COM body position semantics. A DYNAMIC body with a
// feet-origin offset polygon (verts y∈[−80,0], same shape as the game's character bodies)
// is placed at (200,416) and dropped onto a static floor (top at y=480). The game and the
// live haxe shim NEVER call body.align() — so real Nape keeps body.position at the PLACEMENT
// ORIGIN (≈416, falling to ≈480 at rest), with the COM (origin+(0,−40)=376→440) tracked
// separately. Decisive test that 2012 Nape reports the origin, not the COM — the bug was the
// replica's finalizeBody auto-align()ing every dynamic body onto its COM (a vestige of the
// defunct Box2D-parity NapeWorld.hx), so getX/getY returned 376 not 416 and broke the
// level-7 opponent_patrol turn-around. localCOMx=0 + vertical gravity ⇒ zero gravity-torque
// ⇒ stays upright, rotation≡0, no trig. Trace position.x, position.y, rotation, 120 steps.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Circle; import nape.shape.Polygon; import nape.geom.Vec2;
  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop(); try { run(); trace("[P0OM] DONE"); } catch (e:Error) { trace("[P0OM] ERROR " + e.message); } }
    private function bits(n:Number):String { var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0; return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 500));
      floor.shapes.add(new Polygon([new Vec2(-150,-20), new Vec2(150,-20), new Vec2(150,20), new Vec2(-150,20)], mat));
      floor.space = space;
      var bar:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 416)); // feet-origin: verts span y∈[−80,0]
      bar.shapes.add(new Polygon([new Vec2(-10,-80), new Vec2(10,-80), new Vec2(10,0), new Vec2(-10,0)], mat));
      bar.space = space; // NB: no bar.align() — exactly as the game/shim leave it
      for (var i:int = 1; i <= 120; i++) {
        space.step(1.0/60.0, 10, 10);
        trace("[P0OM] " + i + " " + bits(bar.position.x) + " " + bits(bar.position.y) + " " + bits(bar.rotation));
      }
    }
  }
}
