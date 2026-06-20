// CALLING AS3 — dumps the ORIGINAL Nape both-dynamic arbiter SOLVE ORDER for the
// level-9 tower, to ground-truth the replica's orderedActiveArbiters(). The tower
// has tied penetration depths (c0-c1 & c1-c2 at 1px, c2-c3 & c3-c4 at 3px), so the
// post-sort order of `c_arbiters_false` (Nape's bottom-up merge sort by oc1.dist,
// strict-< tie-break) depends on the LIST's head->tail INPUT order — which we can't
// derive without reading it. After each of the first few steps we walk
// space.zpp_inner.c_arbiters_false head->tail (= this step's post-sort SOLVE order)
// and emit each arbiter's two body Y-centres + oc1.dist. Body Y identifies the crate
// (c0~399, c1~360, c2~321, c3~284, c4~247, post~222, ballA~180, ballB~108).
package {
  import flash.display.MovieClip;
  import nape.space.Space;
  import nape.phys.Body;
  import nape.phys.BodyType;
  import nape.phys.Material;
  import nape.shape.Polygon;
  import nape.shape.Circle;
  import nape.geom.Vec2;
  import zpp_nape.space.ZPP_Space;
  import zpp_nape.dynamics.ZPP_ColArbiter;
  import zpp_nape.util.ZNPList_ZPP_ColArbiter;
  import zpp_nape.util.ZNPNode_ZPP_ColArbiter;

  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[P0FSO] DONE"); } catch (e:Error) { trace("[P0FSO] ERROR " + e.message); } }

    private function dumpList(tag:String, i:int, list:ZNPList_ZPP_ColArbiter):void {
      var s:String = "[P0FSO] " + i + " " + tag + " :";
      var n:ZNPNode_ZPP_ColArbiter = list.head;
      while (n != null) {
        var a:ZPP_ColArbiter = n.elt;
        // b1y>b2y mapped to integer slot for readability; raw dist appended
        s += " (" + Math.round(a.b1.posy) + "," + Math.round(a.b2.posy) + ")d=" + a.oc1.dist.toFixed(5);
        n = n.next;
      }
      trace(s);
    }

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));
      var avg:Material = new Material(0.2, 0.1, 0.1, 0.5, 0.1);
      var fb:Material  = new Material(1.0, 0.1, 0.1, 0.5, 0.1);

      var floor:Body = new Body(BodyType.STATIC, new Vec2(472, 439));
      floor.shapes.add(new Polygon([new Vec2(-300,-20),new Vec2(300,-20),new Vec2(300,20),new Vec2(-300,20)], avg));
      floor.space = space;

      var cys:Array = new Array(); cys.push(399); cys.push(360); cys.push(321); cys.push(284); cys.push(247);
      for (var k:int = 0; k < 5; k++) {
        var c:Body = new Body(BodyType.DYNAMIC, new Vec2(472, cys[k]));
        c.shapes.add(new Polygon([new Vec2(-24,-20),new Vec2(24,-20),new Vec2(24,20),new Vec2(-24,20)], avg));
        c.align(); c.space = space;
      }
      var post:Body = new Body(BodyType.DYNAMIC, new Vec2(472, 222));
      post.shapes.add(new Polygon([new Vec2(-6,-28),new Vec2(6,-28),new Vec2(6,28),new Vec2(-6,28)], avg));
      post.align(); post.rotation = 89 * Math.PI / 180; post.space = space;
      var b1:Body = new Body(BodyType.DYNAMIC, new Vec2(473, 180));
      b1.shapes.add(new Circle(35, new Vec2(0,0), fb)); b1.align(); b1.space = space;
      var b2:Body = new Body(BodyType.DYNAMIC, new Vec2(479, 108));
      b2.shapes.add(new Circle(35, new Vec2(0,0), fb)); b2.align(); b2.space = space;

      var zsp:ZPP_Space = space.zpp_inner;
      for (var i:int = 1; i <= 5; i++) {
        space.step(1.0/60.0, 10, 10);
        dumpList("FALSE", i, zsp.c_arbiters_false); // both-dynamic, post-sort = solve order
        dumpList("TRUE",  i, zsp.c_arbiters_true);  // has-static
      }
    }
  }
}
