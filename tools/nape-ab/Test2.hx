// Reproduce the real level-9 wall bounce (from the trajectory A/B) and test which ball property makes
// nape-haxe4 match the ORIGINAL: tangential (y) velocity preserved + spin stays 0. The original bounce:
//   before vel=(302,-561) spin=0  ->  after vel=(-151,-544) spin=0   (y kept, NO spin, NO friction)
// Ours (default) instead halves y and spins the ball (friction 3.16 applied). Variations tested:
//   default | allowRotation=false | ball-friction=0 | isBullet
//   haxe -cp tools/nape-ab -lib nape-haxe4 -main Test2 -neko /tmp/t2.n && neko /tmp/t2.n
import nape.geom.Vec2;
import nape.phys.Body;
import nape.phys.BodyType;
import nape.phys.Material;
import nape.shape.Circle;
import nape.shape.Polygon;
import nape.space.Space;

class Test2 {
    static function mat(el:Float, dyn:Float, stat:Float, dens:Float, roll:Float):Material {
        var m = new Material(); m.elasticity = el; m.dynamicFriction = dyn; m.staticFriction = stat;
        m.density = dens; m.rollingFriction = roll; return m;
    }
    static function run(label:String, noRotation:Bool, ballFric:Float, bullet:Bool) {
        var sp = new Space(new Vec2(0, 1000));
        // mud wall (vertical), elasticity 0, friction 100; ball approaches from the LEFT moving +x.
        var wall = new Body(BodyType.STATIC);
        wall.shapes.add(new Polygon(Polygon.box(40, 400), mat(0.0, 100, 100, 1.0, 100)));
        wall.position.setxy(230, 0);
        sp.bodies.add(wall);
        var ball = new Body(BodyType.DYNAMIC);
        ball.shapes.add(new Circle(12, null, mat(1.0, ballFric, ballFric, 0.5, ballFric)));
        ball.position.setxy(185, 0);
        sp.bodies.add(ball);
        ball.velocity.setxy(302, -561);   // real pre-bounce velocity (moving up-right into the wall)
        if (noRotation) ball.allowRotation = false;
        if (bullet) ball.isBullet = true;
        var bounced = false; var preY = ball.velocity.y;
        for (i in 0...20) {
            var vxBefore = ball.velocity.x;
            sp.step(1/60, 10, 10);
            if (!bounced && ball.velocity.x < 0) { // x reversed = bounced
                bounced = true;
                Sys.println(StringTools.rpad(label, " ", 26)
                    + " -> after bounce: vel=(" + Math.round(ball.velocity.x) + "," + Math.round(ball.velocity.y)
                    + ") spin=" + (Math.round(ball.angularVel * 100) / 100)
                    + "   [orig wants vy~-556, spin 0]");
                return;
            }
        }
        Sys.println(StringTools.rpad(label, " ", 26) + " -> (no bounce detected)");
    }
    // Slow PERSISTENT contact: ball rolling on a floor. With friction the ball should spin up toward
    // rolling (omega -> v/r). This must STILL get friction under the patch (the contact isn't fresh
    // after frame 1) — proving ground roll is preserved.
    static function runRoll(label:String) {
        var sp = new Space(new Vec2(0, 1000));
        var floor = new Body(BodyType.STATIC);
        floor.shapes.add(new Polygon(Polygon.box(600, 40), mat(0.0, 0.5, 0.5, 1.0, 0.5)));
        floor.position.setxy(0, 30);
        sp.bodies.add(floor);
        var ball = new Body(BodyType.DYNAMIC);
        ball.shapes.add(new Circle(12, null, mat(1.0, 0.1, 0.1, 0.5, 0.1)));
        ball.position.setxy(0, -2);
        sp.bodies.add(ball);
        ball.velocity.setxy(200, 0);
        for (i in 0...40) sp.step(1 / 60, 10, 10);
        Sys.println(StringTools.rpad(label, " ", 26) + " -> after 40f roll: vx=" + Math.round(ball.velocity.x)
            + " spin=" + (Math.round(ball.angularVel * 100) / 100) + "   [friction OK if spin != 0]");
    }
    static function main() {
        Sys.println("scenario                    result");
        run("default (fric 0.1)",      false, 0.1, false);
        run("allowRotation=false",     true,  0.1, false);
        run("ball friction = 0",       false, 0.0, false);
        run("isBullet=true",           false, 0.1, true);
        run("noRotation + fric0",      true,  0.0, false);
        runRoll("ROLL slow on floor");
    }
}
