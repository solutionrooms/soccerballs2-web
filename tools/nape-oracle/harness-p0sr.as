// CALLING AS3 (real 2012 nape.* under Ruffle) — "sandy rebound" (lvl "19: SANDY REBOUND")
// f65 DIVERGENCE ORACLE.
//
// The haxe-port A/B (replica :8753 vs nape-haxe4 :8754, both V8) pinned the whole-level
// divergence to a SINGLE contact at frame 65: the el=1 `ball_large` (uid_315038), in pure
// free-fall (rot==0, w==0 from f55..f64), grazes the right-side grass terrain slope and
// rebounds. Both V8 builds are bit-identical f20..f64, then split at f65:
//     f64 (IDENTICAL): pos(713.018,305.262)  vel(-143.294,221.546)
//     f65 REPLICA    : vel(-191.297, 166.779)
//     f65 NAPE4      : vel(-204.17 , 180.4  )
// Same pre-state, same V8 (NO trig/AVM2 noise) -> a genuine algorithmic restitution diff:
// nape-haxe4 2.0.22 kicks ~13px/s (~6.7%) harder left. This harness asks the REAL 2012 SWF
// which one is faithful.
//
// Scene reproduced EXACTLY via the game's own terrain path (PhysicsBase.InitLines):
//   - The big `poly_collide_grass` line poly of the level (Levels_Data.xml:2767-2775, 68 pts):
//     centroid-subtract -> GeomPoly -> triangularDecomposition() -> STATIC body of triangles,
//     material `poly_average` (density 1, friction 0.5 [static=dyn=roll], elasticity 0).
//   - `ball_large`: solid circle r35, material `football` (density 0.5, friction 0.1, el 1),
//     placed at the f64 pre-state (already 0.23px into edge (728,340)-(746,321)), w=0.
//   - gravity (0,1000), dt 1/60, 10/10 iters — the game's step.
// Combined restitution for the contact = (1 + 0)/2 = 0.5. Ball moves ~4.4px/frame << r35,
// so NO continuous sweep (discrete contact). Single isolated circle-vs-static contact =>
// independent of the rest of the level (b1/b2 dyn-vs-static is bit-invariant).
//
// Decision rule: if SWF f65 vx ~ -204 -> the REPLICA UNDER-REBOUNDS this glancing el=1
// terrain contact (a real engine bug to fix). If ~ -191 -> replica is faithful and the
// bug is downstream / in nape-haxe4 (not the 2012 engine).
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
  import nape.geom.GeomPoly;
  import nape.geom.GeomPolyList;
  import nape.geom.GeomVertexIterator;

  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[P0SR] DONE"); } catch (e:Error) { trace("[P0SR] ERROR " + e.message + "\n" + e.getStackTrace()); } }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }

    // The big poly_collide_grass line of "sandy rebound" — raw points, document order
    // (Levels_Data.xml:2768-2774, one closed concave loop of 68 vertices).
    private static const GRASS:Array = [
      -38,-27, -20,-25, 9,-12, 11,14, 14,41, 17,68, 33,78, 63,80, 105,82, 127,86,
      135,100, 121,112, 99,134, 59,144, 37,158, 11,178, 12,194, 16,233, 24,259, 44,270,
      67,259, 124,259, 170,251, 209,260, 247,262, 271,263, 282,265, 288,270, 284,292, 143,312,
      127,322, 121,350, 119,370, 125,394, 133,414, 151,424, 175,432, 233,430, 306,429, 321,487,
      375,488, 375,437, 386,435, 430,430, 492,438, 580,434, 608,428, 632,422, 656,414, 676,396,
      700,378, 712,362, 728,340, 746,321, 758,310, 798,302, 818,300, 838,288, 854,268, 862,218,
      868,178, 874,148, 902,128, 942,126, 996,125, 994,565, -152,576, -151,-40
    ];

    private function run():void {
      var space:Space = new Space(new Vec2(0, 1000));

      // poly_average (grass collision): density 1, friction_static 0.5,
      // friction_dynamic/rolling default to static (0.5), elasticity 0.
      var grassMat:Material = new Material(0.0, 0.5, 0.5, 1, 0.5); // (el, dynFric, statFric, density, rollFric)

      // ---- Terrain: EXACT PhysicsBase.InitLines path ----
      var cx:Number = 0;
      var cy:Number = 0;
      var i:int;
      var pts:Array = new Array();
      for (i = 0; i < GRASS.length; i += 2) {
        pts.push(new Vec2(GRASS[i], GRASS[i+1]));
        cx += GRASS[i]; cy += GRASS[i+1];
      }
      var n:int = pts.length;        // 68
      cx /= n; cy /= n;
      for each (var v:Vec2 in pts) { v.x -= cx; v.y -= cy; }

      var gp:GeomPoly = new GeomPoly(pts);
      var gpl:GeomPolyList = gp.triangularDecomposition();
      var terrain:Body = new Body(BodyType.STATIC, new Vec2(cx, cy));
      for (var k:int = 0; k < gpl.length; k++) {
        // Dump triangulation connectivity as world-integer vertex triples
        // (local + centroid round-trips to the original integer points), so the
        // gate can rebuild the EXACT triangle soup nape produced.
        var tri:GeomPoly = gpl.at(k);
        var vi:GeomVertexIterator = tri.iterator();
        var verts:String = "";
        while (vi.hasNext()) {
          var vv:Vec2 = vi.next();
          verts += " " + Math.round(vv.x + cx) + " " + Math.round(vv.y + cy);
        }
        trace("[TRI] " + k + verts);
        terrain.shapes.add(new Polygon(tri, grassMat));
      }
      terrain.space = space;
      trace("[P0SR] tris " + gpl.length + " centroid " + bits(cx) + " " + bits(cy));

      // ---- Ball: ball_large, solid circle r35, football material, f64 pre-state ----
      var footMat:Material = new Material(1, 0.1, 0.1, 0.5, 0.1); // (el, dynFric, statFric, density, rollFric)
      var ball:Body = new Body(BodyType.DYNAMIC, new Vec2(713.018, 305.262));
      ball.shapes.add(new Circle(35, new Vec2(0, 0), footMat));
      ball.space = space;
      ball.velocity = new Vec2(-143.294, 221.546);
      ball.angularVel = 0;

      // f64 is the placed state; step -> f65 (the divergence), then onward.
      for (i = 65; i <= 72; i++) {
        space.step(1.0/60.0, 10, 10);
        trace("[P0SR] " + i
          + " " + bits(ball.position.x) + " " + bits(ball.position.y) + " " + bits(ball.rotation)
          + " " + bits(ball.velocity.x) + " " + bits(ball.velocity.y));
      }
    }
  }
}
