// LEVEL 10 "remote control" big-ball ROLL test. The big ball is `ball_large`: circle radius 35,
// material football (el 1, fric 0.1, density 0.5), rolling on poly_collide_grass -> poly_average
// (fric 0.5, EL 0). Combined friction sqrt(0.1*0.5)=0.224, combined elasticity (1+0)/2=0.5.
// Symptom: on the PORT the big ball SLIDES (no spin) where the ORIGINAL ROLLS (spins).
// Hypothesis: the bounce-gate patch (if c1.bounce!=0 -> jMax=0) zeroes tangent friction on the
// micro-impacts as the radius-35 ball rolls over the faceted grass polyline -> no roll torque.
// This test logs, per frame, linear speed vs angular speed and the ROLL RATIO |angVel*R|/|linVel|
// (~1.0 = pure rolling, ~0.0 = pure sliding). Run it with the engine PATCHED, then UNPATCHED, diff.
//   haxe -cp tools/nape-ab -lib nape-haxe4 -main Test4 -neko /tmp/t4.n && neko /tmp/t4.n
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

class Test4 {
    static inline var R = 35.0;            // ball_large radius
    static inline var GRAV = 1000.0;       // VarsData gravity
    // Level-10 grass polyline (== level 9; SoccerBalls2_Levels_Data.xml). poly_collide_grass.
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

    static function buildPoly(sp:Space, flat:Array<Float>, mat:Material, name:String) {
        var pts:Array<Vec2> = [];
        var cx = 0.0; var cy = 0.0; var i = 0;
        while (i < flat.length) { pts.push(new Vec2(flat[i], flat[i+1])); cx += flat[i]; cy += flat[i+1]; i += 2; }
        var n = pts.length; cx /= n; cy /= n;
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
    }

    static function surfName(s:Dynamic):String { try { return s.userData.data.name; } catch (e:Dynamic) { return "?"; } }

    static function roll(label:String, startx:Float, starty:Float, vx:Float, frames:Int) {
        Sys.println("\n=== " + label + " start=(" + startx + "," + starty + ") vx0=" + vx + " ===");
        var sp = new Space(new Vec2(0, GRAV));
        var grass = new Material(); grass.elasticity = 0; grass.dynamicFriction = 0.5; grass.staticFriction = 0.5; grass.density = 1; grass.rollingFriction = 0;
        buildPoly(sp, GRASS, grass, "grass");
        var football = new Material(); football.elasticity = 1; football.dynamicFriction = 0.1; football.staticFriction = 0.1; football.density = 0.5; football.rollingFriction = 0.1;
        var ball = new Body(BodyType.DYNAMIC, new Vec2(startx, starty));
        ball.shapes.add(new Circle(R, null, football));
        sp.bodies.add(ball);
        ball.velocity.setxy(vx, 0);
        for (f in 0...frames) {
            sp.step(1/60, 10, 10);
            if (f % 8 == 7 || f == frames-1) {
                var lv = Math.sqrt(ball.velocity.x*ball.velocity.x + ball.velocity.y*ball.velocity.y);
                var ratio = (lv > 1) ? (ball.angularVel * R) / lv : 0.0;
                var nc = 0; var sn = "-"; var cf = 0.0;
                var arbs = ball.arbiters;
                for (j in 0...arbs.length) {
                    var ar:Arbiter = arbs.at(j);
                    if (!ar.isCollisionArbiter()) continue;
                    nc++;
                    var ca:CollisionArbiter = ar.collisionArbiter;
                    var other = (ar.shape1.body == ball) ? ar.shape2 : ar.shape1;
                    sn = surfName(other); cf = ca.dynamicFriction;
                }
                Sys.println("  f" + f
                    + " pos=(" + Math.round(ball.position.x) + "," + Math.round(ball.position.y) + ")"
                    + " linV=(" + Math.round(ball.velocity.x) + "," + Math.round(ball.velocity.y) + ") |v|=" + Math.round(lv)
                    + " spin=" + (Math.round(ball.angularVel*1000)/1000)
                    + " ROLLRATIO=" + (Math.round(ratio*100)/100)
                    + "  [contacts=" + nc + " surf=" + sn + " combF=" + (Math.round(cf*100)/100) + "]");
            }
        }
    }

    static function main() {
        Sys.println("LEVEL 10 big-ball roll test. ROLLRATIO ~1.0 => ROLLING, ~0.0 => SLIDING.");
        var patched = "UNKNOWN";
        Sys.println("(engine state: check Arbiter.hx for 'SB2 patch' to know if bounce-gate is active)");
        // A: real start, nudge it rolling down the gentle left slope of the ridge.
        roll("A real start, nudge right (downhill toward peak)", 664, 140, 60, 140);
        roll("B real start, nudge left (downhill off ridge)",    664, 140, -60, 140);
        // C: drop on the STEEP right down-slope from the peak (x833 y73 -> x945 y150) — unambiguous roll.
        roll("C steep right down-slope @x880",                   880, 60, 20, 160);
        // D: drop on the STEEP left down-slope from peak (x833 y73 -> x702 y171).
        roll("D steep left down-slope @x760",                    760, 40, -20, 160);
    }
}
