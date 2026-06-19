// CALLING AS3 — oracle: ONGOING contact events (drives onHitPersistFunction; level-8
// switch_weight + wind are broken because the replica emits BEGIN only). A dynamic block
// falls onto a static floor; we register BEGIN + ONGOING collision listeners and trace the
// step each fires, plus the block's isSleeping flag every step. Pins the faithful semantics:
// (1) which step ONGOING starts relative to BEGIN, (2) that ONGOING fires EVERY step while
// the arbiter is awake, (3) that it STOPS once the block sleeps (ZPP_Space.as:1903-1919 skips
// dispatch when all arbiters sleep — the game's velocity nudge keeps the block awake). Boxes
// are centered (COM=origin) → no align, no rotation, no trig. 130 steps.
package {
  import flash.display.MovieClip;
  import nape.space.Space; import nape.phys.Body; import nape.phys.BodyType;
  import nape.phys.Material; import nape.shape.Polygon; import nape.geom.Vec2;
  import nape.callbacks.InteractionListener; import nape.callbacks.CbEvent;
  import nape.callbacks.CbType; import nape.callbacks.InteractionType;
  import nape.callbacks.InteractionCallback;
  public class Preloader extends MovieClip {
    private var curStep:int = 0;
    public function Preloader() { super(); stop(); try { run(); trace("[P0OG] DONE"); } catch (e:Error) { trace("[P0OG] ERROR " + e.message); } }
    private function onBegin(cb:InteractionCallback):void { trace("[P0OG] BEGIN " + curStep); }
    private function onOngoing(cb:InteractionCallback):void { trace("[P0OG] ONGOING " + curStep); }
    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var mat:Material = new Material(0, 0.5, 0.5, 1.0, 0.1);
      space.listeners.add(new InteractionListener(CbEvent.BEGIN, InteractionType.COLLISION, CbType.ANY_BODY, CbType.ANY_BODY, onBegin));
      space.listeners.add(new InteractionListener(CbEvent.ONGOING, InteractionType.COLLISION, CbType.ANY_BODY, CbType.ANY_BODY, onOngoing));
      var floor:Body = new Body(BodyType.STATIC, new Vec2(200, 400));
      floor.shapes.add(new Polygon(Polygon.box(300, 40), mat));
      floor.space = space;
      var block:Body = new Body(BodyType.DYNAMIC, new Vec2(200, 330)); // falls ~30px onto the floor top (380), center rests 360
      block.shapes.add(new Polygon(Polygon.box(40, 40), mat));
      block.space = space;
      for (var i:int = 1; i <= 130; i++) {
        curStep = i;
        space.step(1.0/60.0, 10, 10);
        trace("[P0OG] STEP " + i + " sleeping=" + (block.isSleeping ? 1 : 0));
      }
    }
  }
}
