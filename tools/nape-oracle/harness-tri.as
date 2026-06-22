// CALLING AS3 (real 2012 nape.* under Ruffle) — capture GeomPoly.triangularDecomposition GOLDEN.
//
// lvl-19 root cause: the shim triangulates terrain with ear-clipping, but 2012 nape uses MONOTONE
// triangulation (ZPP_Monotone.decompose + ZPP_Triangular.triangulate). Different tris → the crate
// catches a different pit edge → level diverges. We're porting the FAITHFUL 2012 pipeline into the
// replica engine; this harness captures its exact output (per-tri verts, bit-exact, IN ORDER) so the
// TS port can be gated against it.
//
// Each polygon is centroid-subtracted exactly like PhysicsBase.InitLines, then run through
// triangularDecomposition(). We dump, per output GeomPoly (triangle), its vertices as f64 bits.
package {
  import flash.display.MovieClip;
  import flash.utils.ByteArray;
  import nape.geom.Vec2;
  import nape.geom.GeomPoly;
  import nape.geom.GeomPolyList;
  import nape.geom.GeomVertexIterator;

  public class Preloader extends MovieClip {
    public function Preloader() { super(); stop();
      try { run(); trace("[TRI] DONE"); } catch (e:Error) { trace("[TRI] ERROR " + e.message + "\n" + e.getStackTrace()); } }

    private function bits(n:Number):String {
      var ba:ByteArray = new ByteArray(); ba.writeDouble(n); ba.position = 0;
      return ba.readUnsignedInt().toString(16) + ":" + ba.readUnsignedInt().toString(16); }

    // centroid-subtract (InitLines), triangulate, dump each output tri bit-exact in order
    private function decomp(name:String, flat:Array):void {
      var cx:Number = 0; var cy:Number = 0; var i:int;
      var pts:Array = [];
      for (i = 0; i < flat.length; i += 2) { pts.push(new Vec2(flat[i], flat[i+1])); cx += flat[i]; cy += flat[i+1]; }
      var n:int = pts.length; cx /= n; cy /= n;
      for each (var v:Vec2 in pts) { v.x -= cx; v.y -= cy; }
      var gp:GeomPoly = new GeomPoly(pts);
      // intermediate: the monotone pieces (decompose output, BEFORE triangulation) — isolates decompose
      var mono:GeomPolyList = gp.monotoneDecomposition();
      trace("[MONO] " + name + " npieces " + mono.length);
      for (var j:int = 0; j < mono.length; j++) {
        var piece:GeomPoly = mono.at(j);
        var mit:GeomVertexIterator = piece.iterator();
        var ms:String = "";
        while (mit.hasNext()) { var mv:Vec2 = mit.next(); ms += " " + bits(mv.x) + " " + bits(mv.y); }
        trace("[MONO] " + name + " p" + j + ms);
      }
      var gpl:GeomPolyList = (new GeomPoly(pts)).triangularDecomposition();
      trace("[TRI] " + name + " centroid " + bits(cx) + " " + bits(cy) + " ntris " + gpl.length);
      for (var k:int = 0; k < gpl.length; k++) {
        var tri:GeomPoly = gpl.at(k);
        var it:GeomVertexIterator = tri.iterator();
        var s:String = "";
        while (it.hasNext()) { var vv:Vec2 = it.next(); s += " " + bits(vv.x) + " " + bits(vv.y); }
        trace("[TRI] " + name + " t" + k + s);
      }
    }

    private function run():void {
      // --- simple test polys (incremental dev) ---
      decomp("quad",  [0,0, 10,0, 10,10, 0,10]);                       // convex
      decomp("Lshape",[0,0, 20,0, 20,10, 10,10, 10,20, 0,20]);         // concave L (split/merge)
      decomp("notch", [0,0, 30,0, 30,20, 20,20, 25,10, 10,10, 15,20, 0,20]); // double-notch (monotone split)
      decomp("star5", [50,0, 61,35, 98,35, 68,57, 79,91, 50,70, 21,91, 32,57, 2,35, 39,35]); // concave star
      // --- the lvl-19 terrain (the real target) ---
      decomp("grass", [-38,-27,-20,-25,9,-12,11,14,14,41,17,68,33,78,63,80,105,82,127,86,135,100,121,112,99,134,59,144,37,158,11,178,12,194,16,233,24,259,44,270,67,259,124,259,170,251,209,260,247,262,271,263,282,265,288,270,284,292,143,312,127,322,121,350,119,370,125,394,133,414,151,424,175,432,233,430,306,429,321,487,375,488,375,437,386,435,430,430,492,438,580,434,608,428,632,422,656,414,676,396,700,378,712,362,728,340,746,321,758,310,798,302,818,300,838,288,854,268,862,218,868,178,874,148,902,128,942,126,996,125,994,565,-152,576,-151,-40]);
      decomp("mud",   [-149,-30,-51,-8,-1,-1,5,62,18,86,34,100,78,105,104,103,126,111,107,137,70,147,46,155,29,166,7,205,13,246,22,268,40,277,65,273,94,280,128,283,171,281,216,281,275,282,278,294,259,301,218,308,187,313,155,326,139,339,131,376,139,404,154,422,165,432,195,440,213,448,242,445,268,451,280,474,292,494,322,499,346,513,354,500,380,494,390,457,413,454,445,454,467,456,501,462,544,467,587,460,629,449,675,432,714,392,730,366,751,353,786,352,799,329,800,320,832,310,848,310,863,300,882,241,885,201,895,167,920,155,962,150,995,150,992,595,-162,602]);
    }
  }
}
