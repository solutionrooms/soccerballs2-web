
/**
	 * ...
	 * @author LongAnimals
	 */
class ObjectParameters
{
    public static var objparamList : Array<Dynamic>;
    
    public function new()
    {
    }
    
    
    public static function InitOnce()
    {
        LoadObjectParams();
    }
    
    public static function GetObjParamString(paramList : Array<Dynamic>, defaultsList : Array<Dynamic>) : String
    {
        var i : Int = 0;        var num : Int = paramList.length;
        var s : String = "";
        for (i in 0...num)
        {
            var pstr : String = paramList[i];
            var def : String = defaultsList[i];
            Utils.print("param " + pstr + " " + def);
            var op : ObjParam = GetObjectParamByName(pstr);
            s += op.name;
            s += "=";
            if (def != "")
            {
                s += def;
            }
            else
            {
                s += op.defaultValue;
            }
            if (i != num - 1)
            {
                s += ",";
            }
        }
        return s;
    }
    public static function GetObjectParamByName(name : String) : ObjParam
    {
        for (o in objparamList)
        {
            if (o.name == name)
            {
                return o;
            }
        }
        return null;
    }
    
    public static function GetDefault(name : String) : String
    {
        for (o in objparamList)
        {
            if (o.name == name)
            {
                return o.defaultValue;
            }
        }
        return null;
    }
    
    public static function AddParamBool(_name : String, _defaultValue : Bool) : Void
    {
        var _def : String = "false";
        if (_defaultValue == true)
        {
            _def = "true";
        }
        AddParam(_name, "bool", _def, "");
    }
    
    public static function AddParamAngle(_name : String, _defaultValue : Float) : Void
    {
        var op : ObjParam = AddParam(_name, "angle", Std.string(_defaultValue), "");
    }
    public static function AddParamNumber(_name : String, _defaultValue : Float, _useRangeMin : Bool, _useRangeMax : Bool, _min : Float, _max : Float, _step : Float) : Void
    {
        var op : ObjParam = AddParam(_name, "number", Std.string(_defaultValue), "");
        op.number_useRangeMin = _useRangeMin;
        op.number_useRangeMax = _useRangeMax;
        op.number_min = _min;
        op.number_max = _max;
        op.number_step = _step;
    }
    public static function AddParam(_name : String, _type : String, _defaultValue : String, _values : String) : ObjParam
    {
        var op : ObjParam = GetObjectParamByName(_name);
        if (op != null)
        {
            return op;
        }
        
        op = new ObjParam();
        op.name = _name;
        op.type = _type;
        op.defaultValue = _defaultValue;
        op.AddValuesString(_values);
        objparamList.push(op);
        return op;
    }
    
    public static function LoadObjectParams()
    {
        objparamList = [];
        var x : FastXML = ExternalData.xml;
        var num = x.nodes.objparam.length();
        for (i in 0...num)
        {
            var xx : FastXML = x.nodes.objparam.get(i);
            var op : ObjParam = new ObjParam();
            op.name = XmlHelper.GetAttrString(xx.att.name, "");
            op.type = XmlHelper.GetAttrString(xx.att.type, "");
            op.defaultValue = XmlHelper.GetAttrString(xx.att.resolve("default"), "");
            op.AddValuesString(XmlHelper.GetAttrString(xx.att.values, ""));
            objparamList.push(op);
        }
    }
}


