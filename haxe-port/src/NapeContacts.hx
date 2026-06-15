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
        var bud0 : PhysObjBodyUserData;
        var bud1 : PhysObjBodyUserData;
        if (Std.is(cb.int1.userData.data, PhysObjBodyUserData))
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
    public static function BeginCollide(cb : InteractionCallback)
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


