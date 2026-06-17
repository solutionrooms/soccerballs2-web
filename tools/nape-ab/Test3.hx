// Faithful headless reconstruction of the LEVEL 9 wall bounce, to find why the port applies MUD
// friction (3.16) where the original applies GRASS friction (0.22). Builds the REAL level-9
// colliders (poly_collide_grass -> poly_average fric0.5, poly_collide_mud -> poly_mud fric100)
// exactly as PhysicsBase.InitLines does: centroid-offset the points, GeomPoly.triangularDecomposition,
// static body at centroid. Then fires a football (el1, fric0.1) into the vertical wall segment and
// logs, per frame, EVERY ball contact: surface name, normal, combined friction, penetration depth.
//   haxe -cp tools/nape-ab -lib nape-haxe4 -main Test3 -neko /tmp/t3.n && neko /tmp/t3.n
import nape.geom.Vec2;
import nape.geom.GeomPoly;
import nape.geom.GeomPolyList;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.dynamics.Arbiter;
import nape.dynamics.CollisionArbiter;
import nape.space.Space;

class Test3 {
    // Real level-9 line points (from SoccerBalls2_Levels_Data.xml lines 1172-1195).
    static var GRASS : Array<Float> = [
        -207,366, -125,360, -89,360, -59,362, -28,369, -4,378, 43,398, 88,417, 109,426, 150,429,
        177,425, 194,410, 210,356, 214,327, 209,291, 214,260, 219,237, 228,222, 252,197, 259,239,
        309,233, 308,192, 369,182, 449,183, 516,188, 581,185, 638,180, 681,177, 702,171, 713,156,
        725,132, 735,115, 744,91, 764,79, 794,73, 833,73, 875,76, 912,85, 928,112, 945,150,
        942,189, 945,213, 942,232, 935,246, 879,248, 811,231, 750,239, 371,297, 337,305, 312,317,
        286,333, 279,354, 273,386, 273,414, 288,429, 307,435, 485,426, 539,423, 576,417, 642,415,
        692,410, 733,391, 780,390, 852,389, 949,366, 997,353, 1009,336, 1063,335, 1095,314, 1109,285,
        1124,257, 1132,225, 1137,201, 1159,183, 1254,178, 1266,560, -219,588
    ];
    static var MUD : Array<Float> = [
        280,360, 259,365, 240,353, 229,312, 229,274, 238,253, 253,250, 266,252, 286,257, 304,255,
        322,243, 332,231, 347,220, 379,213, 410,211, 456,209, 502,211, 538,213, 580,214, 606,213,
        649,207, 678,202, 702,192, 732,172, 749,153, 768,134, 799,122, 828,116, 856,115, 890,118,
        912,128, 928,149, 921,169, 924,201, 924,221, 923,246, 913,260, 883,259, 826,242, 756,250,
        674,265, 571,280, 571,309, 541,297, 498,291, 469,300, 450,315, 430,322, 430,296, 376,301,
        319,315, 294,335
    ];

    static function buildPoly(sp:Space, flat:Array<Float>, mat:Material, name:String) {
        // Replicates PhysicsBase.InitLines: centroid of ALL points, offset, GeomPoly, triangulate,
        // static body at centroid.
        var pts:Array<Vec2> = [];
        var cx = 0.0; var cy = 0.0;
        var i = 0;
        while (i < flat.length) { pts.push(new Vec2(flat[i], flat[i+1])); cx += flat[i]; cy += flat[i+1]; i += 2; }
        var n = pts.length;
        cx /= n; cy /= n;
        for (v in pts) { v.x -= cx; v.y -= cy; }
        var gp = new GeomPoly(pts);
        var gpl:GeomPolyList = gp.triangularDecomposition();
        var b = new Body(BodyType.STATIC, new Vec2(cx, cy));
        for (k in 0...gpl.length) {
            var poly = new Polygon(gpl.at(k), mat);
            poly.userData.data = { name: name };
            b.shapes.add(poly);
        }
        sp.bodies.add(b);
        Sys.println("built " + name + ": " + n + " pts -> " + gpl.length + " triangles, centroid=(" + Math.round(cx) + "," + Math.round(cy) + ")");
    }

    static function surfName(s:Dynamic):String { try { return s.userData.data.name; } catch (e:Dynamic) { return "?"; } }

    static function probe(sp:Space, ball:Body, frame:Int) {
        var arbs = ball.arbiters;
        for (j in 0...arbs.length) {
            var ar:Arbiter = arbs.at(j);
            if (!ar.isCollisionArbiter()) continue;
            var ca:CollisionArbiter = ar.collisionArbiter;
            var other = (ar.shape1.body == ball) ? ar.shape2 : ar.shape1;
            var nrm = ca.normal;
            Sys.println("  f" + frame + " HIT surf=" + surfName(other)
                + " combF=" + (Math.round(ca.dynamicFriction * 100) / 100)
                + " normal=(" + (Math.round(nrm.x * 100) / 100) + "," + (Math.round(nrm.y * 100) / 100) + ")"
                + " ballVel=(" + Math.round(ball.velocity.x) + "," + Math.round(ball.velocity.y) + ")"
                + " spin=" + (Math.round(ball.angularVel * 100) / 100)
                + " pos=(" + Math.round(ball.position.x) + "," + Math.round(ball.position.y) + ")");
        }
    }

    static function shoot(label:String, startx:Float, starty:Float, vx:Float, vy:Float, bullet:Bool) {
        Sys.println("\n=== " + label + " start=(" + startx + "," + starty + ") vel=(" + vx + "," + vy + ") bullet=" + bullet + " ===");
        var sp = new Space(new Vec2(0, 1000));
        var grass = new Material(); grass.elasticity = 0; grass.dynamicFriction = 0.5; grass.staticFriction = 0.5; grass.density = 1; grass.rollingFriction = 0;
        var mud = new Material(); mud.elasticity = 0; mud.dynamicFriction = 100; mud.staticFriction = 100; mud.density = 1; mud.rollingFriction = 100;
        buildPoly(sp, GRASS, grass, "poly_average");
        buildPoly(sp, MUD, mud, "poly_mud");
        var football = new Material(); football.elasticity = 1; football.dynamicFriction = 0.1; football.staticFriction = 0.1; football.density = 0.5; football.rollingFriction = 0.1;
        var ball = new Body(BodyType.DYNAMIC, new Vec2(startx, starty));
        ball.shapes.add(new Circle(12, null, football));
        if (bullet) ball.isBullet = true;
        sp.bodies.add(ball);
        ball.velocity.setxy(vx, vy);
        var lastvx = vx; var reported = false;
        for (f in 0...40) {
            sp.step(1/60, 10, 10);
            probe(sp, ball, f);
            if (!reported && ball.velocity.x < 0 && lastvx >= 0) {
                Sys.println("  >> BOUNCED at f" + f + ": vel=(" + Math.round(ball.velocity.x) + "," + Math.round(ball.velocity.y) + ") spin=" + (Math.round(ball.angularVel*100)/100));
                reported = true;
            }
            lastvx = ball.velocity.x;
        }
        Sys.println("  final: vel=(" + Math.round(ball.velocity.x) + "," + Math.round(ball.velocity.y) + ") spin=" + (Math.round(ball.angularVel*100)/100) + " pos=(" + Math.round(ball.position.x) + "," + Math.round(ball.position.y) + ")");
    }

    static function main() {
        Sys.println("LEVEL 9 wall-bounce reconstruction (grass fric0.5 front @x~214, mud fric100 behind @x~229)");
        Sys.println("ORIGINAL wants: grass friction (combF~0.22), y preserved, spin~0  ->  (-151,-544)");
        Sys.println("PORT shows:     mud friction (combF~3.16), y halved, spin~18      ->  (-156,-283)");
        // Aim the football at the vertical wall segment (x~214, y~237..356). Try a few approaches.
        shoot("A discrete: low approach into vertical face", 150, 330, 302, -561, false);
        shoot("B discrete: closer/higher",                   180, 300, 302, -561, false);
        // Penetration tests: can the ball ever reach the enclosed MUD (combF 3.16)?
        shoot("E FAST ball (vx 900) — tunneling test",       150, 330, 900, -561, false);
        shoot("F FAST+bullet (CCD should prevent tunnel)",   150, 330, 900, -561, true);
        // Ball STARTING in the grass/mud interface (x=222, between grass face 214 and mud 229):
        // mimics 'ball ends up inside the grass skin' — does mud then dominate?
        shoot("G start INSIDE grass skin @x222",             222, 290, 50, -400, false);
        shoot("H start deeper @x232 (past mud face 229)",    232, 290, 50, -400, false);
    }
}
