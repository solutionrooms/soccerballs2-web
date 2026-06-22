// CALLING AS3 (real 2012 nape.* under Ruffle) — "sandy rebound" (lvl "19: SANDY REBOUND")
// FULL-SCENE OUTCOME ORACLE.
//
// The blocker: Jon completes this level on the genuine 2012 SWF but NOT on our replica build.
// The win = a BALL reaches the goal mouth @ (193,431), past the crateMetalLarge beside it.
// The f65 ball-vs-terrain contact is bit-identical replica==2012 (gate p0sr), so any divergence
// is in the AGGREGATE chain (release → free-fall → f65 slope bounce → roll left → crate impact
// f113 → does a ball get past the crate INTO the goal?). This harness runs the WHOLE scene in
// REAL 2012 nape and reports: (1) does any ball reach the goal mouth, (2) per-frame roller+crate.
//
// DETERMINISTIC SPEC (agreed with haxe-port, provably == their replica repro):
//   full scene as loaded; switchable_block uid_897828 @747,275 ABSENT at f0 (the green-switch
//   release, modelled as "block never added"); NO kick; all balls at XML rest; gravity (0,1000);
//   dt 1/60, 10/10; 200 steps.
//
// Scene built the game's OWN way:
//   - terrain <line>s via PhysicsBase.InitLines: centroid-subtract → GeomPoly.triangularDecomposition()
//     → static tris; poly_collide_grass=poly_average(el0,fr0.5), poly_collide_mud=poly_mud(el0,fr100).
//   - object polys via PhysicsBase (triangulatePoly=true, hardcoded): the game's Triangulate.process()
//     → tris per shape (so the crate = 2 tris, exactly like the shim). average=(el0.2,fr0.1).
//   - balls: circles, football(el1)/beachball(el1,ρ0.02). Filters per XML col cat/mask (players
//     cat2/mask11 pass balls but block the crate; cannon col0/0 omitted; goal sensor-mouth omitted
//     from physics, used only for win detection).
// Trig caveat: the crate rotates continuously → V8(replica) vs AVM2(this) sin/cos diverge ≤1 ULP,
// so per-frame can't be frame-perfect over a long rotating run — but the OUTCOME (ball reaches goal,
// a 150+px margin) is robust to that. First sharp split = a contact bug; slow drift = trig ceiling.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import flash.geom.Point;
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
  import nape.dynamics.InteractionFilter;

  public class Preloader extends MovieClip {
    private var space:Space;
    private var balls:Array = [];      // {b:Body, r:Number, name:String}
    private var roller:Body;           // uid_315038
    private var crate:Body;
    private var lineN:int = 0;         // terrain-line dump index

    public function Preloader() { super(); stop();
      try { run(); trace("[P0SF] DONE"); } catch (e:Error) { trace("[P0SF] ERROR " + e.message + "\n" + e.getStackTrace()); } }
    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }

    private function mat(el:Number, dfr:Number, sfr:Number, den:Number, rfr:Number):Material {
      return new Material(el, dfr, sfr, den, rfr); }

    // --- terrain line → static tris (InitLines path) ---
    private function addLine(flat:Array, m:Material, cat:int, mask:int):void {
      var cx:Number = 0; var cy:Number = 0; var i:int;
      var pts:Array = [];
      for (i = 0; i < flat.length; i += 2) { pts.push(new Vec2(flat[i], flat[i+1])); cx += flat[i]; cy += flat[i+1]; }
      var n:int = pts.length; cx /= n; cy /= n;
      for each (var v:Vec2 in pts) { v.x -= cx; v.y -= cy; }
      var gpl:GeomPolyList = (new GeomPoly(pts)).triangularDecomposition();
      var b:Body = new Body(BodyType.STATIC, new Vec2(cx, cy));
      var f:InteractionFilter = new InteractionFilter(cat, mask);
      trace("[LINE] " + lineN + " " + bits(cx) + " " + bits(cy));
      for (var k:int = 0; k < gpl.length; k++) {
        var tri:GeomPoly = gpl.at(k);
        var vi:GeomVertexIterator = tri.iterator();
        var verts:String = "";
        while (vi.hasNext()) { var vv:Vec2 = vi.next(); verts += " " + Math.round(vv.x + cx) + " " + Math.round(vv.y + cy); }
        trace("[LTRI] " + lineN + verts);
        b.shapes.add(new Polygon(tri, m, f));
      }
      lineN++;
      b.space = space;
    }

    // --- object poly → tris via the game's Triangulate (triangulatePoly=true path) ---
    private function addObjPoly(x:Number, y:Number, rotDeg:Number, flat:Array, m:Material, cat:int, mask:int, dyn:Boolean):Body {
      var b:Body = new Body(dyn ? BodyType.DYNAMIC : BodyType.STATIC, new Vec2(x, y));
      b.rotation = rotDeg * Math.PI / 180;
      var contour:Array = [];
      for (var i:int = 0; i < flat.length; i += 2) contour.push(new Point(flat[i], flat[i+1]));
      var tv:Array = (new Triangulate()).process(contour);
      var f:InteractionFilter = new InteractionFilter(cat, mask);
      var numTris:int = int(tv.length / 3);
      for (var t:int = 0; t < numTris; t++) {
        var p0:Point = tv[(t*3)+0]; var p1:Point = tv[(t*3)+1]; var p2:Point = tv[(t*3)+2];
        if (dyn) trace("[CTRI] " + p0.x + " " + p0.y + " " + p1.x + " " + p1.y + " " + p2.x + " " + p2.y);
        b.shapes.add(new Polygon([new Vec2(p0.x,p0.y), new Vec2(p1.x,p1.y), new Vec2(p2.x,p2.y)], m, f));
      }
      b.space = space;
      return b;
    }

    private function addBall(x:Number, y:Number, r:Number, m:Material, name:String):Body {
      var b:Body = new Body(BodyType.DYNAMIC, new Vec2(x, y));
      b.shapes.add(new Circle(r, new Vec2(0,0), m, new InteractionFilter(4, 15)));
      b.space = space;
      balls.push({b:b, r:r, name:name});
      return b;
    }

    private function run():void {
      space = new Space(new Vec2(0, 1000));
      var grass:Material = mat(0, 0.5, 0.5, 1, 0.5);    // poly_average
      var mud:Material   = mat(0, 100, 100, 1, 100);    // poly_mud
      var avg:Material   = mat(0.2, 0.1, 0.1, 0.5, 0.1);// average
      var foot:Material  = mat(1, 0.1, 0.1, 0.5, 0.1);  // football
      var beach:Material = mat(1, 0.1, 0.1, 0.02, 0.1); // beachball

      // ---- terrain (grass cat1/mask15, mud cat1/mask15) ----
      addLine([418,318,423,292,433,290,457,292,521,304,538,308,533,323,506,332,462,333,435,327], grass,1,15);
      addLine([534,165,542,162,562,162,581,163,601,164,604,179,592,187,572,189,550,185,532,176], grass,1,15);
      addLine([372,-114,391,-108,404,-93,412,-49,419,-26,427,-5,460,5,488,21,509,27,514,39,487,62,380,25,362,16,354,5,353,-110], grass,1,15);
      addLine([253,9,269,17,292,17,293,41,317,56,327,49,324,20,324,9,321,-114,310,-119,298,-122,284,-118,268,-108,250,-89,255,-68,261,-51,248,-24,239,-14,238,-4], grass,1,15);
      addLine([-38,-27,-20,-25,9,-12,11,14,14,41,17,68,33,78,63,80,105,82,127,86,135,100,121,112,99,134,59,144,37,158,11,178,12,194,16,233,24,259,44,270,67,259,124,259,170,251,209,260,247,262,271,263,282,265,288,270,284,292,143,312,127,322,121,350,119,370,125,394,133,414,151,424,175,432,233,430,306,429,321,487,375,488,375,437,386,435,430,430,492,438,580,434,608,428,632,422,656,414,676,396,700,378,712,362,728,340,746,321,758,310,798,302,818,300,838,288,854,268,862,218,868,178,874,148,902,128,942,126,996,125,994,565,-152,576,-151,-40], grass,1,15);
      addLine([-149,-30,-51,-8,-1,-1,5,62,18,86,34,100,78,105,104,103,126,111,107,137,70,147,46,155,29,166,7,205,13,246,22,268,40,277,65,273,94,280,128,283,171,281,216,281,275,282,278,294,259,301,218,308,187,313,155,326,139,339,131,376,139,404,154,422,165,432,195,440,213,448,242,445,268,451,280,474,292,494,322,499,346,513,354,500,380,494,390,457,413,454,445,454,467,456,501,462,544,467,587,460,629,449,675,432,714,392,730,366,751,353,786,352,799,329,800,320,832,310,848,310,863,300,882,241,885,201,895,167,920,155,962,150,995,150,992,595,-162,602], mud,1,15);
      addLine([283,-92,271,-84,270,-64,273,-40,260,-21,248,-4,243,8,252,15,257,24,269,28,287,33,294,43,303,56,317,56,332,48,322,20,322,8,323,-86,322,-103,310,-107,299,-109,289,-103], mud,1,15);
      addLine([353,-96,363,-101,374,-102,386,-94,390,-83,394,-51,399,-21,403,-7,419,3,429,10,458,19,476,27,492,31,509,38,510,46,501,56,492,61,481,61,377,27,361,18,353,6,354,-61,352,-79], mud,1,15);
      addLine([533,172,550,171,558,172,571,173,581,174,595,175,603,179,603,191,591,193,580,195,573,195,560,194,546,191,531,184], mud,1,15);
      addLine([417,323,429,330,440,336,454,338,475,339,491,339,509,338,519,334,534,326,538,319,533,314,511,311,475,308,451,303,438,301,428,301,420,301], mud,1,15);

      // ---- static objects ----
      var POST:Array = [-6,-28,6,-28,6,28,-6,28];
      addObjPoly(393,68,-67,POST,avg,8,15,false); addObjPoly(447,90,-68,POST,avg,8,15,false);
      addObjPoly(494,113,-56,POST,avg,8,15,false); addObjPoly(523,151,-18,POST,avg,8,15,false);
      addObjPoly(615,151,21,POST,avg,8,15,false);
      var SAND:Array = [0,0,30,0,30,30,0,30];
      addObjPoly(291.03657092472184,266.4325643154192,10.313240312354822,SAND,avg,8,15,false);
      addObjPoly(324.45494386509426,272.8776289587489,10.313240312354822,SAND,avg,8,15,false);
      addObjPoly(357.954098341526,279.4275457349495,10.313240312354822,SAND,avg,8,15,false);
      addObjPoly(390.40478389632216,286.5145512314275,10.313240312354822,SAND,avg,8,15,false);
      var BLOCK:Array = [0,0,30,0,30,30,0,30];
      addObjPoly(322,126,0,BLOCK,avg,8,15,false);   // uid_666082 (present)
      addObjPoly(324,-22,0,BLOCK,avg,8,15,false);   // uid_091881 (present)
      // uid_897828 @747,275 OMITTED — the released block
      var POST80:Array = [-10,-80,10,-80,10,0,-10,0];
      addObjPoly(566,163,0,POST80,avg,2,15,false);  // referee (collides w/ balls)
      addObjPoly(69,258,0,POST80,avg,2,11,false);   // players (cat2/mask11: pass balls, block crate)
      addObjPoly(545,432,0,POST80,avg,2,11,false);
      addObjPoly(120,86,0,POST80,avg,2,11,false);
      addObjPoly(193,431,0,[-23,-4,-6,-85,19,-86,18,-80,0,-79,-16,-3],avg,8,15,false); // goal solid frame

      // ---- dynamic ----
      crate = addObjPoly(398,416,0,[-24,-20,24,-20,24,20,-24,20],avg,8,15,true);
      roller = addBall(762,237,35,foot,"uid_315038");   // FREE — block removed
      addBall(338,88,35,foot,"ball_large_338");
      addBall(339,-38,12,foot,"ball_notplayer");
      addBall(86,247,12,beach,"ball_beachball");

      // goal-mouth sensor poly (world) for win detection: shape2 @ (193,431)
      var goalMouth:Array = [193-11,431-4, 193+3,431-77, 193+14,431-77, 193+14,431-4];
      var firstWin:int = -1;
      var winName:String = "";

      for (var i:int = 1; i <= 400; i++) {
        space.step(1.0/60.0, 10, 10);
        // win check: any ball center inside the goal mouth?
        if (firstWin < 0) {
          for each (var bb:Object in balls) {
            if (pointInPoly(bb.b.position.x, bb.b.position.y, goalMouth)) { firstWin = i; winName = bb.name; break; }
          }
        }
        trace("[P0SF] " + i
          + " R " + bits(roller.position.x) + " " + bits(roller.position.y) + " " + bits(roller.velocity.x) + " " + bits(roller.velocity.y) + " " + bits(roller.rotation)
          + " C " + bits(crate.position.x) + " " + bits(crate.position.y) + " " + bits(crate.velocity.x) + " " + bits(crate.velocity.y) + " " + bits(crate.rotation));
      }
      // summary
      trace("[P0SF] WIN " + (firstWin >= 0 ? (winName + " @f" + firstWin) : "NONE"));
      for each (var b2:Object in balls)
        trace("[P0SF] FINAL " + b2.name + " " + bits(b2.b.position.x) + " " + bits(b2.b.position.y));
      trace("[P0SF] FINAL crate " + bits(crate.position.x) + " " + bits(crate.position.y) + " " + bits(crate.rotation));
    }

    private function pointInPoly(px:Number, py:Number, poly:Array):Boolean {
      var inside:Boolean = false; var n:int = poly.length / 2;
      var j:int = n - 1;
      for (var k:int = 0; k < n; k++) {
        var xi:Number = poly[k*2]; var yi:Number = poly[k*2+1];
        var xj:Number = poly[j*2]; var yj:Number = poly[j*2+1];
        if (((yi > py) != (yj > py)) && (px < (xj - xi) * (py - yi) / (yj - yi) + xi)) inside = !inside;
        j = k;
      }
      return inside;
    }
  }
}
