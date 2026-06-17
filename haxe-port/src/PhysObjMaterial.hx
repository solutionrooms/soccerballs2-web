import nape.phys.Material;

/**
	 * ...
	 * @author LongAnimals
	 */
class PhysObjMaterial
{
    public var name : String;
    public var density : Float;
    public var friction_dynamic : Float;
    public var friction_static : Float;
    public var friction_rolling : Float;
    public var elasticity : Float;
    
    public function new()
    {
        name = "";
        density = 1;
        friction_dynamic = 1;
        friction_static = 1;
        friction_rolling = 1;
        elasticity = 0;
    }
    
    public function Clone() : PhysObjMaterial
    {
        var copy : PhysObjMaterial = new PhysObjMaterial();
        copy.name = name;
        copy.density = density;
        copy.friction_dynamic = friction_dynamic;
        copy.friction_static = friction_static;
        copy.friction_rolling = friction_rolling;
        copy.elasticity = elasticity;
        return copy;
    }
    
    public function FromXML(x : FastXML)
    {
        name = XmlHelper.GetAttrString(x.att.name, "");
        density = XmlHelper.GetAttrNumber(x.att.density, 1);
        friction_static = XmlHelper.GetAttrNumber(x.att.friction_static, 1);
        friction_dynamic = XmlHelper.GetAttrNumber(x.att.friction_dynamic, friction_static);
        friction_rolling = XmlHelper.GetAttrNumber(x.att.friction_rolling, friction_dynamic);
        elasticity = XmlHelper.GetAttrNumber(x.att.elasticity, 1);
        Utils.print(" Phys Material " + name + "  d:" + density + "  f:" + friction_static + "  el:" + elasticity);
    }
    
    public function MakeNapeMaterial() : Material
    {
        var m : Material = new Material();
        m.density = density;
        m.dynamicFriction = friction_dynamic;
        m.rollingFriction = friction_rolling;
        m.staticFriction = friction_static;
        m.elasticity = elasticity;
        // FAITHFUL FIX (verified by the original-SWF trajectory A/B + headless harness): the original
        // game's 2012 Nape applied NO friction to the ball at fast terrain contacts — the football flew
        // frictionlessly (tangential velocity preserved, physics spin 0; the visual roll is render-driven).
        // nape-haxe4 2.0.22 DOES apply the ball's 0.1 friction at those contacts, halving the climb and
        // spinning the ball (e.g. level 9 falling short of the receiving player). The game's feel was tuned
        // to the 2012 engine, so we re-tune the ball materials to frictionless to reproduce it exactly.
        if (Settings.ballFrictionless && (name == "football" || name == "beachball"))
        {
            m.dynamicFriction = 0;
            m.staticFriction = 0;
            m.rollingFriction = 0;
        }
        return m;
    }
}


