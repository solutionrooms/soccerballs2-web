import nape.phys.Material;

/**
	 * ...
	 * @author LongAnimals
	 */
class PhysObjMaterial
{
    private var name : String;
    private var density : Float;
    private var friction_dynamic : Float;
    private var friction_static : Float;
    private var friction_rolling : Float;
    private var elasticity : Float;
    
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
        return m;
    }
}


