package editorPackage;


/**
	 * ...
	 * @author ...
	 */
class PolyMaterials
{
    private static var list : Array<PolyMaterial>;
    
    public function new()
    {
    }
    public static function GetByName(name : String)
    {
        for (pm in list)
        {
            if (pm.name == name)
            {
                return pm;
            }
        }
        return null;
    }
    
    
    
    public static function GetNameByIndex(index : Int) : String
    {
        return list[index].name;
    }
    public static function GetMaterialNameList() : String
    {
        var s : String = "";
        var max : Int = list.length;
        for (i in 0...max)
        {
            var pm : PolyMaterial = list[i];
            s += pm.name;
            if (i != max - 1)
            {
                s += ",";
            }
        }
        return s;
    }
    public static function InitOnce(x : FastXML)
    {
        list = new Array<PolyMaterial>();
        
        for (i in 0...x.nodes.polymat.length())
        {
            var mx : FastXML = x.nodes.polymat.get(i);
            var matobj : PolyMaterial = new PolyMaterial();
            
            matobj.name = XmlHelper.GetAttrString(mx.att.name, "");
            matobj.materialName = XmlHelper.GetAttrString(mx.att.material, "average");
            matobj.initFunctionName = XmlHelper.GetAttrString(mx.att.initfunction, "");
            matobj.graphicName = XmlHelper.GetAttrString(mx.att.clip, "");
            matobj.initType = XmlHelper.GetAttrString(mx.att.inittype, "poly");
            matobj.edType = XmlHelper.GetAttrString(mx.att.edtype, "poly");
            matobj.fillFrame = as3hx.Compat.parseInt(XmlHelper.GetAttrInt(mx.att.frame, 1)) - 1;
            matobj.fixed = XmlHelper.GetAttrBoolean(mx.att.fixed, true);
            matobj.defaultGameLayer = XmlHelper.GetAttrString(mx.att.gamelayer, "Centre");
            
            var s : String = XmlHelper.GetAttrString(mx.att.col, "0,0");
            var a : Array<Dynamic> = s.split(",");
            
            var s1 : String = XmlHelper.GetAttrString(mx.att.sensor, "0,0");
            var a1 : Array<Dynamic> = s1.split(",");
            
            matobj.collisionCategory = as3hx.Compat.parseInt(a[0]);
            matobj.collisionMask = as3hx.Compat.parseInt(a[1]);
            
            matobj.sensorCategory = as3hx.Compat.parseInt(a1[0]);
            matobj.sensorMask = as3hx.Compat.parseInt(a1[1]);
            
            list.push(matobj);
        }
    }
}

