import flash.geom.Point;
import nape.callbacks.InteractionCallback;
import nape.dynamics.Arbiter;
import nape.dynamics.ArbiterList;
import nape.dynamics.CollisionArbiter;
import nape.dynamics.Contact;

/**
	 * ...
	 * @author
	 */
class NapeContacts
{
    
    public function new()
    {
    }
    
    public static function BeginCollideA(cb : InteractionCallback)
    {
        var contact : Contact = null;
        var arbiterList : ArbiterList = cb.arbiters;
        for (i in 0...arbiterList.length)
        {
            var arbiter : Arbiter = arbiterList.at(i);
            if (arbiter.isCollisionArbiter())
            {
                var ca : CollisionArbiter = arbiter.collisionArbiter;
                contact = ca.contacts.at(0);
            }
            if (arbiter.isSensorArbiter())
            {
                var a : Int = 0;
            }
        }
        
        
        
        
        
        
        var go0 : GameObj = null;
        var go1 : GameObj = null;
        var bud0 : PhysObjBodyUserData = null;        var bud1 : PhysObjBodyUserData = null;        if (Std.is(cb.int1.userData.data, PhysObjBodyUserData))
        {
            bud0 = try cast(cb.int1.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
            if (bud0 == null)
            {
                return;
            }
            if (bud0.gameObjectIndex != -1)
            {
                go0 = GameObjects.objs[bud0.gameObjectIndex];
            }
            else
            {
                go0 = bud0.independantGO;
            }
        }
        else if (Std.is(cb.int1.userData.data, PhysObjMaterial))
        {
        }
        
        if (Std.is(cb.int2.userData.data, PhysObjBodyUserData))
        {
            bud1 = try cast(cb.int2.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
            if (bud1 == null)
            {
                return;
            }
            if (bud1.gameObjectIndex != -1)
            {
                go1 = GameObjects.objs[bud1.gameObjectIndex];
            }
            else
            {
                go1 = bud1.independantGO;
            }
        }
        else if (Std.is(cb.int2.userData.data, PhysObjMaterial))
        {
        }
        
        if (go0 != null)
        {
            var name : String = go0.name;
            go0.hitShapeName = "";
            go0.hitContactPoint_Nape = contact;
            go0.hitUserData_Nape = cb.int2.userData.data;
        }
        if (go1 != null)
        {
            var name : String = go1.name;
            go1.hitShapeName = "";
            go1.hitContactPoint_Nape = contact;
            go1.hitUserData_Nape = cb.int1.userData.data;
        }
        
        
        if (go0 != null && go0.hitUserData_Nape != null)
        {
            if (go0.onHitFunction != null)
            {
                go0.onHitFunction(null);
            }
        }
        if (go1 != null && go1.hitUserData_Nape != null)
        {
            if (go1.onHitFunction != null)
            {
                go1.onHitFunction(null);
            }
        }
    }
    
    
    public static function OngoingSensor(cb : InteractionCallback)
    {
        BeginCollide(cb);
    }
    public static function BeginSensor(cb : InteractionCallback)
    {
        BeginCollide(cb);
    }
    public static function BeginPre(cb : InteractionCallback)
    {
        Utils.print("HERE");
    }
    // ===== TEMP CONTACT PROBE (level-9 friction diagnosis; REMOVE after measuring) =====
    // For every ball-involved collision arbiter, logs which surface was hit and the combined
    // restitution/friction the engine actually applied, plus the ball's speed. A wall hit that
    // produces a mud arbiter logs combined dynF ~3.16; a grass arbiter ~0.22. If a single impact
    // logs BOTH a mud and a grass line, that confirms the overlapping-collider hypothesis.
    public static var probeEnabled : Bool = false; // OFF for deploy. Was ON for the trajectory A/B vs the original SWF; fix now lives in the nape-haxe4 friction patch (tools/patch-nape-friction.sh).
    static var probeOngoingTick : Int = 0;

    static function ProbeLog(arbiterList : ArbiterList, tag : String) : Void
    {
        if (!probeEnabled) return;
        for (i in 0...arbiterList.length)
        {
            var arbiter : Arbiter = arbiterList.at(i);
            if (!arbiter.isCollisionArbiter()) continue;
            var ca : CollisionArbiter = arbiter.collisionArbiter;
            var s1 = arbiter.shape1;
            var s2 = arbiter.shape2;
            // a ball has material elasticity ~1 (football/beachball); the other shape is the surface
            var ballShape = (s1.material.elasticity >= 0.99) ? s1 : ((s2.material.elasticity >= 0.99) ? s2 : null);
            if (ballShape == null || ballShape.body == null) continue;
            var surfShape = (ballShape == s1) ? s2 : s1;
            var v = ballShape.body.velocity;
            var spd = Math.sqrt(v.x * v.x + v.y * v.y);
            if (spd < 40) continue; // skip resting/jitter contacts
            var n = ca.normal;
            var surfName : String = "?";
            try { surfName = surfShape.userData.data.name; } catch (e : Dynamic) { surfName = "?"; }
            var r2 = function(f : Float) : Float { return Math.round(f * 100) / 100; };
            trace("[PROBE " + tag + "] surf=" + surfName + " combF=" + r2(ca.dynamicFriction)
                + " | vel=(" + Math.round(v.x) + "," + Math.round(v.y) + ") spd=" + Math.round(spd)
                + " | normal=(" + r2(n.x) + "," + r2(n.y) + ")"
                + " | spin=" + r2(ballShape.body.angularVel));
        }
    }

    public static function BeginCollide(cb : InteractionCallback)
    {
        var contact : Contact = null;

        var arbiterList : ArbiterList = cb.arbiters;
        ProbeLog(arbiterList, "BEGIN");
        for (i in 0...arbiterList.length)
        {
            var arbiter : Arbiter = arbiterList.at(i);
            if (arbiter.isCollisionArbiter())
            {
                var ca : CollisionArbiter = arbiter.collisionArbiter;
                contact = ca.contacts.at(0);
            }
        }
        
        
        var bud0 : PhysObjBodyUserData = try cast(cb.int1.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
        var bud1 : PhysObjBodyUserData = try cast(cb.int2.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
        
        if (bud0 == null)
        {
            return;
        }
        if (bud1 == null)
        {
            return;
        }
        
        var go0 : GameObj = null;
        var go1 : GameObj = null;
        if (bud0.gameObjectIndex != -1)
        {
            go0 = GameObjects.objs[bud0.gameObjectIndex];
        }
        if (bud1.gameObjectIndex != -1)
        {
            go1 = GameObjects.objs[bud1.gameObjectIndex];
        }
        
        if (go0 != null)
        {
            go0.hitShapeName = "";
            go0.hitContactPoint_Nape = contact;
            go0.hitInteractionCallback_Nape = cb;
        }
        if (go1 != null)
        {
            go1.hitShapeName = "";
            go1.hitContactPoint_Nape = contact;
            go1.hitInteractionCallback_Nape = cb;
        }
        
        if (go0 != null && go1 == null)
        {
            if (go0.onHitSceneryFunction != null)
            {
                go0.onHitSceneryFunction(null);
            }
        }
        if (go1 != null && go0 == null)
        {
            if (go1.onHitSceneryFunction != null)
            {
                go1.onHitSceneryFunction(null);
            }
        }
        if (go0 != null && go1 != null)
        {
            if (go0.onHitFunction != null)
            {
                go0.onHitFunction(go1);
            }
            if (go1.onHitFunction != null)
            {
                go1.onHitFunction(go0);
            }
        }
    }
    
    public static function OngoingCollide(cb : InteractionCallback)
    {
        var contact : Contact = null;

        var arbiterList : ArbiterList = cb.arbiters;
        if ((probeOngoingTick++ % 4) == 0) ProbeLog(arbiterList, "ONGOING");
        for (i in 0...arbiterList.length)
        {
            var arbiter : Arbiter = arbiterList.at(i);
            if (arbiter.isCollisionArbiter())
            {
                var ca : CollisionArbiter = arbiter.collisionArbiter;
                contact = ca.contacts.at(0);
            }
        }
        
        
        var bud0 : PhysObjBodyUserData = try cast(cb.int1.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
        var bud1 : PhysObjBodyUserData = try cast(cb.int2.userData.data, PhysObjBodyUserData) catch(e:Dynamic) null;
        
        if (bud0 == null)
        {
            return;
        }
        if (bud1 == null)
        {
            return;
        }
        
        var go0 : GameObj = null;
        var go1 : GameObj = null;
        if (bud0.gameObjectIndex != -1)
        {
            go0 = GameObjects.objs[bud0.gameObjectIndex];
        }
        if (bud1.gameObjectIndex != -1)
        {
            go1 = GameObjects.objs[bud1.gameObjectIndex];
        }
        
        if (go0 != null)
        {
            go0.hitShapeName = "";
            go0.hitContactPoint_Nape = contact;
        }
        if (go1 != null)
        {
            go1.hitShapeName = "";
            go1.hitContactPoint_Nape = contact;
        }
        
        if (go0 != null && go1 != null)
        {
            if (go0.onHitPersistFunction != null)
            {
                go0.onHitPersistFunction(go1);
            }
            if (go1.onHitPersistFunction != null)
            {
                go1.onHitPersistFunction(go0);
            }
        }
    }
}


