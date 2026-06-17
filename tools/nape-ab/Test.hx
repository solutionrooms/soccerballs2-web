// Headless A/B harness: replays the level-9 mud-wall contact (from the in-game probe) so we can
// compare nape 2.0.20 (original Deltodesco, ~= the 2012 SWC the game shipped) against
// nape-haxe4 2.0.22 (what the port links). Same source compiles against both (identical `nape.*` API);
// only the -lib changes. If the ball keeps its upward velocity in one engine and loses it in the
// other, that's the friction-solver divergence behind "ball sticks to the mud wall".
//
//   haxe -cp tools/nape-ab -lib nape         -main Test -neko /tmp/t20.n && neko /tmp/t20.n
//   haxe -cp tools/nape-ab -lib nape-haxe4   -main Test -neko /tmp/t22.n && neko /tmp/t22.n

import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;

class Test {
    static function mat(el:Float, dyn:Float, stat:Float, dens:Float, roll:Float):Material {
        var m = new Material();
        m.elasticity = el;
        m.dynamicFriction = dyn;
        m.staticFriction = stat;
        m.density = dens;
        m.rollingFriction = roll;
        return m;
    }

    static function main() {
        // Game uses gravity 1000 px/s^2 (+y down) and step(1/60, 10, 10).
        var space = new Space(new Vec2(0, 1000));

        // poly_mud material: elasticity 0, friction 100 (dyn/stat/roll), density 1.
        var mud = mat(0.0, 100, 100, 1.0, 100);
        // football material: elasticity 1, friction 0.1 (dyn/stat/roll), density 0.5.
        var ballMat = mat(1.0, 0.1, 0.1, 0.5, 0.1);

        // Vertical static wall: box 20 wide x 400 tall, centred at x=0 -> right face at x=10.
        var wall = new Body(BodyType.STATIC);
        wall.shapes.add(new Polygon(Polygon.box(20, 400), mud));
        wall.position.setxy(0, 0);
        space.bodies.add(wall);

        // Sweep spin to test the roll-vs-slide hypothesis. The probe measured our in-game spin = +17.89.
        // Rolling-without-slipping up this wall needs omega ~= v_y/r = -280/15 = -18.7 (opposite sign).
        // Report PEAK height reached (most-negative y = highest) for each spin.
        Sys.println("spin    -> peakUp(px)  vyAfter1step   [more peakUp = ball flew higher]");
        for (spin in [17.89, 0.0, -18.7, -30.0, 35.0]) {
            var sp = new Space(new Vec2(0, 1000));
            var w = new Body(BodyType.STATIC);
            w.shapes.add(new Polygon(Polygon.box(20, 400), mud));
            w.position.setxy(0, 0);
            sp.bodies.add(w);
            var ball = new Body(BodyType.DYNAMIC);
            ball.shapes.add(new Circle(15, null, ballMat));
            ball.position.setxy(25, 0);
            sp.bodies.add(ball);
            ball.velocity.setxy(-148, -280);
            ball.angularVel = spin;
            var peakUp = 0.0;
            var vyAfter1 = 0.0;
            for (i in 0...90) {
                sp.step(1 / 60, 10, 10);
                if (i == 0) vyAfter1 = ball.velocity.y;
                var up = -ball.position.y; // -y is up
                if (up > peakUp) peakUp = up;
            }
            Sys.println(StringTools.rpad(Std.string(spin), " ", 7)
                + " -> " + StringTools.lpad(Std.string(Math.round(peakUp)), " ", 6)
                + "       vy1=" + Math.round(vyAfter1));
        }
    }
}
